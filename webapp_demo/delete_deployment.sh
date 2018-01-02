#!/bin/bash

. ../utils.sh

../etc/set_context.sh $APP_CONTEXT

oc delete --ignore-not-found=true -f webapp.yaml
oc delete --ignore-not-found=true configmap webapp
