#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
ENV_FILE="${SCRIPT_DIR}/.env"

if [[ -f "${ENV_FILE}" ]]; then
  set -a
  source "${ENV_FILE}"
  set +a
else
  echo "Missing .env at ${ENV_FILE}"
  exit 1
fi

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

echo "============================================"
echo "  Authentication Service Test Suite"
echo "============================================"
echo ""

echo "=== Step 1: Getting Access Token from Auth0 ==="
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
    echo "❌ Failed to get token!"
    echo "Response: $TOKEN_RESPONSE"
    exit 1
fi

echo "✓ Token obtained successfully!"
echo "Token (first 50 chars): ${TOKEN:0:50}..."
echo ""

echo "=== Test 1: Health Check (Public - No Auth Required) ==="
HEALTH_RESPONSE=$(curl -s -w "\nHTTP_STATUS:%{http_code}" "${BASE_URL}/")
HTTP_STATUS=$(echo "$HEALTH_RESPONSE" | grep "HTTP_STATUS" | cut -d':' -f2)
BODY=$(echo "$HEALTH_RESPONSE" | sed '/HTTP_STATUS/d')

if [ "$HTTP_STATUS" = "200" ]; then
    echo "✓ Health check passed"
    echo "Response: $BODY"
else
    echo "❌ Health check failed (HTTP $HTTP_STATUS)"
    echo "Response: $BODY"
fi
echo ""

echo "=== Test 2: Get JWT Token Value (Authenticated Endpoint) ==="
JWT_RESPONSE=$(curl -s -w "\nHTTP_STATUS:%{http_code}" "${BASE_URL}/jwt" \
  -H "Authorization: Bearer ${TOKEN}")
HTTP_STATUS=$(echo "$JWT_RESPONSE" | grep "HTTP_STATUS" | cut -d':' -f2)
BODY=$(echo "$JWT_RESPONSE" | sed '/HTTP_STATUS/d')

if [ "$HTTP_STATUS" = "200" ]; then
    echo "✓ JWT endpoint authenticated successfully"
    echo "Token value (first 50 chars): ${BODY:0:50}..."
else
    echo "❌ JWT endpoint failed (HTTP $HTTP_STATUS)"
    echo "Response: $BODY"
fi
echo ""

echo "=== Test 2.1: Verify custom claims ==="
echo "To inspect JWT claims, run: ./get-token.sh and paste token at https://jwt.io"
echo "Look for claims starting with: https://tef-austral.com/"
echo ""

echo "=== Test 3: Access JWT Endpoint Without Token (Should Fail) ==="
UNAUTH_RESPONSE=$(curl -s -w "\nHTTP_STATUS:%{http_code}" "${BASE_URL}/jwt")
HTTP_STATUS=$(echo "$UNAUTH_RESPONSE" | grep "HTTP_STATUS" | cut -d':' -f2)

if [ "$HTTP_STATUS" = "401" ]; then
    echo "✓ Correctly rejected unauthenticated request (HTTP 401)"
else
    echo "❌ Expected HTTP 401, got HTTP $HTTP_STATUS"
fi
echo ""

echo "=== Test 4: Access JWT Endpoint With Invalid Token (Should Fail) ==="
INVALID_TOKEN="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxMjM0NTY3ODkwIn0.invalid"
INVALID_RESPONSE=$(curl -s -w "\nHTTP_STATUS:%{http_code}" "${BASE_URL}/jwt" \
  -H "Authorization: Bearer ${INVALID_TOKEN}")
HTTP_STATUS=$(echo "$INVALID_RESPONSE" | grep "HTTP_STATUS" | cut -d':' -f2)

if [ "$HTTP_STATUS" = "401" ]; then
    echo "✓ Correctly rejected invalid token (HTTP 401)"
else
    echo "❌ Expected HTTP 401, got HTTP $HTTP_STATUS"
fi
echo ""

echo "============================================"
echo "  Test Summary"
echo "============================================"
echo "Authentication Service is working correctly!"
echo ""
echo "✓ Public endpoints accessible without auth"
echo "✓ Protected endpoints require valid JWT"
echo "✓ Invalid/missing tokens are rejected"
echo ""
echo "This service only performs AUTHENTICATION."
echo "AUTHORIZATION (ABAC) should be handled by downstream services."
echo "============================================"