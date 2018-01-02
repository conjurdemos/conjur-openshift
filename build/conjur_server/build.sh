# builds Conjur Appliance with /etc/conjur.json (contains memory allocation config for pg)
docker build -t conjur-appliance:local -f Dockerfile .
