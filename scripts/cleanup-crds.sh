#!/bin/bash
set -e

echo "🧹 Starting comprehensive cleanup..."

# ============================================
# 1. Remove Helm Releases First
# ============================================
echo "📦 Removing Helm releases..."
helm uninstall argocd -n argocd --wait 2>/dev/null || true
helm uninstall metallb -n metallb-system --wait 2>/dev/null || true
helm uninstall envoy-gateway -n gateway-system --wait 2>/dev/null || true

sleep 5

# ============================================
# 2. Remove Webhooks (Important!)
# ============================================
echo "🪝 Removing webhooks..."
kubectl delete validatingwebhookconfiguration metallb-webhook-configuration --ignore-not-found=true
kubectl delete validatingwebhookconfiguration argocd-webhook --ignore-not-found=true
kubectl delete validatingwebhookconfiguration envoy-gateway --ignore-not-found=true
kubectl delete mutatingwebhookconfiguration metallb-webhook-configuration --ignore-not-found=true
kubectl delete mutatingwebhookconfiguration argocd-webhook --ignore-not-found=true
kubectl delete mutatingwebhookconfiguration envoy-gateway --ignore-not-found=true

# ============================================
# 3. Remove ArgoCD Resources
# ============================================
echo "🗑️ Removing ArgoCD resources..."

# Delete ArgoCD CRDs
kubectl delete crd applications.argoproj.io --ignore-not-found=true
kubectl delete crd applicationsets.argoproj.io --ignore-not-found=true
kubectl delete crd appprojects.argoproj.io --ignore-not-found=true

# Delete ArgoCD ClusterRoles
kubectl get clusterrole -o name | grep argocd | xargs -r kubectl delete 2>/dev/null || true

# Delete ArgoCD ClusterRoleBindings
kubectl get clusterrolebinding -o name | grep argocd | xargs -r kubectl delete 2>/dev/null || true

# ============================================
# 4. Remove MetalLB Resources
# ============================================
echo "🗑️ Removing MetalLB resources..."

# Delete all MetalLB CRDs
kubectl get crd -o name | grep metallb.io | xargs -r kubectl delete 2>/dev/null || true

# Delete MetalLB ClusterRoles
kubectl get clusterrole -o name | grep metallb | xargs -r kubectl delete 2>/dev/null || true

# Delete MetalLB ClusterRoleBindings
kubectl get clusterrolebinding -o name | grep metallb | xargs -r kubectl delete 2>/dev/null || true

# ============================================
# 5. Remove Gateway API Resources
# ============================================
echo "🗑️ Removing Gateway API resources..."

# Delete Gateway API CRDs
kubectl get crd -o name | grep gateway.networking.k8s.io | xargs -r kubectl delete 2>/dev/null || true

# Delete Envoy Gateway resources
kubectl get clusterrole -o name | grep envoy | xargs -r kubectl delete 2>/dev/null || true
kubectl get clusterrolebinding -o name | grep envoy | xargs -r kubectl delete 2>/dev/null || true

# ============================================
# 6. Remove Namespaces
# ============================================
echo "🗑️ Removing namespaces..."

# First, try graceful deletion
# for ns in argocd metallb-system gateway-system development staging production monitoring; do
for ns in argocd metallb-system gateway-system monitoring; do
    kubectl delete namespace $ns --timeout=30s --ignore-not-found=true 2>/dev/null || {
        echo "Force deleting namespace: $ns"
        kubectl get namespace $ns -o json 2>/dev/null | \
            jq '.spec.finalizers = []' | \
            kubectl replace --raw "/api/v1/namespaces/$ns/finalize" -f - 2>/dev/null || true
    }
done

echo "⏳ Waiting for complete cleanup..."
sleep 15

echo ""
echo "✅ Cleanup complete!"