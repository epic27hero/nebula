#!/bin/bash
set -e

echo "🔍 PROJECT NEBULA - COMPLETE STATUS CHECK"
echo "=========================================="
echo ""

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 1. KUBERNETES CLUSTER STATUS
echo -e "${BLUE}1️⃣  KUBERNETES CLUSTER STATUS${NC}"
echo "---"
kubectl cluster-info 2>/dev/null || echo "❌ Cluster not accessible"
echo ""
echo "Nodes:"
kubectl get nodes -o wide
echo ""

# 2. NAMESPACES
echo -e "${BLUE}2️⃣  KUBERNETES NAMESPACES${NC}"
echo "---"
kubectl get ns | grep -E "argocd|production|staging|development|monitoring|metallb|gateway" || true
echo ""

# 3. ARGOCD STATUS
echo -e "${BLUE}3️⃣  ARGOCD DEPLOYMENT${NC}"
echo "---"
ARGOCD_PODS=$(kubectl get pods -n argocd --no-headers | wc -l)
ARGOCD_RUNNING=$(kubectl get pods -n argocd -o jsonpath='{.items[?(@.status.phase=="Running")].metadata.name}' | wc -w)
echo "Pods Running: $ARGOCD_RUNNING/$ARGOCD_PODS"
kubectl get pods -n argocd -o wide | tail -n +2 | head -5
echo ""

# 4. ARGOCD SERVER ACCESS
echo -e "${BLUE}4️⃣  ARGOCD SERVER ACCESS${NC}"
echo "---"
ARGOCD_IP=$(kubectl get svc -n argocd argocd-server -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || echo "pending")
ARGOCD_PORT=$(kubectl get svc -n argocd argocd-server -o jsonpath='{.spec.ports[?(@.name=="http")].nodePort}' 2>/dev/null)
if [ "$ARGOCD_IP" != "pending" ]; then
    echo -e "${GREEN}✅ ArgoCD Web UI:${NC} http://$ARGOCD_IP:80"
    echo "   Username: admin"
    echo "   Password: $(cat argocd-password.txt 2>/dev/null || echo 'Check argocd-password.txt')"
else
    echo -e "${YELLOW}⏳ ArgoCD IP pending assignment${NC}"
fi
echo ""

# 5. ARGOCD APPLICATIONS
echo -e "${BLUE}5️⃣  ARGOCD APPLICATIONS${NC}"
echo "---"
kubectl get applications -n argocd -o wide
echo ""

# 6. PRODUCTION DEPLOYMENT
echo -e "${BLUE}6️⃣  PRODUCTION DEPLOYMENT${NC}"
echo "---"
kubectl get deployment -n production
echo ""
echo "Production Pods:"
kubectl get pods -n production
echo ""

# 7. FASTAPI SERVICE ACCESS
echo -e "${BLUE}7️⃣  FASTAPI APPLICATION ACCESS${NC}"
echo "---"
FASTAPI_LB_IP=$(kubectl get svc -n production fastapi-app-lb -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || echo "pending")

if [ "$FASTAPI_LB_IP" != "pending" ] && [ -n "$FASTAPI_LB_IP" ]; then
    echo -e "${GREEN}✅ FastAPI via LoadBalancer:${NC} http://$FASTAPI_LB_IP"
    echo "   Swagger UI: http://$FASTAPI_LB_IP/docs"
    echo "   Health: http://$FASTAPI_LB_IP/health"
    echo "   Metrics: http://$FASTAPI_LB_IP/metrics"
else
    echo -e "${RED}❌ FastAPI LoadBalancer IP not assigned${NC}"
fi
echo ""

# 8. MONITORING STACK
echo -e "${BLUE}8️⃣  MONITORING STACK${NC}"
echo "---"
echo "Prometheus:"
PROMETHEUS_LB=$(kubectl get svc -n monitoring prometheus-lb -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || echo "pending")
if [ "$PROMETHEUS_LB" != "pending" ] && [ -n "$PROMETHEUS_LB" ]; then
    echo -e "${GREEN}✅ http://$PROMETHEUS_LB:9090${NC}"
