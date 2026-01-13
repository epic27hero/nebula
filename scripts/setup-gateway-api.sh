#!/bin/bash
set -e

echo "🌐 Gateway API Setup & Management Script"
echo "=========================================="
echo ""

# Configuration
GATEWAY_API_VERSION="v1.2.0"
ENVOY_GATEWAY_VERSION="v1.2.0"
MODE="${1:-check}"  # check, install, reinstall

# Gateway API CRDs
GATEWAY_CRDS=(
    "gatewayclasses.gateway.networking.k8s.io"
    "gateways.gateway.networking.k8s.io"
    "httproutes.gateway.networking.k8s.io"
    "grpcroutes.gateway.networking.k8s.io"
    "referencegrants.gateway.networking.k8s.io"
    "tcproutes.gateway.networking.k8s.io"
    "tlsroutes.gateway.networking.k8s.io"
    "udproutes.gateway.networking.k8s.io"
    "backendtlspolicies.gateway.networking.k8s.io"
)

# Envoy Gateway CRDs
ENVOY_CRDS=(
    "backendtrafficpolicies.gateway.envoyproxy.io"
    "clienttrafficpolicies.gateway.envoyproxy.io"
    "envoypatchpolicies.gateway.envoyproxy.io"
    "envoyproxies.gateway.envoyproxy.io"
    "securitypolicies.gateway.envoyproxy.io"
)

