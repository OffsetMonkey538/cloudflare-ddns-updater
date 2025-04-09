#!/bin/sh

###
###  This script will keep the IPv4 and IPv6 addresses of
###  CloudFlare DNS entries up to date with the current public
###  IP addresses of the computer it is run on.
###
###  It uses the CloudFlare api and the jq command for checking the IP address
###  currently set for the wanted domain and compares it with
###  the results from the ipify.org api (https://api4.ipify.org and https://api6.ipify.org)
###
###  If the IP addresses don't match, it will send an api request
###  to the CloudFlare api to change the two records for the new addresses.
###
###
###  To get the record ids for the domain records, you can uncomment the
###  following line and run the script, which will ask the CloudFlare api
###  for a list of all DNS records on the specified domain. It'll then
###  feed that into a jq command that beautifies it so you can
###  easily find the correct record id.
###  Note: API_TOKEN and ZONE_ID must already be defined!
###  LIST_RECORDS=true
###

UPDATE_DNS_COMMAND="curl -s -X PUT \"https://api.cloudflare.com/client/v4/zones/\$ZONE_ID/dns_records/\$RECORD_ID\" \
  -H \"Authorization: Bearer \$API_TOKEN\" \
  -H \"Content-Type: application/json\" \
  --data \"{
    \\\"type\\\": \\\"\$RECORD_TYPE\\\",
    \\\"name\\\": \\\"\$DOMAIN\\\",
    \\\"content\\\": \\\"\$ACTUAL_IP\\\",
    \\\"ttl\\\": \$TTL,
    \\\"proxied\\\": false,
    \\\"comment\\\": \\\"Automatically updated on \$(date '+%Y-%m-%d_%H-%M-%S') using [INSERT LINK]\\\"
  }\""
GET_RECORD_COMMAND="curl -s \"https://api.cloudflare.com/client/v4/zones/\$ZONE_ID/dns_records/\$RECORD_ID\" \
  -H \"Authorization: Bearer \$API_TOKEN\" \
  -H \"Content-Type:application/json\""
LIST_RECORDS_COMMAND="curl -s \"https://api.cloudflare.com/client/v4/zones/\$ZONE_ID/dns_records\" \
  -H \"Authorization: Bearer \$API_TOKEN\" \
  -H \"Content-Type:application/json\""

load_env() {
  while IFS= read -r line || [ -n "$line" ]; do
    # Remove all whitespace. Also removes around the equals so should just be able to eval it as a command
    eval "$(echo "${line}" | tr -d '[:space:]')"
  done < .env
}

# Load .env file
load_env

# If enabled, list records and exit
if [ "$LIST_RECORDS" = true ]; then
  eval "$LIST_RECORDS_COMMAND" | jq .
  exit
fi

# Get current addresses for the domain
CURRENT_IPV4=$(RECORD_ID=$RECORD_ID_4 eval "$GET_RECORD_COMMAND | jq '.result.content' | tail -c +2 | head -c -2") # Json has quotes around the value so remove
CURRENT_IPV6=$(RECORD_ID=$RECORD_ID_6 eval "$GET_RECORD_COMMAND | jq '.result.content' | tail -c +2 | head -c -2") # Json has quotes around the value so remove

# Get actual addresses of the computer
ACTUAL_IPV4=$(curl -s https://api4.ipify.org)
ACTUAL_IPV6=$(curl -s https://api6.ipify.org)


if [ "$CURRENT_IPV4" != "$ACTUAL_IPV4" ]; then
  echo "IPv4 Address changed from $CURRENT_IPV4 to $ACTUAL_IPV4! Updating..."
  ## All spellchecks below: variables are used when evaluating the update command defined at the top.
  # shellcheck disable=SC2034
  RECORD_TYPE="A"
  # shellcheck disable=SC2034
  ACTUAL_IP=$ACTUAL_IPV4
  # shellcheck disable=SC2034
  # Variable below comes from .env file
  # shellcheck disable=SC2153
  RECORD_ID=$RECORD_ID_4
  eval "$UPDATE_DNS_COMMAND"
  echo
  echo
fi
if [ "$CURRENT_IPV6" != "$ACTUAL_IPV6" ]; then
  echo "IPv6 Address changed from $CURRENT_IPV6 to $ACTUAL_IPV6! Updating..."
  ## All spellchecks below: variables are used when evaluating the update command defined at the top.
  # shellcheck disable=SC2034
  RECORD_TYPE="AAAA"
  # shellcheck disable=SC2034
  ACTUAL_IP=$ACTUAL_IPV6
  # shellcheck disable=SC2034
  # Variable below comes from .env file
  # shellcheck disable=SC2153
  RECORD_ID=$RECORD_ID_6
  eval "$UPDATE_DNS_COMMAND"
fi

