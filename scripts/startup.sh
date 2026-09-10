#!/usr/bin/env bash

set -euo pipefail # "-e" if any line fails to execute, it stops right there instead of continuing
# "-u" undefined vars r treated as errors, "-o pipefail" if command in pipeline fail all is considered failed
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
CHART_DIR="${PROJECT_ROOT}/helm/python-redis"

EXPECTED_CONTEXT="kind-redis-cluster"
RELEASE_NAME="redis-app"
NAMESPACE="default"

echo "========================================"
echo " Redis + FastAPI Helm Startup"
echo "========================================"
echo

if ! command -v helm > /dev/null 2>&1; then
    echo "ERROR: Helm is not installed."
    exit 1
fi

CURRENT_CONTEXT="$(kubectl config current-context)"

echo "Checking Kubernetes context..."
echo "${CURRENT_CONTEXT}"
echo

if [ "${CURRENT_CONTEXT}" != "${EXPECTED_CONTEXT}" ]; then
    echo "ERROR: Expected Kubernetes context '${EXPECTED_CONTEXT}'."
    echo "Current context is '${CURRENT_CONTEXT}'."
    echo
    echo "Switch contexts with:"
    echo "kubectl config use-context ${EXPECTED_CONTEXT}"
    exit 1
fi

echo "Kubernetes context is correct."
echo

echo "Checking NGINX IngressClass..."

if ! kubectl get ingressclass nginx > /dev/null 2>&1; then
    echo "ERROR: NGINX Ingress Controller is not installed."
    exit 1
fi

echo "NGINX IngressClass is available."
echo

echo "Checking local FastAPI image inside kind..."

if ! docker exec redis-cluster-control-plane \
    crictl images | grep -q "python-api"; then

    echo "ERROR: python-api image is not loaded into the kind node."
    echo
    echo "Build and load it with:"
    echo "docker build -t python-api:latest ${PROJECT_ROOT}"
    echo "kind load docker-image python-api:latest --name redis-cluster"
    exit 1
fi

echo "python-api image is available inside kind."
echo

echo "Linting Helm chart..."
helm lint "${CHART_DIR}"

echo
echo "Installing/upgrading Helm release '${RELEASE_NAME}'..."

helm upgrade --install "${RELEASE_NAME}" "${CHART_DIR}" --namespace "${NAMESPACE}"

echo
echo "Waiting for Redis Deployment..."
kubectl rollout status \
    deployment/"${RELEASE_NAME}-redis" \
    --namespace "${NAMESPACE}" \
    --timeout=180s

echo
echo "Waiting for FastAPI Deployment..."
kubectl rollout status \
    deployment/"${RELEASE_NAME}-python-api" \
    --namespace "${NAMESPACE}" \
    --timeout=180s

echo
echo "========================================"
echo " Helm Deployment complete"
echo "========================================"
echo

echo "Helm release:"
helm list --namespace "${NAMESPACE}"

echo "Pods:"
kubectl get pods --namespace "${NAMESPACE}"

echo
echo "Services:"
kubectl get services --namespace "${NAMESPACE}"

echo
echo "Ingress:"
kubectl get ingress --namespace "${NAMESPACE}"

echo
echo "PersistentVolumeClaim:"
kubectl get pvc --namespace "${NAMESPACE}"

echo
echo "Application URLs:"
echo "http://localhost/api/"
echo "http://localhost/api/cache"
echo "http://localhost/api/secret-test"