###########################################
# Check if Gateway API is installed
###########################################
check_installation() {
    echo "🔍 Checking Gateway API installation..."
    echo "---------------------------------------"
    
    local missing_crds=0
    local total_crds=$((${#GATEWAY_CRDS[@]} + ${#ENVOY_CRDS[@]}))
    
    for crd in "${GATEWAY_CRDS[@]}" "${ENVOY_CRDS[@]}"; do
        if kubectl get crd "$crd" &>/dev/null; then
            echo "  ✓ $crd"
        else
            echo "  ✗ $crd (missing)"
            ((missing_crds++))
        fi
    done
    
    echo ""
    if [ $missing_crds -eq 0 ]; then
        echo "✅ Gateway API is fully installed ($total_crds/$total_crds CRDs)"
        
        # Check Envoy Gateway deployment
        if kubectl get deployment envoy-gateway -n envoy-gateway-system &>/dev/null; then
            local ready=$(kubectl get deployment envoy-gateway -n envoy-gateway-system -o jsonpath='{.status.readyReplicas}' 2>/dev/null || echo "0")
            if [ "$ready" -gt 0 ]; then
                echo "✅ Envoy Gateway is running"
            else
                echo "⚠️  Envoy Gateway exists but is not ready"
            fi
        else
            echo "⚠️  Envoy Gateway deployment not found"
        fi
        
        return 0
    else
        echo "⚠️  Gateway API is incomplete ($missing_crds/$total_crds CRDs missing)"
        return 1
    fi
}

###########################################
# Clean existing installation
###########################################
clean_gateway_api() {
    echo ""
    echo "🗑️  Cleaning existing Gateway API installation..."
    echo "------------------------------------------------"
    
    # Delete Gateway resources first (prevents blocking)
    echo "  Deleting Gateway resources..."
    kubectl delete gateways --all -A --ignore-not-found=true --timeout=30s 2>/dev/null || true
    kubectl delete httproutes --all -A --ignore-not-found=true --timeout=30s 2>/dev/null || true
    kubectl delete gatewayclasses --all --ignore-not-found=true --timeout=30s 2>/dev/null || true
    
    # Remove Envoy Gateway
    echo "  Removing Envoy Gateway..."
    kubectl delete -f https://github.com/envoyproxy/gateway/releases/download/${ENVOY_GATEWAY_VERSION}/install.yaml --ignore-not-found=true 2>/dev/null || true
    kubectl delete namespace envoy-gateway-system --ignore-not-found=true --timeout=60s 2>/dev/null || true
    
    sleep 3
    
    # Remove Envoy CRDs
    echo "  Removing Envoy CRDs..."
    for crd in "${ENVOY_CRDS[@]}"; do
        kubectl delete crd "$crd" --ignore-not-found=true --wait=false 2>/dev/null || true
    done
    
    # Remove Gateway API CRDs
    echo "  Removing Gateway API CRDs..."
    for crd in "${GATEWAY_CRDS[@]}"; do
        kubectl delete crd "$crd" --ignore-not-found=true --wait=false 2>/dev/null || true
    done
    
    echo "  Waiting for cleanup to complete..."
    sleep 10
    
    # Force remove any stuck CRDs
    for crd in "${GATEWAY_CRDS[@]}" "${ENVOY_CRDS[@]}"; do
        if kubectl get crd "$crd" &>/dev/null; then
            echo "  Force removing stuck CRD: $crd"
            kubectl patch crd "$crd" -p '{"metadata":{"finalizers":[]}}' --type=merge 2>/dev/null || true
            kubectl delete crd "$crd" --force --grace-period=0 2>/dev/null || true
        fi
    done
    
    sleep 3
    echo "✅ Cleanup complete"
}

###########################################
# Install Gateway API
###########################################
install_gateway_api() {
    echo ""
    echo "📦 Installing Gateway API ${GATEWAY_API_VERSION}..."
    echo "---------------------------------------------------"
    
    # Install Gateway API CRDs
    echo "  Installing Gateway API CRDs..."
    kubectl apply -f https://github.com/kubernetes-sigs/gateway-api/releases/download/${GATEWAY_API_VERSION}/standard-install.yaml
    
    echo "  Waiting for CRDs to be established..."
    sleep 15
    
    # Create gateway-system namespace
    echo "  Creating gateway-system namespace..."
    kubectl create namespace gateway-system --dry-run=client -o yaml | kubectl apply -f -
    
    # Install Envoy Gateway
    echo "  Installing Envoy Gateway ${ENVOY_GATEWAY_VERSION}..."
    kubectl apply -f https://github.com/envoyproxy/gateway/releases/download/${ENVOY_GATEWAY_VERSION}/install.yaml
    
    echo "  Waiting for Envoy Gateway to be ready..."
    kubectl wait --timeout=5m -n envoy-gateway-system deployment/envoy-gateway --for=condition=Available || {
        echo "⚠️  Envoy Gateway deployment timeout - checking status..."
        kubectl get pods -n envoy-gateway-system
    }
    
    echo "✅ Installation complete"
}

###########################################
# Verify installation
###########################################
verify_installation() {
    echo ""
    echo "🔍 Verifying installation..."
    echo "----------------------------"
    
    echo ""
    echo "Envoy Gateway Pods:"
    kubectl get pods -n envoy-gateway-system -o wide 2>/dev/null || echo "  No pods found"
    
    echo ""
    echo "Gateway API CRDs:"
    kubectl get crd | grep gateway.networking.k8s.io || echo "  No Gateway API CRDs found"
    
    echo ""
    echo "Envoy Gateway CRDs:"
    kubectl get crd | grep gateway.envoyproxy.io || echo "  No Envoy Gateway CRDs found"
    
    echo ""
    echo "GatewayClasses:"
    kubectl get gatewayclass 2>/dev/null || echo "  No GatewayClasses found (normal if not configured yet)"
    
    echo ""
    echo "Gateways (all namespaces):"
    kubectl get gateway -A 2>/dev/null || echo "  No Gateways found (normal if not created yet)"
}

###########################################
# Main execution
###########################################
case "$MODE" in
    check)
        check_installation
        ;;
    
    install)
        if check_installation 2>/dev/null; then
            echo ""
            echo "✅ Gateway API is already installed"
            echo "Use '$0 reinstall' to reinstall"
        else
            install_gateway_api
            verify_installation
        fi
        ;;
    
    reinstall)
        echo "⚠️  This will remove and reinstall Gateway API"
        read -p "Continue? (yes/no): " confirm
        if [ "$confirm" = "yes" ]; then
            clean_gateway_api
            install_gateway_api
            verify_installation
        else
            echo "❌ Cancelled"
            exit 0
        fi
        ;;
    
    clean)
        echo "⚠️  This will remove Gateway API completely"
        read -p "Continue? (yes/no): " confirm
        if [ "$confirm" = "yes" ]; then
            clean_gateway_api
        else
            echo "❌ Cancelled"
            exit 0
        fi
        ;;
    
    *)
        echo "Usage: $0 {check|install|reinstall|clean}"
        echo ""
        echo "Commands:"
        echo "  check      - Check if Gateway API is installed"
        echo "  install    - Install Gateway API (if not present)"
        echo "  reinstall  - Remove and reinstall Gateway API"
        echo "  clean      - Remove Gateway API completely"
        echo ""
        echo "Examples:"
        echo "  $0 check"
        echo "  $0 install"
        echo "  $0 reinstall"
        exit 1
        ;;
esac

echo ""
echo "🏁 Done!"