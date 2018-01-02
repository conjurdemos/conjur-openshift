#!/bin/bash 

declare SERVER_URL="https://10.2.2.2:8443"

# log in
oc login $SERVER_URL -u admin -p admin

declare EXERCISE_ROOT="/home/vagrant/scripts"

declare CONJUR_CONTEXT=conjur # project for Conjur
declare APP_CONTEXT=webapp # project for example app

declare CONJUR_CLUSTER_ACCOUNT=dev
declare CONJUR_MASTER_DNS_NAME=conjur-master.$CONJUR_CONTEXT.svc.cluster.local
declare CONJUR_ADMIN_PASSWORD=Cyberark1

# for the host conjur cli
declare CONJUR_CERT_PATH="$EXERCISE_ROOT/conjur-${CONJUR_CLUSTER_ACCOUNT}.pem"
declare CONJURRC="$EXERCISE_ROOT/conjurrc"
export CONJURRC

declare MANIFEST_DIR=conjur-service

announce() {
  echo "++++++++++++++++++++++++++++++++++++++"
  echo ""
  echo "$@"
  echo ""
  echo "++++++++++++++++++++++++++++++++++++++"
}

copy_file_to_container() {
  local from=$1
  local to=$2
  local pod_name=$3

  local source_file_path="$(readlink -f "$from")"
  local source_file_name="$(basename "$source_file_path")"
  local parent_path="$(dirname "$source_file_path")"
  local parent_name="$(basename "$parent_path")"

  local container_temp_path="/tmp"

  oc rsync "$parent_path" "$pod_name:$container_temp_path"
  oc exec "$pod_name" mv "$container_temp_path/$parent_name/$source_file_name" "$to"
  oc exec "$pod_name" rm -- -rf "$container_temp_path/$parent_name"
}

load_policy() {
  local POLICY_FILE=$1

  run_conjur_cmd_as_admin <<CMD
conjur policy load --as-group security_admin "policy/$POLICY_FILE"
CMD
}

mastercmd() {
  local current_context=$(oc projects | grep \* | awk '{ print $2 }')

  set_context $CONJUR_CONTEXT

  local master_pod=$(oc get pod -l role=master --no-headers | awk '{ print $1 }')
  local interactive=$1

  if [ $interactive = '-i' ]; then
    shift
    oc exec -i $master_pod -- $@
  else
    oc exec $master_pod -- $@
  fi

  set_context "$current_context"
}

rotate_host_api_key() {
  local host=$1

  run_conjur_cmd_as_admin <<CMD
conjur host rotate_api_key -h $host
CMD
}

run_conjur_cmd_as_admin() {
   if [[ "$CONJURRC" = "" ]] ; then
    echo "Set CONJURRC to point to your .conjurrc file."
    echo "This is created by 'conjur init' in your home directory by default."
    exit 1
  fi

  local command=$(cat $@)

  if [[ -z "$command" ]] ; then
    echo "Usage: %s <conjur-command>" $0
    exit 1
  fi
  conjur authn logout > /dev/null
  conjur authn login -u admin -p "$CONJUR_ADMIN_PASSWORD" > /dev/null

  local output=$(eval "$command")

  conjur authn logout > /dev/null
  echo "$output"
}

set_context() {
  # general utility for switching projects/namespaces/contexts in openshift
  # expects exactly 1 argument, a project name.
  if [[ $# != 1 ]]; then
    printf "Error in %s/%s - expecting 1 arg.\n" $(pwd) $0
    exit -1
  fi

  oc project $1 > /dev/null
}

wait_for_node() {
  local podname=$1
  wait_for_it 20 '[ $(oc exec "'"$1"'" evoke role) = "blank" ]'
}

function wait_for_it() {
  local timeout=$1
  local spacer=2
  shift

  if ! [ $timeout = '-1' ]; then
    local times_to_run=$((timeout / spacer))

    echo "Waiting for $@ up to $timeout s"
    for i in $(seq $times_to_run); do
      eval $@ && echo 'Success!' && break
      echo -n .
      sleep $spacer
    done

    eval $@
  else
    echo "Waiting for $@ forever"

    while ! eval $@; do
      echo -n .
      sleep $spacer
    done
    echo 'Success!'
  fi
}
