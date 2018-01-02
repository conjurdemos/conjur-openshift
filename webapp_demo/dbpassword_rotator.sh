#!/bin/bash 
set -o pipefail

. ../utils.sh

while [[ 1 == 1 ]]; do
	new_pwd=$(openssl rand -hex 12)
	error_msg=$(run_conjur_cmd_as_admin <<CMD
conjur variable values add db/password $new_pwd 2>&1 >/dev/null
CMD
)
	if [[ "$error_msg" = "" ]]; then
		echo $(date +%X) "New db password is:" $new_pwd
	else
		echo $error_msg
	fi
	sleep 5
done
