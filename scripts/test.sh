#!/bin/bash

set -e

EXPECTED_CONTEXT="kind-redis-cluster"
BASE_URL="http://localhost/api"

CURRENT_CONTEXT="$(kubectl config current-context)"

if [ "${CURRENT_CONTEXT}" != "${EXPECTED_CONTEXT}" ]; then
    echo "ERROR: Expected Kubernetes context '${EXPECTED_CONTEXT}'."
    echo "Current context is '${CURRENT_CONTEXT}'."
    exit 1
fi

echo "========================================"
echo " Redis + FastAPI Ingress Test"
echo "========================================"
echo


echo "Testing FastAPI root endpoint through NGINX Ingress..."
curl -s --fail "${BASE_URL}/" # -s means silent so there isnt any fluff
echo
echo

read -p "Enter the key: " key
read -p "Enter the value: " value

ENCODED_KEY=$(printf '%s' "${key}" | jq -sRr @uri)
ENCODED_VALUE=$(printf '%s' "${value}" | jq -sRr @uri)

echo
echo "Storing key/value pair..."
curl --fail-with-body -sS -X POST \
    "${BASE_URL}/cache?key=${ENCODED_KEY}&value=${ENCODED_VALUE}"
    
echo
echo

echo "Retrieving key/value pair..."
curl --fail-with-body -sS \
    "${BASE_URL}/cache?key=${ENCODED_KEY}"

echo
echo

echo "Testing Kubernete Secret injection..."
curl -s --fail "${BASE_URL}/secret-test"

echo
echo

echo "========================================"
echo " Test complete"
echo "========================================"