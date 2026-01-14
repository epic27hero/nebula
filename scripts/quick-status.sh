#!/bin/bash

##############################################################################
# Quick Infrastructure Status Check (One-liner Summary)
# 
# This is a fast version that shows critical status information at a glance
#
# Usage: ./quick-status.sh
##############################################################################

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}╔════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║         INFRASTRUCTURE QUICK STATUS CHECK                      ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════════╝${NC}\n"

# Kubernetes
K8S=$(kubectl get nodes --no-headers 2>/dev/null | grep Ready | wc -l)
K8S_TOTAL=$(kubectl get nodes --no-headers 2>/dev/null | wc -l)
[ $K8S -eq $K8S_TOTAL ] && echo -e "${GREEN}✓ Kubernetes:${NC} $K8S/$K8S_TOTAL nodes Ready" || echo -e "${RED}✗ Kubernetes:${NC} $K8S/$K8S_TOTAL nodes Ready"

# Terraform
if [ -d "/root/project_nebula/terraform" ] && [ -f "/root/project_nebula/terraform/terraform.tfstate" ]; then
    TF_SERIAL=$(grep '"serial":' /root/project_nebula/terraform/terraform.tfstate | head -1 | grep -oE '[0-9]+' | head -1)
    echo -e "${GREEN}✓ Terraform:${NC} State serial $TF_SERIAL"
else
    echo -e "${RED}✗ Terraform:${NC} Not found or no state"
fi

# ArgoCD
ARGOCD_IP=$(kubectl get svc argocd-server -n argocd -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null)
if [ -n "$ARGOCD_IP" ]; then
    APPS_SYNCED=$(kubectl get applications -n argocd -o jsonpath='{.items[?(@.status.sync.status=="Synced")]}' 2>/dev/null | grep -c "name")
    APPS_TOTAL=$(kubectl get applications -n argocd --no-headers 2>/dev/null | wc -l)
    echo -e "${GREEN}✓ ArgoCD:${NC} $ARGOCD_IP | $APPS_SYNCED/$APPS_TOTAL apps synced"
else
    echo -e "${RED}✗ ArgoCD:${NC} No external IP assigned"
fi

# Gateway API
GW=$(kubectl get gateways --all-namespaces --no-headers 2>/dev/null | wc -l)
[ $GW -gt 0 ] && echo -e "${GREEN}✓ Gateway API:${NC} $GW gateway(s) deployed" || echo -e "${YELLOW}⚠ Gateway API:${NC} No gateways found"

# Helm Releases
RELEASES=$(helm list --all-namespaces --short 2>/dev/null | wc -l)
[ $RELEASES -gt 0 ] && echo -e "${GREEN}✓ Helm Releases:${NC} $RELEASES deployed" || echo -e "${RED}✗ Helm Releases:${NC} None found"

# Prometheus
PROM=$(kubectl get pods -n monitoring -l app.kubernetes.io/name=prometheus --no-headers 2>/dev/null | grep Running | wc -l)
[ $PROM -gt 0 ] && echo -e "${GREEN}✓ Prometheus:${NC} Running (10.43.24.90:80)" || echo -e "${RED}✗ Prometheus:${NC} Not running"

# Grafana
GRAF=$(kubectl get pods -n monitoring -l app.kubernetes.io/name=grafana --no-headers 2>/dev/null | grep Running | wc -l)
[ $GRAF -gt 0 ] && echo -e "${GREEN}✓ Grafana:${NC} Running (10.43.215.176:80)" || echo -e "${RED}✗ Grafana:${NC} Not running"

# MetalLB
MLBPODS=$(kubectl get pods -n metallb-system --no-headers 2>/dev/null | grep Running | wc -l)
[ $MLBPODS -ge 2 ] && echo -e "${GREEN}✓ MetalLB:${NC} All components running" || echo -e "${YELLOW}⚠ MetalLB:${NC} $MLBPODS/2 pods running"

# Pods Overview
RUNNING=$(kubectl get pods --all-namespaces --field-selector=status.phase=Running --no-headers 2>/dev/null | wc -l)
PENDING=$(kubectl get pods --all-namespaces --field-selector=status.phase=Pending --no-headers 2>/dev/null | wc -l)
FAILED=$(kubectl get pods --all-namespaces --field-selector=status.phase=Failed --no-headers 2>/dev/null | wc -l)
echo -e "${GREEN}✓ Pods:${NC} $RUNNING running" && [ $PENDING -gt 0 ] && echo -e "  ${YELLOW}⚠${NC} $PENDING pending" && [ $FAILED -gt 0 ] && echo -e "  ${RED}✗${NC} $FAILED failed"

echo -e "\n${BLUE}════════════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}AccessPoints:${NC}"
echo -e "  ArgoCD:     http://$ARGOCD_IP"
echo -e "  Prometheus: http://10.43.24.90:80"
echo -e "  Grafana:    http://10.43.215.176:80"
echo -e "${BLUE}════════════════════════════════════════════════════════════════${NC}\n"
