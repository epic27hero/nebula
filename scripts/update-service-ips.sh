#!/bin/bash

# ============================================================================
# UPDATE SERVICE IP CONFIGURATION
# ============================================================================
# This script allows you to update the fixed service IP configuration.
#
# Usage:
#   ./scripts/update-service-ips.sh              # Interactive mode
#   ./scripts/update-service-ips.sh --no-prompt  # Use default fixed IPs
#
# The default fixed IPs are:
#   - FastAPI: 192.168.0.203
#   - ArgoCD: 192.168.0.202
#   - Prometheus: 192.168.0.204:9090
#   - Grafana: 192.168.0.205:3000
#
# ============================================================================

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="$SCRIPT_DIR/../config/service-endpoints.conf"

echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}⚙️  UPDATE SERVICE IP CONFIGURATION${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo ""

# Default fixed IPs
DEFAULT_FASTAPI_IP="192.168.0.203"
DEFAULT_FASTAPI_PORT="80"
DEFAULT_ARGOCD_IP="192.168.0.202"
DEFAULT_ARGOCD_PORT="80"
DEFAULT_PROMETHEUS_IP="192.168.0.204"
DEFAULT_PROMETHEUS_PORT="9090"
DEFAULT_GRAFANA_IP="192.168.0.205"
DEFAULT_GRAFANA_PORT="3000"

# Interactive mode unless --no-prompt is passed
INTERACTIVE=true
if [ "$1" = "--no-prompt" ]; then
    INTERACTIVE=false
fi

if [ "$INTERACTIVE" = true ]; then
    echo -e "${CYAN}📋 Current Fixed IPs:${NC}"
    echo "   🔵 FastAPI:    ${DEFAULT_FASTAPI_IP}:${DEFAULT_FASTAPI_PORT}"
    echo "   ⚙️  ArgoCD:     ${DEFAULT_ARGOCD_IP}:${DEFAULT_ARGOCD_PORT}"
    echo "   📊 Prometheus: ${DEFAULT_PROMETHEUS_IP}:${DEFAULT_PROMETHEUS_PORT}"
    echo "   📈 Grafana:    ${DEFAULT_GRAFANA_IP}:${DEFAULT_GRAFANA_PORT}"
    echo ""
    echo -e "${YELLOW}Enter new values (or press Enter to keep defaults):${NC}"
    echo ""
    
    read -p "FastAPI IP [${DEFAULT_FASTAPI_IP}]: " FASTAPI_IP
    FASTAPI_IP=${FASTAPI_IP:-$DEFAULT_FASTAPI_IP}
    
    read -p "FastAPI Port [${DEFAULT_FASTAPI_PORT}]: " FASTAPI_PORT
    FASTAPI_PORT=${FASTAPI_PORT:-$DEFAULT_FASTAPI_PORT}
    
    read -p "ArgoCD IP [${DEFAULT_ARGOCD_IP}]: " ARGOCD_IP
    ARGOCD_IP=${ARGOCD_IP:-$DEFAULT_ARGOCD_IP}
    
    read -p "ArgoCD Port [${DEFAULT_ARGOCD_PORT}]: " ARGOCD_PORT
    ARGOCD_PORT=${ARGOCD_PORT:-$DEFAULT_ARGOCD_PORT}
    
    read -p "Prometheus IP [${DEFAULT_PROMETHEUS_IP}]: " PROMETHEUS_IP
    PROMETHEUS_IP=${PROMETHEUS_IP:-$DEFAULT_PROMETHEUS_IP}
    
    read -p "Prometheus Port [${DEFAULT_PROMETHEUS_PORT}]: " PROMETHEUS_PORT
    PROMETHEUS_PORT=${PROMETHEUS_PORT:-$DEFAULT_PROMETHEUS_PORT}
    
    read -p "Grafana IP [${DEFAULT_GRAFANA_IP}]: " GRAFANA_IP
    GRAFANA_IP=${GRAFANA_IP:-$DEFAULT_GRAFANA_IP}
    
    read -p "Grafana Port [${DEFAULT_GRAFANA_PORT}]: " GRAFANA_PORT
    GRAFANA_PORT=${GRAFANA_PORT:-$DEFAULT_GRAFANA_PORT}
else
    # Use default fixed IPs
    FASTAPI_IP="$DEFAULT_FASTAPI_IP"
    FASTAPI_PORT="$DEFAULT_FASTAPI_PORT"
    ARGOCD_IP="$DEFAULT_ARGOCD_IP"
    ARGOCD_PORT="$DEFAULT_ARGOCD_PORT"
    PROMETHEUS_IP="$DEFAULT_PROMETHEUS_IP"
    PROMETHEUS_PORT="$DEFAULT_PROMETHEUS_PORT"
    GRAFANA_IP="$DEFAULT_GRAFANA_IP"
    GRAFANA_PORT="$DEFAULT_GRAFANA_PORT"
fi

echo ""
echo -e "${CYAN}✓ Creating configuration with:${NC}"
echo "   🔵 FastAPI:    ${FASTAPI_IP}:${FASTAPI_PORT}"
echo "   ⚙️  ArgoCD:     ${ARGOCD_IP}:${ARGOCD_PORT}"
echo "   📊 Prometheus: ${PROMETHEUS_IP}:${PROMETHEUS_PORT}"
echo "   📈 Grafana:    ${GRAFANA_IP}:${GRAFANA_PORT}"
echo ""

# Create the config file
mkdir -p "$(dirname "$CONFIG_FILE")"

cat > "$CONFIG_FILE" << 'EOFCONFIG'
# ============================================================================
# SERVICE ENDPOINTS CONFIGURATION
# ============================================================================
# Fixed Load Balancer IPs for Project Nebula services
# These are static/reserved IPs assigned to services
#
# To update IPs:
#   1. Manually edit this file, OR
#   2. Run: ./scripts/update-service-ips.sh
#
# To validate IPs:
#   ./scripts/detect-service-ips.sh
#
# Last Updated: $(date '+%Y-%m-%d %H:%M:%S')
# ============================================================================

# FastAPI Application
export FASTAPI_LB_IP="$FASTAPI_IP"
export FASTAPI_LB_PORT="$FASTAPI_PORT"
export FASTAPI_PROTOCOL="http"
export FASTAPI_URL="http://$FASTAPI_IP:$FASTAPI_PORT"
export FASTAPI_DOCS_URL="http://$FASTAPI_IP:$FASTAPI_PORT/docs"
export FASTAPI_HEALTH_URL="http://$FASTAPI_IP:$FASTAPI_PORT/health"
export FASTAPI_METRICS_URL="http://$FASTAPI_IP:$FASTAPI_PORT/metrics"

# Monitoring - Prometheus
export PROMETHEUS_IP="$PROMETHEUS_IP"
export PROMETHEUS_PORT="$PROMETHEUS_PORT"
export PROMETHEUS_PROTOCOL="http"
export PROMETHEUS_URL="http://$PROMETHEUS_IP:$PROMETHEUS_PORT"

# Monitoring - Grafana
export GRAFANA_IP="$GRAFANA_IP"
export GRAFANA_PORT="$GRAFANA_PORT"
export GRAFANA_PROTOCOL="http"
export GRAFANA_URL="http://$GRAFANA_IP:$GRAFANA_PORT"
export GRAFANA_CREDENTIALS="admin/grafana"

# Management - ArgoCD
export ARGOCD_IP="$ARGOCD_IP"
export ARGOCD_PORT="$ARGOCD_PORT"
export ARGOCD_PROTOCOL="http"
export ARGOCD_URL="http://$ARGOCD_IP:$ARGOCD_PORT"

# Kubernetes - API Server Metrics
export KUBE_API_SERVER="https://10.43.0.1:443/metrics"

# ============================================================================
# QUICK REFERENCE - CURL COMMANDS
# ============================================================================
# FastAPI Application
# curl http://$FASTAPI_IP          # API endpoint
# curl http://$FASTAPI_IP/docs     # Swagger documentation
# curl http://$FASTAPI_IP/health   # Health check
# curl http://$FASTAPI_IP/metrics  # Prometheus metrics
#
# Monitoring
# curl http://$PROMETHEUS_IP:$PROMETHEUS_PORT     # Prometheus
# curl http://$GRAFANA_IP:$GRAFANA_PORT          # Grafana (admin/grafana)
#
# Management
# curl http://$ARGOCD_IP           # ArgoCD UI
# ============================================================================
EOFCONFIG

echo -e "${GREEN}✅ Configuration updated successfully!${NC}"
echo "   File: $CONFIG_FILE"
echo ""
echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}✓ Fixed IPs Configuration Complete${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo ""
echo "💡 Next steps:"
echo "   1. Verify configuration: ./scripts/detect-service-ips.sh"
echo "   2. Use in pipelines by sourcing: source config/service-endpoints.conf"
echo ""
