set -e

echo "🔧 Gateway API Troubleshooting and Fix Script"
echo "=============================================="
echo ""

# Function to check CRD status
check_crd_status() {
    local crd=$1
    if kubectl get crd "$crd" &> /dev/null; then
        echo "✓ $crd exists"
        # Check for version issues
        local stored_versions=$(kubectl get crd "$crd" -o jsonpath='{.status.storedVersions[*]}')
        local spec_versions=$(kubectl get crd "$crd" -o jsonpath='{.spec.versions[*].name}')
        echo "  Stored versions: $stored_versions"
        echo "  Spec versions: $spec_versions"
        return 0
    else
        echo "✗ $crd does not exist"
        return 1
    fi
}

echo "Step 1: Checking existing Gateway API CRDs..."
echo "----------------------------------------------"

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

ENVOY_CRDS=(
    "backendtrafficpolicies.gateway.envoyproxy.io"
    "clienttrafficpolicies.gateway.envoyproxy.io"
    "envoypatchpolicies.gateway.envoyproxy.io"
    "envoyproxies.gateway.envoyproxy.io"
    "securitypolicies.gateway.envoyproxy.io"
)

HAS_ISSUES=false
for crd in "${GATEWAY_CRDS[@]}" "${ENVOY_CRDS[@]}"; do
    if ! check_crd_status "$crd"; then
        HAS_ISSUES=true
    fi
    echo ""
done

if [ "$HAS_ISSUES" = true ]; then
    echo "⚠️  Issues detected with Gateway API CRDs"
    echo ""
fi

echo "Step 2: Clean removal of existing installations..."
echo "---------------------------------------------------"

read -p "Do you want to remove and reinstall Gateway API? (yes/no): " confirm
if [ "$confirm" != "yes" ]; then
    echo "Aborted."
    exit 0
fi

# Delete Gateway resources first
echo "🗑️  Deleting Gateway resources..."
kubectl delete gateways --all -A --ignore-not-found=true --timeout=30s
kubectl delete httproutes --all -A --ignore-not-found=true --timeout=30s
kubectl delete gatewayclasses --all --ignore-not-found=true --timeout=30s

# Delete Envoy Gateway
echo "🗑️  Removing Envoy Gateway..."
if kubectl get namespace envoy-gateway-system &> /dev/null; then
    kubectl delete -f https://github.com/envoyproxy/gateway/releases/download/v1.2.0/install.yaml --ignore-not-found=true
    kubectl delete namespace envoy-gateway-system --ignore-not-found=true --wait=true --timeout=60s
fi

echo "⏳ Waiting for resources to be cleaned up..."
sleep 5

# Delete Envoy CRDs
echo "🗑️  Removing Envoy CRDs..."
for crd in "${ENVOY_CRDS[@]}"; do
    kubectl delete crd "$crd" --ignore-not-found=true --wait=false
done

sleep 2

# Delete Gateway API CRDs
echo "🗑️  Removing Gateway API CRDs..."
for crd in "${GATEWAY_CRDS[@]}"; do
    echo "  Deleting $crd..."
    kubectl delete crd "$crd" --ignore-not-found=true --wait=false
done

echo "⏳ Waiting for all CRDs to be fully removed..."
sleep 10

# Verify cleanup
echo "✅ Verifying cleanup..."
for crd in "${GATEWAY_CRDS[@]}"; do
    if kubectl get crd "$crd" &> /dev/null; then
        echo "  ⚠️  $crd still exists, forcing deletion..."
        kubectl patch crd "$crd" -p '{"metadata":{"finalizers":[]}}' --type=merge
        kubectl delete crd "$crd" --force --grace-period=0
    fi
done

sleep 5

echo ""
echo "Step 3: Fresh installation of Gateway API..."
echo "---------------------------------------------"

# Install Gateway API CRDs
echo "📦 Installing Gateway API v1.2.0..."
kubectl apply -f https://github.com/kubernetes-sigs/gateway-api/releases/download/v1.2.0/standard-install.yaml

echo "⏳ Waiting for CRDs to be established..."
sleep 15

# Verify Gateway API CRDs
echo "✅ Verifying Gateway API CRDs..."
kubectl get crd | grep gateway.networking.k8s.io

# Create gateway-system namespace
echo "📦 Creating gateway-system namespace..."
kubectl create namespace gateway-system --dry-run=client -o yaml | kubectl apply -f -

# Install Envoy Gateway
echo "📦 Installing Envoy Gateway v1.2.0..."
kubectl apply -f https://github.com/envoyproxy/gateway/releases/download/v1.2.0/install.yaml

echo "⏳ Waiting for Envoy Gateway deployment..."
kubectl wait --timeout=5m -n envoy-gateway-system deployment/envoy-gateway --for=condition=Available

echo ""
echo "Step 4: Final verification..."
echo "------------------------------"

# Check deployments
echo "Checking Envoy Gateway pods:"
kubectl get pods -n envoy-gateway-system

echo ""
echo "Checking Gateway API CRDs:"
kubectl get crd | grep gateway

echo ""
echo "Checking GatewayClasses:"
kubectl get gatewayclass 2>/dev/null || echo "  No GatewayClasses found (this is normal)"

echo ""
echo "✅ Gateway API fix completed successfully!"
echo ""
echo "🎯 Next steps:"
echo "  1. Apply GatewayClass: kubectl apply -f gateway-api/gateway-class.yaml"
echo "  2. Create Gateways for your applications"
echo "  3. Create HTTPRoutes to route traffic"