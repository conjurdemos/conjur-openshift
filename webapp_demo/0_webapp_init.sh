#!/bin/bash
set -eo pipefail

. ../utils.sh

main() {
	initialize_host_conjur_cli
	build_app

	announce "
When using the Conjur CLI don't forget to run the following command in your terminal:

export CONJURRC=$CONJURRC
"
}

initialize_host_conjur_cli() {
	rm -f $CONJURRC $CONJUR_CERT_PATH

  # get external IP addresses
  local EXTERNAL_PORT=$(oc describe svc conjur-master | awk '/NodePort:/ {print $2 " " $3}' | awk '/https/ {print $2}' | awk -F "/" '{ print $1 }')

	conjur init -h "conjur-master:$EXTERNAL_PORT" -f "$CONJURRC" << END
yes
yes
yes
END
	conjur authn login -u admin -p $CONJUR_ADMIN_PASSWORD
	conjur bootstrap << END
no
END
  conjur authn logout
}

build_app() {
	pushd build
	  ./build.sh
	popd
}

main $@
