#!/bin/bash 
set -o pipefail

. utils.sh

echo "Purging Conjur environment..."
echo "This will completely destroy your currently running Conjur environment - proceed?"
select yn in "Yes" "No"; do
  case $yn in
      Yes ) break;;
      No ) exit -1;;
  esac
done

main() {
	delete_contexts
	announce "Conjur environment purged."
}

delete_contexts() {
	oc project default
	oc delete project $APP_CONTEXT
	oc delete project $CONJUR_CONTEXT
	announce "Waiting for $CONJUR_CONTEXT project deletion to complete"
	while : ; do
		printf "..."
		if [[ "$(oc projects | grep $CONJUR_CONTEXT)" != "" ]]; then
			sleep 5
		else
			break
		fi
	done
	echo ""
}

main $@
