#!/bin/bash

# ============================================================================
# CONFIGURE METALLB FOR FIXED SERVICE IPs
# ============================================================================
# This script configures MetalLB to use specific IP pools for services
#
# Fixed IPs to assign:
#   - FastAPI:    192.168.0.203
#   - ArgoCD:     192.168.0.202
#   - Prometheus: 192.168.0.204
#   - Grafana:    192.168.0.205
#
# Usage:
#   ./scripts/configure-fixed-ips.sh
#
# ============================================================================

set -e

echo "🔧 Configuring MetalLB for Fixed Service IPs..."
echo "=================================================="
echo ""

# Check if kubectl is available
if ! command -v kubectl &> /dev/null; then
    echo "❌ kubectl not found. Please install kubectl."
    exit 1
fi

# Check if MetalLB namespace exists
echo "✓ Checking MetalLB installation..."
if ! kubectl get namespace metallb-system &>/dev/null; then
    echo "⚠️  MetalLB not installed in metallb-system namespace"
    echo "   Install MetalLB first with: ./scripts/install-metallb.sh"
    exit 1
fi

echo "✅ MetalLB found in metallb-system namespace"
echo ""

# Create MetalLB IPAddressPool for fixed IPs
echo "📝 Creating MetalLB IP Address Pool..."
cat <<'EOF' | kubectl apply -f -
apiVersion: metallb.io/v1beta1
kind: IPAddressPool
metadata:
  name: project-nebula-fixed-ips
  namespace: metallb-system
spec:
  addresses:
  - 192.168.0.202-192.168.0.205  # Range includes all 4 IPs
EOF

echo "✅ IP Address Pool created"
echo ""

# Create BGP Advertisement (or L2Advertisement depending on version)
echo "📡 Creating Advertisement..."
cat <<'EOF' | kubectl apply -f -
apiVersion: metallb.io/v1beta1
kind: L2Advertisement
metadata:
  name: project-nebula-l2
  namespace: metallb-system
spec:
  ipAddressPools:
  - project-nebula-fixed-ips
EOF

echo "✅ L2Advertisement created"
echo ""

# Create service annotations for specific IPs
echo "🏷️  Creating service annotations..."
cat <<'EOF' | kubectl apply -f -
---
# FastAPI - 192.168.0.203
apiVersion: v1
kind: Service
metadata:
  name: fastapi-app-lb
  namespace: production
  annotations:
    metallb.universe.tf/address-pool: project-nebula-fixed-ips
spec:
  type: LoadBalancer
  loadBalancerIP: 192.168.0.203
  selector:
    app: fastapi
  ports:
  - port: 80
    targetPort: 80
    protocol: TCP

---
# ArgoCD - 192.168.0.202
apiVersion: v1
kind: Service
metadata:
  name: argocd-server
  namespace: argocd
  annotations:
    metallb.universe.tf/address-pool: project-nebula-fixed-ips
spec:
  type: LoadBalancer
  loadBalancerIP: 192.168.0.202
  selector:
    app.kubernetes.io/name: argocd-server
  ports:
  - name: http
    port: 80
    targetPort: 8080
    protocol: TCP
  - name: https
    port: 443
    targetPort: 8443
    protocol: TCP

---
# Prometheus - 192.168.0.204
apiVersion: v1
kind: Service
metadata:
  name: prometheus-lb
  namespace: monitoring
  annotations:
    metallb.universe.tf/address-pool: project-nebula-fixed-ips
spec:
  type: LoadBalancer
  loadBalancerIP: 192.168.0.204
  selector:
    app.kubernetes.io/name: prometheus
  ports:
  - port: 9090
    targetPort: 9090
    protocol: TCP

---
# Grafana - 192.168.0.205
apiVersion: v1
kind: Service
metadata:
  name: grafana-lb
  namespace: monitoring
  annotations:
    metallb.universe.tf/address-pool: project-nebula-fixed-ips
spec:
  type: LoadBalancer
  loadBalancerIP: 192.168.0.205
  selector:
    app.kubernetes.io/instance: grafana
    app.kubernetes.io/name: grafana
  ports:
  - port: 3000
    targetPort: 3000
    protocol: TCP
EOF

echo "✅ Services configured with fixed IPs"
echo ""

echo "🔄 Waiting for LoadBalancer IPs to be assigned (30 seconds)..."
sleep 30

echo ""
echo "📊 Final IP Assignment:"
echo "=================================================="
kubectl get svc -n production fastapi-app-lb -o wide 2>/dev/null | tail -1 || echo "fastapi-app-lb: waiting..."
kubectl get svc -n argocd argocd-server -o wide 2>/dev/null | tail -1 || echo "argocd-server: waiting..."
kubectl get svc -n monitoring prometheus-lb -o wide 2>/dev/null | tail -1 || echo "prometheus-lb: waiting..."
kubectl get svc -n monitoring grafana-lb -o wide 2>/dev/null | tail -1 || echo "grafana-lb: waiting..."

echo ""
echo "=================================================="
echo "✅ MetalLB Configuration Complete!"
echo "=================================================="
echo ""
echo "Service IPs should now be:"
echo "   🔵 FastAPI:    http://192.168.0.203"
echo "   ⚙️  ArgoCD:     http://192.168.0.202"
echo "   📊 Prometheus: http://192.168.0.204:9090"
echo "   📈 Grafana:    http://192.168.0.205:3000"
echo ""
echo "💡 If IPs are still <pending>, check:"
echo "   kubectl get svc -A -o wide"
echo "   kubectl logs -n metallb-system -l app=metallb"
echo ""