else
    echo -e "${RED}❌ LoadBalancer IP pending${NC}"
fi

echo ""
echo "Grafana:"
GRAFANA_LB=$(kubectl get svc -n monitoring grafana-lb -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || echo "pending")
GRAFANA_PASS=$(cat grafana-password.txt 2>/dev/null || echo "grafana")
if [ "$GRAFANA_LB" != "pending" ] && [ -n "$GRAFANA_LB" ]; then
    echo -e "${GREEN}✅ http://$GRAFANA_LB:3000${NC}"
    echo "   Username: admin"
    echo "   Password: $GRAFANA_PASS"
else
    echo -e "${RED}❌ LoadBalancer IP pending${NC}"
fi
echo ""

# 9. METALLB STATUS
echo -e "${BLUE}9️⃣  METALLB (LOAD BALANCER)${NC}"
echo "---"
kubectl get pods -n metallb-system
echo ""
echo "IP Pool:"
kubectl get ipaddresspool -n metallb-system || echo "No IP pools configured"
echo ""

# 10. GATEWAY API
echo -e "${BLUE}🔟 GATEWAY API${NC}"
echo "---"
kubectl get gateways -n production
echo ""

# 11. TERRAFORM STATE
echo -e "${BLUE}1️⃣1️⃣  TERRAFORM STATE${NC}"
echo "---"
if [ -f "terraform/terraform.tfstate" ]; then
    SERIAL=$(jq -r '.serial' terraform/terraform.tfstate 2>/dev/null)
    RESOURCES=$(jq '.resources | length' terraform/terraform.tfstate 2>/dev/null)
    echo -e "${GREEN}✅ State Version:${NC} $SERIAL"
    echo "   Resources: $RESOURCES"
else
    echo -e "${RED}❌ No terraform state found${NC}"
fi
echo ""

# 12. GIT SYNC STATUS
echo -e "${BLUE}1️⃣2️⃣  GIT REPOSITORY${NC}"
echo "---"
cd /root/project_nebula
COMMIT=$(git rev-parse --short HEAD 2>/dev/null)
BRANCH=$(git rev-parse --abbrev-ref HEAD 2>/dev/null)
REMOTE=$(git config --get remote.origin.url 2>/dev/null)
echo "Current: $BRANCH @ $COMMIT"
echo "Remote: $REMOTE"
echo "Status:"
git status --short 2>/dev/null | head -10 || echo "Clean"
echo ""

# SUMMARY
echo -e "${BLUE}═══════════════════════════════════${NC}"
echo -e "${BLUE}📋 QUICK ACCESS REFERENCE${NC}"
echo -e "${BLUE}═══════════════════════════════════${NC}"
echo ""
echo -e "${GREEN}🌐 ArgoCD Web UI:${NC}"
echo "   http://$ARGOCD_IP"
echo ""
echo -e "${GREEN}📊 Monitoring:${NC}"
if [ "$PROMETHEUS_LB" != "pending" ] && [ -n "$PROMETHEUS_LB" ]; then
    echo "   Prometheus: http://$PROMETHEUS_LB:9090"
else
    echo "   Prometheus: (IP pending)"
fi
if [ "$GRAFANA_LB" != "pending" ] && [ -n "$GRAFANA_LB" ]; then
    echo "   Grafana: http://$GRAFANA_LB:3000"
else
    echo "   Grafana: (IP pending)"
fi
echo ""
echo -e "${GREEN}🚀 Application:${NC}"
if [ "$FASTAPI_LB_IP" != "pending" ] && [ -n "$FASTAPI_LB_IP" ]; then
    echo "   FastAPI: http://$FASTAPI_LB_IP"
    echo "   Swagger: http://$FASTAPI_LB_IP/docs"
else
    echo "   FastAPI: (IP pending)"
fi
echo ""
echo -e "${BLUE}═══════════════════════════════════${NC}"
