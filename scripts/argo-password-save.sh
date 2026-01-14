# Save ArgoCD password
# ARGOCD_PASSWORD=$(terraform output -raw argocd_admin_password 2>/dev/null || echo "")
# if [ -n "$ARGOCD_PASSWORD" ]; then
#     echo "$ARGOCD_PASSWORD" > ../argocd-password.txt
#     echo "ArgoCD password saved to: argocd-password.txt"
# fi

ARGOCD_NS="argocd"
ARGOCD_SECRET="argocd-initial-admin-secret"
OUT_FILE="./argocd-password.txt"

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