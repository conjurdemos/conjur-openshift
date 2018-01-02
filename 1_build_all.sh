#!/bin/bash 
set -eo pipefail

. utils.sh

main() {
  build_appliance_image
	build_haproxy_image

	install_weavescope
}

build_appliance_image() {
  # Assumptions:
  # - conjur-appliance:4.9-stable exists in the Docker engine.

	pushd ${EXERCISE_ROOT}/build/conjur_server
	  ./build.sh
	popd
}

build_haproxy_image() {
	pushd ${EXERCISE_ROOT}/build/haproxy
	  ./build.sh
	popd
}

install_weavescope() {
  # setup weave scope for visualization
  weave_image=$(docker images | awk '/weave/ {print $1}')
  if [[ "$weave_image" == "" ]]; then
    sudo curl -L git.io/scope -o /usr/local/bin/scope
    sudo chmod a+x /usr/local/bin/scope
  fi
}

main $@
