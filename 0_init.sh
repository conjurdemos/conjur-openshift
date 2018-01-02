#!/bin/bash 
set -eo pipefail

. utils.sh

main() {
  create_contexts
  announce_openshift_version
}

create_contexts() {
  announce "Creating separate contexts for conjur cluster and example application"

  oc project default

  if oc projects | grep -w $CONJUR_CONTEXT > /dev/null; then
    echo "Project '$CONJUR_CONTEXT' exists, switching to it."
    oc project $CONJUR_CONTEXT > /dev/null
  else
    oc new-project $CONJUR_CONTEXT --display-name="Conjur Openshift" --description="Demonstration of Conjur running in Openshift."
    sleep 2

    # Permissions

    oc adm policy add-scc-to-user anyuid -z default
    oc adm policy add-cluster-role-to-user cluster-reader system:serviceaccount:$CONJUR_CONTEXT:default
    oc policy add-role-to-user edit developer

  fi

  if oc projects | grep -w $APP_CONTEXT > /dev/null; then
    echo "Project '$APP_CONTEXT' exists, not going to create it."
  else
    oc new-project $APP_CONTEXT --display-name="Conjur Webapp Demo" --description="For demonstration of Conjur container authentication and secrets retrieval."

    # Permissions

    oc policy add-role-to-user edit developer

  fi
}

announce_openshift_version () {
  MAJOR_VERSION=$(oc version | grep openshift | awk '{print $2}' | awk -F "." '{ print $1}')
  MINOR_VERSION=$(oc version | grep openshift | awk -F "." '{ print $2}')
  printf "Running Openshift %s.%s\n" $MAJOR_VERSION $MINOR_VERSION
}

main $@
