#!/bin/bash

##############################################################################
# Complete Infrastructure Status Check Script
# 
# This script provides a comprehensive status check of all infrastructure
# components including: Terraform, Kubernetes, Gateway API, ArgoCD, Helm,
# Prometheus, and Grafana with IP addresses and access information.
#
# Usage: ./check-complete-status.sh
##############################################################################

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Helper functions for colored output
print_header() {
    echo -e "\n${CYAN}═══════════════════════════════════════════════════════════════${NC}"
    echo -e "${BLUE}► $1${NC}"
    echo -e "${CYAN}═══════════════════════════════════════════════════════════════${NC}\n"
}

print_section() {
    echo -e "\n${YELLOW}📌 $1${NC}"
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ $1${NC}"
}

##############################################################################
# 1. TERRAFORM STATUS
##############################################################################
print_header "1. TERRAFORM STATUS"

if [ -d "/root/project_nebula/terraform" ]; then
    print_success "Terraform directory found at /root/project_nebula/terraform"
    
    cd /root/project_nebula/terraform
    
    # Check Terraform version
    if command -v terraform &> /dev/null; then
        TF_VERSION=$(terraform version | head -n 1)
        print_info "Terraform Version: $TF_VERSION"
    else
        print_error "Terraform not installed"
    fi
    
    # Check Terraform state
    if [ -f "terraform.tfstate" ]; then
        print_success "Terraform state file exists"
        TF_SERIAL=$(grep '"serial":' terraform.tfstate | head -1 | grep -oE '[0-9]+' | head -1)
        print_info "State Serial Number: $TF_SERIAL"
        
        # Count resources
        RESOURCE_COUNT=$(grep -o '"type": "' terraform.tfstate | wc -l)
        print_info "Total Resources in State: $RESOURCE_COUNT"
    else
        print_error "Terraform state file not found"
    fi
    
    # List modules
    if [ -d "modules" ]; then
        print_info "Terraform Modules:"
        for module in modules/*/; do
            if [ -d "$module" ]; then
                MODULE_NAME=$(basename "$module")
                echo "    └─ $MODULE_NAME"
            fi
        done
    fi
else
    print_error "Terraform directory not found"
fi

##############################################################################
# 2. KUBERNETES CLUSTER STATUS
##############################################################################
print_header "2. KUBERNETES CLUSTER STATUS"

# Check if kubectl is available
if ! command -v kubectl &> /dev/null; then
    print_error "kubectl not installed"
else
    print_success "kubectl is available"
    
    # Kubernetes version
    K8S_VERSION=$(kubectl version --short 2>/dev/null | grep "Server" | awk '{print $3}')
    print_info "Kubernetes Version: $K8S_VERSION"
    
    # Cluster API endpoint
    API_ENDPOINT=$(kubectl cluster-info 2>/dev/null | grep 'Kubernetes master' | awk '{print $NF}')
    print_info "API Endpoint: $API_ENDPOINT"
    
    # Node status
    print_section "Cluster Nodes"
    NODE_COUNT=$(kubectl get nodes --no-headers 2>/dev/null | wc -l)
    print_info "Total Nodes: $NODE_COUNT"
    
    kubectl get nodes --no-headers 2>/dev/null | while read node status rest; do
        if [[ $status == "Ready" ]]; then
            print_success "Node $node: $status"
        else
            print_warning "Node $node: $status"
        fi
    done
    
    # Namespace count
    NS_COUNT=$(kubectl get ns --no-headers 2>/dev/null | wc -l)
    print_info "Total Namespaces: $NS_COUNT"
fi

##############################################################################
# 3. ARGOCD STATUS
##############################################################################
print_header "3. ARGOCD STATUS"

NS="argocd"

if kubectl get namespace $NS &> /dev/null; then
    print_success "ArgoCD namespace exists"
    
    # ArgoCD version
    ARGOCD_VERSION=$(kubectl get deployment -n $NS -l app.kubernetes.io/name=argocd-server -o jsonpath='{.items[0].spec.template.spec.containers[0].image}' 2>/dev/null | grep -oE 'v[0-9]+\.[0-9]+\.[0-9]+')
    print_info "ArgoCD Version: $ARGOCD_VERSION"
    
    # Check ArgoCD server service
    print_section "ArgoCD Server Access"
    ARGOCD_IP=$(kubectl get svc argocd-server -n $NS -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null)
    
    if [ -z "$ARGOCD_IP" ]; then
        ARGOCD_IP=$(kubectl get svc argocd-server -n $NS -o jsonpath='{.spec.clusterIP}' 2>/dev/null)
        print_warning "Using Cluster IP: $ARGOCD_IP"
    else
        print_success "External IP (LoadBalancer): $ARGOCD_IP"
    fi
    
    # Service ports
    print_info "Service Type: $(kubectl get svc argocd-server -n $NS -o jsonpath='{.spec.type}' 2>/dev/null)"
    HTTP_PORT=$(kubectl get svc argocd-server -n $NS -o jsonpath='{.spec.ports[?(@.port==80)].nodePort}' 2>/dev/null)
    HTTPS_PORT=$(kubectl get svc argocd-server -n $NS -o jsonpath='{.spec.ports[?(@.port==443)].nodePort}' 2>/dev/null)
    
    print_info "HTTP Port: 80 (NodePort: $HTTP_PORT)"
    print_info "HTTPS Port: 443 (NodePort: $HTTPS_PORT)"
    
    # Access URLs
    print_info "Access URLs:"
    echo "    └─ HTTP:  http://$ARGOCD_IP"
    echo "    └─ HTTPS: https://$ARGOCD_IP"
    
    # Pod status
    print_section "ArgoCD Pods"
    ARGOCD_PODS=$(kubectl get pods -n $NS --no-headers 2>/dev/null | wc -l)
    ARGOCD_READY=$(kubectl get pods -n $NS -o jsonpath='{.items[?(@.status.conditions[?(@.status=="True")].type=="Ready")].metadata.name}' 2>/dev/null | wc -w)
    print_info "Pods: $ARGOCD_READY / $ARGOCD_PODS Ready"
    
    kubectl get pods -n $NS --no-headers 2>/dev/null | while read pod status rest; do
        if [[ $status == "1/1" ]] || [[ $status == "Running" ]]; then
            print_success "  $pod: $status"
        else
            print_warning "  $pod: $status"
        fi
    done
    
    # Applications
    print_section "ArgoCD Applications"
    kubectl get applications -n $NS 2>/dev/null | tail -n +2 | while read name sync_status health_status rest; do
        if [[ $sync_status == "Synced" ]]; then
            print_success "  $name: Sync=$sync_status, Health=$health_status"
        else
            print_warning "  $name: Sync=$sync_status, Health=$health_status"
        fi
    done
    
    # Credentials info
    print_section "ArgoCD Credentials"
    if [ -f "/root/project_nebula/argocd-password.txt" ]; then
        print_info "Password file exists at: /root/project_nebula/argocd-password.txt"
        print_info "Default username: admin"
    fi
else
    print_error "ArgoCD namespace not found"
fi

##############################################################################
# 4. GATEWAY API STATUS
##############################################################################
print_header "4. GATEWAY API STATUS"

# Check Gateway API CRDs
if kubectl get crd gateways.gateway.networking.k8s.io &> /dev/null; then
    print_success "Gateway API CRDs are installed"
    
    # List gateways
    print_section "Gateways"
    GATEWAY_COUNT=$(kubectl get gateways --all-namespaces --no-headers 2>/dev/null | wc -l)
    
    if [ $GATEWAY_COUNT -gt 0 ]; then
        print_info "Total Gateways: $GATEWAY_COUNT"
        kubectl get gateways --all-namespaces --no-headers 2>/dev/null | while read ns gateway status rest; do
            print_info "  Namespace: $ns, Gateway: $gateway, Status: $status"
        done
    else
        print_warning "No gateways found"
    fi
    
    # List HTTPRoutes
    print_section "HTTPRoutes"
    ROUTE_COUNT=$(kubectl get httproutes --all-namespaces --no-headers 2>/dev/null | wc -l)
    
    if [ $ROUTE_COUNT -gt 0 ]; then
        print_info "Total HTTPRoutes: $ROUTE_COUNT"
        kubectl get httproutes --all-namespaces --no-headers 2>/dev/null | while read ns route rest; do
            print_info "  Namespace: $ns, Route: $route"
        done
    else
        print_warning "No HTTPRoutes found"
    fi
else
    print_warning "Gateway API CRDs not installed"
fi

##############################################################################
# 5. HELM STATUS
##############################################################################
print_header "5. HELM STATUS"

if command -v helm &> /dev/null; then
    HELM_VERSION=$(helm version --short 2>/dev/null)
    print_success "Helm installed: $HELM_VERSION"
    
    # List Helm repositories
    print_section "Helm Repositories"
    REPO_COUNT=$(helm repo list 2>/dev/null | tail -n +2 | wc -l)
    
    if [ $REPO_COUNT -gt 0 ]; then
        print_info "Total Repositories: $REPO_COUNT"
        helm repo list 2>/dev/null | tail -n +2 | while read name url rest; do
            print_info "  Repository: $name → $url"
        done
    else
        print_warning "No Helm repositories configured"
    fi
    
    # List Helm releases across namespaces
    print_section "Helm Releases"
    RELEASE_COUNT=$(helm list --all-namespaces --short 2>/dev/null | wc -l)
    
    if [ $RELEASE_COUNT -gt 0 ]; then
        print_info "Total Releases: $RELEASE_COUNT"
        helm list --all-namespaces 2>/dev/null | tail -n +2 | while read name namespace revision status chart version rest; do
            if [[ $status == "deployed" ]]; then
                print_success "  $name (ns: $namespace): $status - Chart: $chart"
            else
                print_warning "  $name (ns: $namespace): $status - Chart: $chart"
            fi
        done
    else
        print_warning "No Helm releases found"
    fi
else
    print_error "Helm not installed"
fi

##############################################################################
# 6. PROMETHEUS STATUS
##############################################################################
print_header "6. PROMETHEUS STATUS"

NS="monitoring"

if kubectl get namespace $NS &> /dev/null; then
    print_success "Monitoring namespace exists"
    
    # Prometheus service
    print_section "Prometheus Access"
    PROM_IP=$(kubectl get svc -n $NS -l app.kubernetes.io/name=prometheus -o jsonpath='{.items[0].status.loadBalancer.ingress[0].ip}' 2>/dev/null)
    
    if [ -z "$PROM_IP" ]; then
        PROM_IP=$(kubectl get svc -n $NS -l app.kubernetes.io/name=prometheus -o jsonpath='{.items[0].spec.clusterIP}' 2>/dev/null)
        PROM_SVCTYPE="ClusterIP"
    else
        PROM_SVCTYPE="LoadBalancer"
    fi
    
    if [ -n "$PROM_IP" ]; then
        print_info "Service Type: $PROM_SVCTYPE"
        print_success "Prometheus IP: $PROM_IP"
        PROM_PORT=$(kubectl get svc -n $NS -l app.kubernetes.io/name=prometheus -o jsonpath='{.items[0].spec.ports[0].port}' 2>/dev/null)
        print_info "Prometheus Access URL: http://$PROM_IP:$PROM_PORT"
    else
        print_warning "Prometheus service not found"
    fi
    
    # Prometheus pods
    print_section "Prometheus Pods"
    PROM_PODS=$(kubectl get pods -n $NS -l app.kubernetes.io/name=prometheus --no-headers 2>/dev/null | wc -l)
    
    if [ $PROM_PODS -gt 0 ]; then
        print_info "Prometheus Instances: $PROM_PODS"
        kubectl get pods -n $NS -l app.kubernetes.io/name=prometheus --no-headers 2>/dev/null | while read pod status rest; do
            if [[ $status == "1/1" ]] || [[ $status == "Running" ]]; then
                print_success "  $pod: $status"
            else
                print_warning "  $pod: $status"
            fi
        done
    else
        print_warning "No Prometheus pods found"
    fi
else
    print_error "Monitoring namespace not found"
fi

##############################################################################
# 7. GRAFANA STATUS
##############################################################################
print_header "7. GRAFANA STATUS"

NS="monitoring"

if kubectl get namespace $NS &> /dev/null; then
    # Grafana service
    print_section "Grafana Access"
    GRAFANA_IP=$(kubectl get svc -n $NS -l app.kubernetes.io/name=grafana -o jsonpath='{.items[0].status.loadBalancer.ingress[0].ip}' 2>/dev/null)
    
    if [ -z "$GRAFANA_IP" ]; then
        GRAFANA_IP=$(kubectl get svc -n $NS -l app.kubernetes.io/name=grafana -o jsonpath='{.items[0].spec.clusterIP}' 2>/dev/null)
        GRAFANA_SVCTYPE="ClusterIP"
    else
        GRAFANA_SVCTYPE="LoadBalancer"
    fi
    
    if [ -n "$GRAFANA_IP" ]; then
        print_info "Service Type: $GRAFANA_SVCTYPE"
        print_success "Grafana IP: $GRAFANA_IP"
        GRAFANA_PORT=$(kubectl get svc -n $NS -l app.kubernetes.io/name=grafana -o jsonpath='{.items[0].spec.ports[0].port}' 2>/dev/null)
        print_info "Grafana Access URL: http://$GRAFANA_IP:$GRAFANA_PORT"
        print_info "Default Credentials: admin / (check Grafana secret for password)"
    else
        print_warning "Grafana service not found"
    fi
    
    # Grafana pods
    print_section "Grafana Pods"
    GRAFANA_PODS=$(kubectl get pods -n $NS -l app.kubernetes.io/name=grafana --no-headers 2>/dev/null | wc -l)
    
    if [ $GRAFANA_PODS -gt 0 ]; then
        print_info "Grafana Instances: $GRAFANA_PODS"
        kubectl get pods -n $NS -l app.kubernetes.io/name=grafana --no-headers 2>/dev/null | while read pod status rest; do
            if [[ $status == "1/1" ]] || [[ $status == "Running" ]]; then
                print_success "  $pod: $status"
            else
                print_warning "  $pod: $status"
            fi
        done
    else
        print_warning "No Grafana pods found"
    fi
else
    print_error "Monitoring namespace not found"
fi

##############################################################################
# 8. METALLB LOAD BALANCER
##############################################################################
print_header "8. METALLB LOAD BALANCER"

NS="metallb-system"

if kubectl get namespace $NS &> /dev/null; then
    print_success "MetalLB namespace exists"
    
    # Check MetalLB pods
    print_section "MetalLB Components"
    METALLB_PODS=$(kubectl get pods -n $NS --no-headers 2>/dev/null | wc -l)
    print_info "Total Pods: $METALLB_PODS"
    
    kubectl get pods -n $NS --no-headers 2>/dev/null | while read pod status rest; do
        if [[ $status == "1/1" ]] || [[ $status == "Running" ]]; then
            print_success "  $pod: $status"
        else
            print_warning "  $pod: $status"
        fi
    done
    
    # IP Address Pool
    print_section "IP Address Pools"
    POOL_COUNT=$(kubectl get IPAddressPool -n $NS --no-headers 2>/dev/null | wc -l)
    
    if [ $POOL_COUNT -gt 0 ]; then
        kubectl get IPAddressPool -n $NS --no-headers 2>/dev/null | while read pool autoassign rest; do
            print_info "Pool: $pool, Auto-assign: $autoassign"
        done
    fi
else
    print_error "MetalLB namespace not found"
fi

##############################################################################
# 9. SERVICES SUMMARY
##############################################################################
print_header "9. SERVICES SUMMARY"

print_section "LoadBalancer Services (with assigned IPs)"
kubectl get svc --all-namespaces -o wide 2>/dev/null | grep -i loadbalancer | while read ns name type cluster_ip external_ip port selector; do
    if [ "$external_ip" != "<pending>" ] && [ "$external_ip" != "-" ]; then
        print_success "$ns/$name → $external_ip"
    else
        print_warning "$ns/$name → $external_ip (pending)"
    fi
done

##############################################################################
# 10. STORAGE STATUS
##############################################################################
print_header "10. STORAGE & PVCS"

print_section "Persistent Volumes"
PV_COUNT=$(kubectl get pv --no-headers 2>/dev/null | wc -l)
print_info "Total PersistentVolumes: $PV_COUNT"

print_section "Persistent Volume Claims"
PVC_COUNT=$(kubectl get pvc --all-namespaces --no-headers 2>/dev/null | wc -l)
print_info "Total PVCs: $PVC_COUNT"

if [ $PVC_COUNT -gt 0 ]; then
    kubectl get pvc --all-namespaces --no-headers 2>/dev/null | while read ns name status volume capacity rest; do
        print_info "  $ns/$name: $status"
    done
fi

##############################################################################
# 11. CONTAINER IMAGES
##############################################################################
print_header "11. RUNNING CONTAINERS SUMMARY"

print_section "Container Runtime Info"
RUNTIME=$(kubectl get nodes -o jsonpath='{.items[0].status.nodeInfo.containerRuntimeVersion}' 2>/dev/null)
print_info "Container Runtime: $RUNTIME"

print_section "Total Pods by Status"
RUNNING=$(kubectl get pods --all-namespaces --field-selector=status.phase=Running --no-headers 2>/dev/null | wc -l)
PENDING=$(kubectl get pods --all-namespaces --field-selector=status.phase=Pending --no-headers 2>/dev/null | wc -l)
FAILED=$(kubectl get pods --all-namespaces --field-selector=status.phase=Failed --no-headers 2>/dev/null | wc -l)

print_success "Running: $RUNNING"
if [ $PENDING -gt 0 ]; then
    print_warning "Pending: $PENDING"
fi
if [ $FAILED -gt 0 ]; then
    print_error "Failed: $FAILED"
fi

##############################################################################
# 12. QUICK REFERENCE
##############################################################################
print_header "12. QUICK REFERENCE & NEXT STEPS"

print_section "Access Endpoints Summary"
echo "  ArgoCD:    http://$ARGOCD_IP"
echo "  Prometheus: http://$PROM_IP:$PROM_PORT"
echo "  Grafana:    http://$GRAFANA_IP:$GRAFANA_PORT"

print_section "Useful Commands"
echo "  View ArgoCD apps:       kubectl get applications -n argocd"
echo "  ArgoCD sync:            argocd app sync <app-name>"
echo "  Watch deployments:      kubectl get deployments --all-namespaces -w"
echo "  Check pod logs:         kubectl logs -n <namespace> -l <label> --tail=50"
echo "  Port-forward Grafana:   kubectl port-forward -n monitoring svc/grafana 3000:80"
echo "  Port-forward Prometheus: kubectl port-forward -n monitoring svc/prometheus-server 9090:80"

##############################################################################
# FINAL SUMMARY
##############################################################################
print_header "✓ STATUS CHECK COMPLETE"

echo -e "${GREEN}All infrastructure components have been checked.${NC}"
echo -e "${BLUE}For detailed information about specific components, refer to the sections above.${NC}\n"
