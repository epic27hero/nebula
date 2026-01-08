set -e

echo "🌐 Installing Gateway API..."

# Install Gateway API CRDs
echo "📦 Installing Gateway API CRDs (v1.0.0)..."
kubectl apply -f https://github.com/kubernetes-sigs/gateway-api/releases/download/v1.0.0/standard-install.yaml

echo "⏳ Waiting for CRDs to be established..."
sleep 10

# Verify CRDs installation
echo "✅ Verifying Gateway API CRDs..."
kubectl get crd gateways.gateway.networking.k8s.io
kubectl get crd gatewayclasses.gateway.networking.k8s.io
kubectl get crd httproutes.gateway.networking.k8s.io

# Create namespace for gateway system
kubectl create namespace gateway-system --dry-run=client -o yaml | kubectl apply -f -

# Install Envoy Gateway (Gateway API implementation)
echo "📦 Installing Envoy Gateway..."
kubectl apply -f https://github.com/envoyproxy/gateway/releases/download/v1.0.0/install.yaml

echo "⏳ Waiting for Envoy Gateway to be ready..."
kubectl wait --timeout=5m -n envoy-gateway-system deployment/envoy-gateway --for=condition=Available

echo "✅ Gateway API installed successfully!"
echo ""
echo "Verify installation:"
echo "  kubectl get gatewayclass"
echo "  kubectl get gateway -A"