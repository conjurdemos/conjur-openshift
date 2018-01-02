#!/bin/bash 
set -eo pipefail

. utils.sh

declare MASTER_POD_NAME=""

main() {
	create_conjur_cluster
	configure_conjur_cluster
	start_sync_replication

	create_load_balancer

	print_config
	
	scope launch
}

create_conjur_cluster() {
	set_context $CONJUR_CONTEXT

  # initiate conjur cluster from manifest
  oc create -f "$MANIFEST_DIR/conjur-cluster.yaml"

	sleep 5

  # get list of the master/standby candidates
  pod_list=$(oc get pods -l app=conjur-node --no-headers | awk '{ print $1 }')
  # select first pod in list to be master
	MASTER_POD_NAME=$(echo $pod_list | awk '{print $1}' )

  # give containers time to get running
	echo "Waiting for pods to launch"
	wait_for_node $MASTER_POD_NAME
}

configure_conjur_cluster() {
  announce "Configuring cluster based on role labels..."
  
	set_context $CONJUR_CONTEXT

  # set master
  oc label --overwrite pod $MASTER_POD_NAME role=master

  announce "$(printf "Configuring conjur-master %s...\n" $MASTER_POD_NAME)"

	# configure Conjur master server using evoke
	oc exec $MASTER_POD_NAME -- evoke configure master \
		-j /etc/conjur.json \
		-h $CONJUR_MASTER_DNS_NAME \
		--master-altnames conjur-master \
		--follower-altnames conjur-follower \
		-p $CONJUR_ADMIN_PASSWORD \
		$CONJUR_CLUSTER_ACCOUNT

  # Prepare standby seed files
  announce "$(printf "Preparing standby seed files...\n")"

	oc exec $MASTER_POD_NAME evoke seed standby > $MANIFEST_DIR/standby-seed.tar

	# get master IP address for standby config
	MASTER_POD_IP=$(oc describe pod $MASTER_POD_NAME | awk '/IP:/ {print $2}')

	# get list of the other pods 
	pod_list=$(oc get pods -l role=unset --no-headers | awk '{ print $1 }')

	for pod_name in $pod_list; do
		announce "$(printf "Configuring standby %s...\n" $pod_name)"

    # label pod with role
    oc label --overwrite pod $pod_name role=standby

    # copy standby seed file to pod
	  copy_file_to_container "$MANIFEST_DIR/standby-seed.tar" "/tmp/standby-seed.tar" "$pod_name"

    # unpack seed file and configure standby
		oc exec $pod_name evoke unpack seed /tmp/standby-seed.tar
		oc exec $pod_name -- evoke configure standby -j /etc/conjur.json -i $MASTER_POD_IP
	done

}

create_load_balancer() {
	set_context $CONJUR_CONTEXT

	# create load balancer
	oc create -f $MANIFEST_DIR/haproxy-conjur-master.yaml

	sleep 5

	pushd $EXERCISE_ROOT/etc
	 ./update_haproxy.sh haproxy-conjur-master
  popd

}

start_sync_replication() {
	announce "Starting synchronous replication..."
  mastercmd evoke replication sync
}

print_config() {
	# get internal/external IP addresses
	EXTERNAL_PORT=$(oc describe svc conjur-master | awk '/NodePort:/ {print $2 " " $3}' | awk '/https/ {print $2}' | awk -F "/" '{ print $1 }')
  # inform user of service ingresses
	announce "
Conjur cluster is ready. Addresses for the Conjur Master service:


Inside the cluster:
  conjur-master.$CONJUR_CONTEXT.svc.cluster.local

Outside the cluster:
  DNS hostname: conjur-master, IP:127.0.0.1, Port:$EXTERNAL_PORT
"

}

main $@
