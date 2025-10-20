#!/bin/bash

set -e

AUTH0_DOMAIN="tef-austral.us.auth0.com"
CLIENT_ID="KuVymmoEvGBrTIPkIERGKaGGvphD0yaF"
CLIENT_SECRET="fHRAwEdsmPb6-aioNNjZ7F2V8BZhobDGvOnWU_FIe1cWUOzAI3D6z0FL8Q5VoV3W"
AUDIENCE="https://tef-austral.com/api"
BASE_URL="http://localhost:8006"

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

TOKEN=$(echo $TOKEN_RESPONSE | grep -o '"access_token":"[^"]*' | cut -d'"' -f4)

if [ -z "$TOKEN" ]; then
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