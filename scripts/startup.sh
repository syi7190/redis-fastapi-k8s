#!/usr/bin/env bash

set -euo pipefail # "-e" if any line fails to execute, it stops right there instead of continuing
# "-u" undefined vars r treated as errors, "-o pipefail" if command in pipeline fail all is considered failed
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
ARGOCD_APPLICATION="${PROJECT_ROOT}/argocd/application.yaml"

EXPECTED_CONTEXT="kind-redis-cluster"
ARGOCD_NAMESPACE="argocd"
APPLICATION_NAME="redis-app"
APPLICATION_NAMESPACE="default"

echo "========================================"
echo " Redis + FastAPI Argo CD Startup"
echo "========================================"
echo

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

echo "Checking Argo CD namespace..."

if ! kubectl get namespace "${ARGOCD_NAMESPACE}" > /dev/null 2>&1; then
    echo "ERROR: Argo CD namespace '${ARGOCD_NAMESPACE}' does not exist."
    echo "Install Argo CD before running this script."
    exit 1
fi

echo "Argo CD namespace exists."
echo

echo "Checking Argo CD Application CRD..."

if ! kubectl get crd applications.argoproj.io > /dev/null 2>&1; then
    echo "ERROR: Argo CD Application CRD is not installed."
    exit 1
fi

echo "Argo CD Appication CRD is available."
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

echo "Applying Argo CD Application..."
kubectl apply -f "${ARGOCD_APPLICATION}"

echo
echo "Requesting an Argo CD refresh..."
kubectl annotate \
    application "${APPLICATION_NAME}" \
    --namespace "${ARGOCD_NAMESPACE}" \
    argocd.argoproj.io/refresh=hard \
    --overwrite > /dev/null

echo
echo "Waiting for Argo CD to create the Redis Deployment..."

for attempt in {1..60}; do
    if kubectl get deployment \
        "${APPLICATION_NAME}-redis" \
        --namespace "${APPLICATION_NAMESPACE}" \
        > /dev/null 2>&1; then
        break
    fi

    sleep 5
done

if ! kubectl get deployment \
    "${APPLICATION_NAME}-redis" \
    --namespace "${APPLICATION_NAMESPACE}" \
    > /dev/null 2>&1; then

    echo "ERROR: Argo CD did not create the Redis Deployment."
    echo
    echo "Application status:"
    kubectl get application \
        "${APPLICATION_NAME}" \
        --namespace "${ARGOCD_NAMESPACE}"
    exit 1
fi

echo "Redis Deployment exists."
echo

echo "Waiting for Argo CD to create the FastAPI Deployment..."

for attempt in {1..60}; do
    if kubectl get deployment \
        "${APPLICATION_NAME}-python-api" \
        --namespace "${APPLICATION_NAMESPACE}" \
        > /dev/null 2>&1; then
        break
    fi

    sleep 5
done

if ! kubectl get deployment \
    "${APPLICATION_NAME}-python-api" \
    --namespace "${APPLICATION_NAMESPACE}" \
    > /dev/null 2>&1; then

    echo "ERROR: Argo CD did not create the FastAPI Deployment."
    echo
    echo "Application status:"
    kubectl get application \
        "${APPLICATION_NAME}" \
        --namespace "${ARGOCD_NAMESPACE}"
    exit 1
fi

echo "FastAPI Deployment exists."
echo

echo
echo "Waiting for Redis Deployment..."
kubectl rollout status \
    deployment/"${APPLICATION_NAME}-redis" \
    --namespace "${APPLICATION_NAMESPACE}" \
    --timeout=180s

echo
echo "Waiting for FastAPI Deployment..."
kubectl rollout status \
    deployment/"${APPLICATION_NAME}-python-api" \
    --namespace "${APPLICATION_NAMESPACE}" \
    --timeout=180s

echo
echo "========================================"
echo " Argo CD Deployment ready"
echo "========================================"
echo

echo "Argo CD Application:"
kubectl get application \
    "${APPLICATION_NAME}" \
    --namespace "${ARGOCD_NAMESPACE}"

echo
echo "Pods:"
kubectl get pods \
    --namespace "${APPLICATION_NAMESPACE}"

echo
echo "Services:"
kubectl get svc \
    --namespace "${APPLICATION_NAMESPACE}"

echo
echo "Ingress:"
kubectl get ingress \
    --namespace "${APPLICATION_NAMESPACE}"

echo
echo "PersistentVolumeClaim:"
kubectl get pvc \
    --namespace "${APPLICATION_NAMESPACE}" || true

echo
echo "Application URLs:"
echo "http://localhost/api/"
echo "http://localhost/api/cache"
echo "http://localhost/api/secret-test"
echo
echo "Argo CD now owns application synchronization."
echo "Do not run Helm upgrade/install directly for this application."