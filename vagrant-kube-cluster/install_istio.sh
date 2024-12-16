#!/bin/bash

set -euo pipefail

# ANSI color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color


# ============================
# Variables
# ============================
NAMESPACE_ISTIO="istio-system"
NAMESPACE_ISTIO_GATEWAY="istio-system"


########################################
# Install Istio
########################################
echo -e "${CYAN}Installing Istio...${NC}"
helm repo add istio https://istio-release.storage.googleapis.com/charts && echo -e "${GREEN}Istio repo added.${NC}"
helm repo update && echo -e "${GREEN}Helm repos updated.${NC}"

kubectl create namespace "$NAMESPACE_ISTIO" || true
kubectl create namespace "$NAMESPACE_ISTIO_GATEWAY" || true

helm install istio-base istio/base -n "$NAMESPACE_ISTIO" --version 1.21.0
echo -e "${YELLOW}Waiting a moment for istio-base CRDs...${NC}"
sleep 10

helm install istiod istio/istiod -n "$NAMESPACE_ISTIO" \
  --version 1.21.0 \
  --set global.proxy.autoInject=enabled \
  --set global.proxy.privileged=true \
  --set meshConfig.accessLogFile="/dev/stdout" \
  --set persistence.enabled=true \
  --set persistence.storageClass=local-path \
  --set persistence.size=8Gi

echo -e "${YELLOW}Waiting for istiod to be ready...${NC}"
kubectl rollout status -n "$NAMESPACE_ISTIO" deployment/istiod

helm install istio-ingressgateway istio/gateway -n "$NAMESPACE_ISTIO_GATEWAY" --version 1.21.0
echo -e "${YELLOW}Waiting for istio-ingressgateway to be ready...${NC}"
kubectl rollout status -n "$NAMESPACE_ISTIO_GATEWAY" deployment/istio-ingressgateway

echo -e "${GREEN}Istio installed successfully.${NC}"