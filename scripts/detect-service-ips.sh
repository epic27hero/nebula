#!/bin/bash

# ============================================================================
# VALIDATE FIXED SERVICE IPs
# ============================================================================
# This script validates that services are accessible at their FIXED IP addresses:
#   - FastAPI: 192.168.0.203
#   - ArgoCD: 192.168.0.202
#   - Prometheus: 192.168.0.204:9090
#   - Grafana: 192.168.0.205:3000
#
# The IPs are STATIC and should not change. This script verifies they're responsive.
#
# Usage:
#   ./scripts/detect-service-ips.sh         # Validate fixed IPs
#   ./scripts/detect-service-ips.sh --raw   # Show raw detection from cluster
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

# Fixed IPs
FASTAPI_IP="192.168.0.203"
FASTAPI_PORT="80"
ARGOCD_IP="192.168.0.202"
ARGOCD_PORT="80"
PROMETHEUS_IP="192.168.0.204"
PROMETHEUS_PORT="9090"
GRAFANA_IP="192.168.0.205"
GRAFANA_PORT="3000"

echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}✓ FIXED SERVICE ENDPOINTS - VALIDATION${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo ""

echo -e "${CYAN}📋 Configured Fixed IPs:${NC}"
echo "   🔵 FastAPI:    http://${FASTAPI_IP}:${FASTAPI_PORT}"
echo "   ⚙️  ArgoCD:     http://${ARGOCD_IP}:${ARGOCD_PORT}"
echo "   📊 Prometheus: http://${PROMETHEUS_IP}:${PROMETHEUS_PORT}"
echo "   📈 Grafana:    http://${GRAFANA_IP}:${GRAFANA_PORT}"
echo ""

# Test connectivity if curl is available
if command -v curl &> /dev/null; then
    echo -e "${CYAN}🧪 Testing Connectivity:${NC}"
    
    # Test FastAPI
    echo -n "   FastAPI (${FASTAPI_IP}:${FASTAPI_PORT})... "
    if timeout 3 curl -s "http://${FASTAPI_IP}:${FASTAPI_PORT}/health" > /dev/null 2>&1; then
        echo -e "${GREEN}✓ Responding${NC}"
    else
        echo -e "${YELLOW}⚠ Not responding (may be starting)${NC}"
    fi
    
    # Test ArgoCD
    echo -n "   ArgoCD (${ARGOCD_IP}:${ARGOCD_PORT})... "
    if timeout 3 curl -s "http://${ARGOCD_IP}:${ARGOCD_PORT}" > /dev/null 2>&1; then
        echo -e "${GREEN}✓ Responding${NC}"
    else
        echo -e "${YELLOW}⚠ Not responding (may be starting)${NC}"
    fi
    
    # Test Prometheus
    echo -n "   Prometheus (${PROMETHEUS_IP}:${PROMETHEUS_PORT})... "
    if timeout 3 curl -s "http://${PROMETHEUS_IP}:${PROMETHEUS_PORT}/-/healthy" > /dev/null 2>&1; then
        echo -e "${GREEN}✓ Responding${NC}"
    else
        echo -e "${YELLOW}⚠ Not responding (may be starting)${NC}"
    fi
    
    # Test Grafana
    echo -n "   Grafana (${GRAFANA_IP}:${GRAFANA_PORT})... "
    if timeout 3 curl -s "http://${GRAFANA_IP}:${GRAFANA_PORT}/api/health" > /dev/null 2>&1; then
        echo -e "${GREEN}✓ Responding${NC}"
    else
        echo -e "${YELLOW}⚠ Not responding (may be starting)${NC}"
    fi
    
    echo ""
else
    echo -e "${YELLOW}⚠ curl not available - skipping connectivity tests${NC}"
    echo ""
fi

# Show detection from cluster if requested
if [ "$1" = "--raw" ]; then
    echo -e "${CYAN}🔍 Detecting Actual Service IPs from Cluster:${NC}"
    echo ""
    
    if ! command -v kubectl &> /dev/null; then
        echo -e "${RED}❌ kubectl not found${NC}"
        exit 1
    fi
    
    if ! kubectl cluster-info &>/dev/null; then
        echo -e "${RED}❌ Cannot connect to Kubernetes cluster${NC}"
        exit 1
    fi
    
    echo "FastAPI service:"
    kubectl get svc fastapi-app -n production -o wide 2>/dev/null || echo "  (not found)"
    echo ""
    
    echo "ArgoCD service:"
    kubectl get svc argocd-server -n argocd -o wide 2>/dev/null || echo "  (not found)"
    echo ""
    
    echo "Prometheus service:"
    kubectl get svc prometheus-server -n monitoring -o wide 2>/dev/null || echo "  (not found)"
    echo ""
    
    echo "Grafana service:"
    kubectl get svc grafana -n monitoring -o wide 2>/dev/null || echo "  (not found)"
    echo ""
fi

echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}✓ Fixed IPs are configured in config/service-endpoints.conf${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo ""
echo "💡 Quick Reference - curl commands:"
echo "   # FastAPI"
echo "   curl http://${FASTAPI_IP}          # API endpoint"
echo "   curl http://${FASTAPI_IP}/docs     # Swagger docs"
echo "   curl http://${FASTAPI_IP}/health   # Health check"
echo "   curl http://${FASTAPI_IP}/metrics  # Prometheus metrics"
echo ""
echo "   # Monitoring"
echo "   curl http://${PROMETHEUS_IP}:${PROMETHEUS_PORT}     # Prometheus"
echo "   curl http://${GRAFANA_IP}:${GRAFANA_PORT}          # Grafana (admin/grafana)"
echo ""
echo "   # Management"
echo "   curl http://${ARGOCD_IP}           # ArgoCD"
echo ""
echo "✅ Script complete!"
