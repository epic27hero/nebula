#!/bin/bash

# ============================================================================
# GitLab CI/CD Dynamic Variables Configurator
# ============================================================================
# This script helps set up GitLab CI/CD variables for Project Nebula
# It discovers current service IPs from the K3s cluster and provides instructions
# ============================================================================

set -e

echo "🔧 Project Nebula - GitLab CI/CD Variables Setup"
echo "=================================================="
echo ""

# Color codes
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to get service IP
get_service_ip() {
    local service=$1
    local namespace=$2
    kubectl get svc "$service" -n "$namespace" -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || echo ""
}

# Check if kubectl is available
if ! command -v kubectl &> /dev/null; then
    echo "❌ kubectl not found. Please install kubectl or run this script on a machine with k3s access."
    exit 1
fi

echo -e "${BLUE}📊 Discovering service endpoints from K3s cluster...${NC}"
echo ""

# Discover current IPs
ARGOCD_IP=$(get_service_ip "argocd-server" "argocd")
FASTAPI_IP=$(get_service_ip "fastapi-app-lb" "production")
PROMETHEUS_IP=$(kubectl get svc prometheus-server -n monitoring -o jsonpath='{.spec.clusterIP}' 2>/dev/null || echo "")
GRAFANA_IP=$(kubectl get svc grafana -n monitoring -o jsonpath='{.spec.clusterIP}' 2>/dev/null || echo "")

# Set defaults if not found
ARGOCD_IP=${ARGOCD_IP:-192.168.0.205}
FASTAPI_IP=${FASTAPI_IP:-192.168.0.206}
PROMETHEUS_IP=${PROMETHEUS_IP:-10.43.24.90}
GRAFANA_IP=${GRAFANA_IP:-10.43.215.176}

echo -e "${GREEN}✓ Discovered IPs:${NC}"
echo "  • ArgoCD:     $ARGOCD_IP"
echo "  • FastAPI:    $FASTAPI_IP"
echo "  • Prometheus: $PROMETHEUS_IP"
echo "  • Grafana:    $GRAFANA_IP"
echo ""

# GitLab information
read -p "$(echo -e ${BLUE}📋 Enter GitLab hostname [192.168.0.190]: ${NC})" GITLAB_HOST
GITLAB_HOST=${GITLAB_HOST:-192.168.0.190}

read -p "$(echo -e ${BLUE}📋 Enter GitLab port [80]: ${NC})" GITLAB_PORT
GITLAB_PORT=${GITLAB_PORT:-80}

read -p "$(echo -e ${BLUE}📋 Enter GitLab protocol [http]: ${NC})" GITLAB_PROTOCOL
GITLAB_PROTOCOL=${GITLAB_PROTOCOL:-http}

echo ""
echo -e "${YELLOW}📝 Summary of variables to add to GitLab:${NC}"
echo ""
echo "Go to: Project → Settings → CI/CD → Variables"
echo ""
cat << EOF

Variable Name             | Value
=====================================================
GITLAB_HOST              | $GITLAB_HOST
GITLAB_PORT              | $GITLAB_PORT
GITLAB_PROTOCOL          | $GITLAB_PROTOCOL
ARGOCD_IP                | $ARGOCD_IP
ARGOCD_PORT              | 80
ARGOCD_PROTOCOL          | http
FASTAPI_LB_IP            | $FASTAPI_IP
FASTAPI_LB_PORT          | 80
FASTAPI_PROTOCOL         | http
PROMETHEUS_IP            | $PROMETHEUS_IP
PROMETHEUS_PORT          | 80
PROMETHEUS_PROTOCOL      | http
GRAFANA_IP               | $GRAFANA_IP
GRAFANA_PORT             | 80
GRAFANA_PROTOCOL         | http
DEPLOY_SERVER            | 192.168.0.113
DEPLOY_USER              | root

EOF

echo ""
echo -e "${BLUE}🔑 To add these variables via GitLab UI:${NC}"
echo ""
echo "1. Go to: http://$GITLAB_HOST/root/project_nebula/-/settings/ci_cd"
echo "2. Scroll to 'Variables' section"
echo "3. Click 'Add variable' for each variable above"
echo "4. Set the Variable name and Value"
echo "5. Optionally mark as 'Protected' for sensitive values"
echo "6. Click 'Add variable' to save"
echo ""

echo -e "${BLUE}💾 Alternative: Save to .gitlab-ci.environment.yml${NC}"
echo ""
echo "Create .gitlab-ci.environment.yml with:"
echo ""
cat << EOF > /tmp/gitlab-ci.environment.example.yml
# .gitlab-ci.environment.yml
# Override default variables for your environment

variables:
  GITLAB_HOST: $GITLAB_HOST
  GITLAB_PORT: "$GITLAB_PORT"
  GITLAB_PROTOCOL: $GITLAB_PROTOCOL
  ARGOCD_IP: $ARGOCD_IP
  ARGOCD_PORT: "80"
  ARGOCD_PROTOCOL: "http"
  FASTAPI_LB_IP: $FASTAPI_IP
  FASTAPI_LB_PORT: "80"
  FASTAPI_PROTOCOL: "http"
  PROMETHEUS_IP: $PROMETHEUS_IP
  PROMETHEUS_PORT: "80"
  PROMETHEUS_PROTOCOL: "http"
  GRAFANA_IP: $GRAFANA_IP
  GRAFANA_PORT: "80"
  GRAFANA_PROTOCOL: "http"
  DEPLOY_SERVER: "192.168.0.113"
  DEPLOY_USER: "root"
EOF

cat /tmp/gitlab-ci.environment.example.yml
echo ""

echo -e "${GREEN}✅ Setup complete!${NC}"
echo ""
echo "📖 For more information, see: docs/GITLAB_CI_VARIABLES.md"
echo ""
