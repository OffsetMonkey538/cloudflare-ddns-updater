#!/bin/sh

UPDATE_DNS_COMMAND="curl -s -X PUT \"https://api.cloudflare.com/client/v4/zones/\$ZONE_ID/dns_records/\$RECORD_ID\" \
  -H \"Authorization: Bearer \$API_TOKEN\" \
  -H \"Content-Type: application/json\" \
  --data \"{
    \\\"type\\\": \\\"\$RECORD_TYPE\\\",
    \\\"name\\\": \\\"\$DOMAIN\\\",
    \\\"content\\\": \\\"\$ACTUAL_IP\\\",
    \\\"ttl\\\": \$TTL,
    \\\"proxied\\\": false,
    \\\"comment\\\": \\\"Automatically updated on \$(date '+%Y-%m-%d_%H-%M-%S')\\\"
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
  ALL_RECORDS=$(eval "$LIST_RECORDS_COMMAND")
  echo "IPv4 record id: $(echo "$ALL_RECORDS" | jq '.result[] | select(.name=="'"$DOMAIN"'" and .type=="A") | .id')"
  echo "IPv6 record id: $(echo "$ALL_RECORDS" | jq '.result[] | select(.name=="'"$DOMAIN"'" and .type=="AAAA") | .id')"
  exit
fi

# Get current addresses for the domain
CURRENT_IPV4=$(RECORD_ID=$RECORD_ID_4 eval "$GET_RECORD_COMMAND | jq '.result.content' | tail -c +2 | head -c -2") # Json has quotes around the value so remove
CURRENT_IPV6=$(RECORD_ID=$RECORD_ID_6 eval "$GET_RECORD_COMMAND | jq '.result.content' | tail -c +2 | head -c -2") # Json has quotes around the value so remove

# Get actual addresses of the computer
ACTUAL_IPV4=$(curl -s https://api.ipify.org)
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

