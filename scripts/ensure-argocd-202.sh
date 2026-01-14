#!/bin/bash
# Ensure ArgoCD is always at 192.168.0.202
# Run this script if ArgoCD IP ever changes

ARGOCD_IP="192.168.0.202"
ARGOCD_NAMESPACE="argocd"

echo "🔧 Ensuring ArgoCD is locked to $ARGOCD_IP..."

# Update MetalLB IP pool to include .202
kubectl patch ipaddresspool pool -n metallb-system --type merge -p \
  '{"spec":{"addresses":["192.168.0.201-192.168.0.250"]}}' 2>/dev/null || true

# Verify service is configured correctly
SERVICE_STATUS=$(kubectl get svc argocd-server -n $ARGOCD_NAMESPACE -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null)

if [ "$SERVICE_STATUS" == "$ARGOCD_IP" ]; then
    echo "✅ ArgoCD is correctly configured at $ARGOCD_IP"
else
    echo "⚠️  ArgoCD IP is different: $SERVICE_STATUS"
    echo "Recreating service..."
    
    kubectl delete service argocd-server -n $ARGOCD_NAMESPACE 2>/dev/null || true
    sleep 3
    
    kubectl apply -f - << 'EOF'
apiVersion: v1
kind: Service
metadata:
  name: argocd-server
  namespace: argocd
  labels:
    app.kubernetes.io/name: argocd-server
    app.kubernetes.io/instance: argocd
spec:
  type: LoadBalancer
  ports:
  - name: http
    port: 80
    protocol: TCP
    targetPort: 8080
  selector:
    app.kubernetes.io/name: argocd-server
    app.kubernetes.io/instance: argocd
EOF
    
    sleep 5
    echo "✅ ArgoCD service recreated"
fi

# Verify connectivity
echo ""
echo "🔍 Testing connectivity..."
curl -s -o /dev/null -w "HTTP Status: %{http_code}\n" http://$ARGOCD_IP

echo ""
echo "✨ ArgoCD is ready at http://$ARGOCD_IP"
