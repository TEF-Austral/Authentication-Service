#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
ENV_FILE="${SCRIPT_DIR}/.env"

if [[ -f "${ENV_FILE}" ]]; then
  set -a
  source "${ENV_FILE}"
  set +a
fi

AUTH0_DOMAIN="${AUTH0_DOMAIN}"
CLIENT_ID="${AUTH0_MGMT_CLIENT_ID}"
CLIENT_SECRET="${AUTH0_MGMT_CLIENT_SECRET}"
AUDIENCE="${AUTH0_AUDIENCE}"

TOKEN_RESPONSE=$(curl -s --request POST \
  --url "https://${AUTH0_DOMAIN}/oauth/token" \
  --header 'content-type: application/json' \
  --data '{
    "client_id":"'${CLIENT_ID}'",
    "client_secret":"'${CLIENT_SECRET}'",
    "audience":"'${AUDIENCE}'",
    "grant_type":"client_credentials"
  }')

TOKEN=$(echo "$TOKEN_RESPONSE" | grep -o '"access_token":"[^"]*' | cut -d'"' -f4)

echo "$TOKEN"