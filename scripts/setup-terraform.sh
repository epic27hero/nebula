#!/bin/bash
set -e

terraform version | grep -q "1." || {
  echo "❌ Terraform 1.x required"
  exit 1
}


MODE=${MODE:-auto}
CLEAN=${CLEAN:-false}

echo "🏗️ Terraform setup started (mode: $MODE)"

# Check if cleanup is needed
if [ "$CLEAN" = "true" ]; then
    echo ""
    echo "⚠️  WARNING: This will destroy all existing resources!"
    if [ "$MODE" = "interactive" ]; then
        read -p "Continue with cleanup? (yes/no): " confirm
        if [ "$confirm" != "yes" ]; then
            echo "❌ Cleanup cancelled"
            exit 0
        fi
    fi
    
    echo "🧹 Running cleanup..."
    ./scripts/cleanup-crds.sh
    
    echo "⏳ Waiting for cluster to stabilize (30s)..."
    sleep 30
    
    # Verify cleanup
    echo "🔍 Verifying cleanup..."
    ./scripts/check-cluster.sh
fi

# Import existing namespaces if they exist
echo "🔍 Checking for existing namespaces..."
cd terraform
for ns in development staging production; do
    if kubectl get namespace $ns >/dev/null 2>&1; then
        echo "📦 Importing existing namespace: $ns"
        terraform import "kubernetes_namespace_v1.envs[\"$ns\"]" $ns 2>/dev/null || true
    fi
done
cd ..

cd terraform

# Always run init
echo "🔹 terraform init"
terraform init

echo "🔹 terraform validate"
terraform validate

echo "🔹 terraform plan"
terraform plan -out=tfplan

if [ "$MODE" = "interactive" ]; then
    read -p "Apply Terraform plan? (yes/no): " confirm
    if [ "$confirm" != "yes" ]; then
        echo "❌ Terraform apply cancelled"
        exit 0
    fi
fi

echo "🔹 terraform apply"
terraform apply -auto-approve tfplan

echo ""
echo "✅ Infrastructure created successfully!"
echo ""

#COMMENTING OUT
# terraform output


ARGOCD_NS="argocd"
ARGOCD_SECRET="argocd-initial-admin-secret"
OUT_FILE="../argocd-password.txt"

echo "🔐 Fetching ArgoCD admin password..."

# Wait for ArgoCD secret to exist (max 60s)
for i in {1..30}; do
    if kubectl get secret "$ARGOCD_SECRET" -n "$ARGOCD_NS" >/dev/null 2>&1; then
        break
    fi
    echo "⏳ Waiting for ArgoCD secret..."
    sleep 2
done

# Final check
if ! kubectl get secret "$ARGOCD_SECRET" -n "$ARGOCD_NS" >/dev/null 2>&1; then
    echo "❌ ArgoCD secret not found. Password not saved."
    exit 1
fi

# Extract + decode password
kubectl -n "$ARGOCD_NS" get secret "$ARGOCD_SECRET" \
  -o jsonpath='{.data.password}' | base64 -d > "$OUT_FILE"

chmod 600 "$OUT_FILE"

echo "✅ ArgoCD admin password saved to argocd-password.txt"
echo "🔑 Login:"
echo "   Username: admin"
echo "   Password: $(cat "$OUT_FILE")"


cd ..

echo "🏁 Terraform completed"
echo ""
echo "📋 Next steps:"
echo "  - Check cluster status: kubectl get all -A"
echo "  - Access ArgoCD: kubectl get svc -n argocd"
echo "  - View logs: kubectl logs -n argocd -l app.kubernetes.io/name=argocd-server"