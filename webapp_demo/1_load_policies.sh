#!/bin/bash

. ../utils.sh

announce "Loading users policy"
load_policy users.yml

announce "Loading openshift_apps policy"
load_policy openshift_apps.yml

announce "Loading webapp policy"
load_policy webapp.yml

announce "Loading db policy"
load_policy db.yml

password=$(openssl rand -hex 12)
announce "Setting DB password: $password"
run_conjur_cmd_as_admin <<CMD
conjur variable values add db/password "$password"
CMD
