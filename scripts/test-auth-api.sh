#!/usr/bin/env bash

set -euo pipefail

# Resolve project root and load .env
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
ROOT_DIR="$(cd -- "${SCRIPT_DIR}/.." >/dev/null 2>&1 && pwd)"
ENV_FILE="${ROOT_DIR}/.env"

if [[ -f "${ENV_FILE}" ]]; then
  # Export all variables defined in .env
  set -a
  # shellcheck disable=SC1090
  source "${ENV_FILE}"
  set +a
else
  echo "Missing .env at ${ENV_FILE}"
  exit 1
fi

# Map \& validate required variables from .env
AUTH0_DOMAIN="${AUTH0_DOMAIN:?ENV AUTH0_DOMAIN is required}"
CLIENT_ID="${AUTH0_MGMT_CLIENT_ID:-${AUTH0_CLIENT_ID:-}}"
CLIENT_SECRET="${AUTH0_MGMT_CLIENT_SECRET:-${AUTH0_CLIENT_SECRET:-}}"
AUDIENCE="${AUTH0_AUDIENCE:-${AUDIENCE:-}}"
BASE_URL="${BASE_URL:-http://localhost:8006}"

missing=()
[[ -z "${CLIENT_ID}" ]] && missing+=("AUTH0_MGMT_CLIENT_ID")
[[ -z "${CLIENT_SECRET}" ]] && missing+=("AUTH0_MGMT_CLIENT_SECRET")
[[ -z "${AUDIENCE}" ]] && missing+=("AUTH0_AUDIENCE")
if (( ${#missing[@]} > 0 )); then
  echo "Missing required env vars: ${missing[*]}"
  exit 1
fi

echo "=== Getting Access Token from Auth0 ==="
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

if [ -z "${TOKEN:-}" ]; then
    echo "Failed to get token!"
    echo "Response: $TOKEN_RESPONSE"
    exit 1
fi

echo "Token obtained successfully!"
echo "Token: ${TOKEN:0:50}..."
echo ""

echo "=== Test 1: Health Check (No Auth) ==="
curl -s "${BASE_URL}/" && echo -e "\n"

echo "=== Test 2: Get JWT Token Value ==="
curl -s "${BASE_URL}/jwt" \
  -H "Authorization: Bearer ${TOKEN}" && echo -e "\n"

echo "=== Test 3: Get All Snippets ==="
curl -s "${BASE_URL}/snippets" \
  -H "Authorization: Bearer ${TOKEN}" && echo -e "\n"

echo "=== Test 4: Get Single Snippet ==="
curl -s "${BASE_URL}/snippets/test-123" \
  -H "Authorization: Bearer ${TOKEN}" && echo -e "\n"

echo "=== Test 5: Create Snippet ==="
curl -s -X POST "${BASE_URL}/snippets" \
  -H "Authorization: Bearer ${TOKEN}" \
  -H "Content-Type: application/json" \
  -d '"This is my test snippet content"' && echo -e "\n"

echo "=== Test 6: Get All Users ==="
curl -s "${BASE_URL}/users" \
  -H "Authorization: Bearer ${TOKEN}" && echo -e "\n"

echo "=== Test 7: Create New User ==="
curl -s -X POST "${BASE_URL}/users" \
  -H "Authorization: Bearer ${TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{
    "email": "testuser'$(date +%s)'@example.com",
    "password": "TestPassword123!",
    "name": "Test User",
    "nickname": "testuser",
    "blocked": false
  }' && echo -e "\n"

echo ""
echo "=== All tests completed! ==="
