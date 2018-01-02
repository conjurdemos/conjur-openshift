#!/bin/bash 
set -eo pipefail

. ../utils.sh

declare ssl_certificate=""

main () {
  retrieve_conjur_cert
  store_conjur_cert
  store_webapp_api_key
  deploy_webapp
}

retrieve_conjur_cert() {
  announce "Grabbing the conjur.pem"

  set_context $CONJUR_CONTEXT

  ssl_certificate=$(mastercmd cat /opt/conjur/etc/ssl/conjur.pem)
# ssl_certificate=$(cat "conjur-${CONJUR_CLUSTER_ACCOUNT}.pem")
}

store_conjur_cert() {
  announce "Storing non-secret conjur cert as configuration data"

  set_context $APP_CONTEXT

  # write conjur ssl cert in configmap
  oc delete --ignore-not-found=true configmap webapp
  oc create configmap webapp \
    --from-file=ssl-certificate=<(echo "$ssl_certificate")
}

store_webapp_api_key() {
  announce "Storing webapp API key as secret"

  set_context $APP_CONTEXT

  # write webapp API key as secret
  oc delete --ignore-not-found=true secret conjur-webapp-api-key
  oc create secret generic conjur-webapp-api-key --from-literal "api-key=$(rotate_host_api_key 'conjur/openshift-12345/apps/webapp')"
}

deploy_webapp() {
  oc create -f webapp.yaml
}

main $@
