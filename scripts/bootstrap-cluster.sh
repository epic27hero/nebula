set -e

echo "╔════════════════════════════════════════════════════════════╗"
echo "║   🚀 Kubernetes Cluster Bootstrap - Complete Setup        ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""

# Check if running as root
if [ "$EUID" -eq 0 ]; then 
   echo "⚠️  Please do not run as root"
   exit 1
fi

# Check if kubectl is configured
if ! kubectl cluster-info &> /dev/null; then
    echo "❌ kubectl is not configured or cluster is not reachable"
    echo "Please configure kubectl first"
    exit 1
fi

echo "✅ Kubernetes cluster is reachable"
echo ""

# Step 1: Install dependencies
echo "════════════════════════════════════════════════════════════"
echo "📦 Step 1/5: Installing Core Dependencies"
echo "════════════════════════════════════════════════════════════"
./scripts/install-dependencies.sh
echo ""

# Step 2: Install Gateway API
echo "════════════════════════════════════════════════════════════"
echo "🌐 Step 2/5: Installing Gateway API"
echo "════════════════════════════════════════════════════════════"
./scripts/install-gateway-api.sh
echo ""

# Step 3: Setup Terraform Infrastructure
echo "════════════════════════════════════════════════════════════"
echo "🏗️  Step 3/5: Setting up Infrastructure with Terraform"
echo "════════════════════════════════════════════════════════════"

cd terraform

# Create terraform.tfvars if it doesn't exist
if [ ! -f terraform.tfvars ]; then
    echo "📝 Creating terraform.tfvars from example..."
    cp terraform.tfvars.example terraform.tfvars
    echo ""
    echo "⚠️  IMPORTANT: Edit terraform/terraform.tfvars with your values"
    echo "   - Update metallb_ip_range to match your network"
    echo "   - Verify kubeconfig_path"
    echo ""
    read -p "Press Enter after editing terraform.tfvars to continue..."
fi

# Initialize and apply Terraform
terraform init
terraform validate
echo ""
echo "🔍 Terraform plan preview:"
terraform plan -out=tfplan

echo ""
read -p "Apply Terraform plan? (yes/no): " confirm
if [ "$confirm" != "yes" ]; then
    echo "❌ Terraform apply cancelled"
    exit 1
fi

terraform apply tfplan

# Get outputs
echo ""
echo "📊 Terraform Outputs:"
terraform output

# Save ArgoCD password
ARGOCD_PASSWORD=$(terraform output -raw argocd_admin_password 2>/dev/null || echo "")
if [ -n "$ARGOCD_PASSWORD" ]; then
    echo "$ARGOCD_PASSWORD" > ../argocd-password.txt
    echo "ArgoCD password saved to: argocd-password.txt"
fi

cd ..
echo ""

# Step 4: Configure ArgoCD
echo "════════════════════════════════════════════════════════════"
echo "🔧 Step 4/5: Configuring ArgoCD"
echo "════════════════════════════════════════════════════════════"

echo "⏳ Waiting for ArgoCD to be ready (this may take 2-3 minutes)..."
kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=argocd-server -n argocd --timeout=300s

# Get ArgoCD server IP
ARGOCD_SERVER=$(kubectl get svc argocd-server -n argocd -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || echo "")

if [ -z "$ARGOCD_SERVER" ]; then
    echo "⚠️  LoadBalancer IP not assigned yet, trying NodePort..."
    ARGOCD_SERVER="localhost"
    kubectl port-forward svc/argocd-server -n argocd 8080:443 &
    PORT_FORWARD_PID=$!
    sleep 5
    ARGOCD_SERVER="localhost:8080"
fi

echo "ArgoCD Server: ${ARGOCD_SERVER}"

# Get ArgoCD password if not already obtained
if [ -z "$ARGOCD_PASSWORD" ]; then
    ARGOCD_PASSWORD=$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d)
    echo "$ARGOCD_PASSWORD" > argocd-password.txt
fi

# Login to ArgoCD
echo "🔐 Logging into ArgoCD..."
argocd login ${ARGOCD_SERVER} --username admin --password ${ARGOCD_PASSWORD} --insecure

# Update repository URL in ArgoCD applications
echo "📝 Updating repository URL in ArgoCD applications..."
REPO_URL=$(git config --get remote.origin.url 2>/dev/null || echo "https://gitlab.com/your-org/fastapi-k8s-platform.git")
echo "Repository URL: ${REPO_URL}"

# Update all application manifests with actual repo URL
find argocd/applications -name "*.yaml" -exec sed -i "s|https://gitlab.com/your-org/fastapi-k8s-platform.git|${REPO_URL}|g" {} \;

# Create ArgoCD project and applications
echo "🚀 Deploying ArgoCD applications..."
kubectl apply -f argocd/projects/fastapi-project.yaml
kubectl apply -f argocd/app-of-apps.yaml

echo ""

# Step 5: Final verification
echo "════════════════════════════════════════════════════════════"
echo "✅ Step 5/5: Final Verification"
echo "════════════════════════════════════════════════════════════"

echo ""
echo "Checking namespaces..."
kubectl get namespaces | grep -E "production|staging|development|argocd|gateway-system|metallb-system"

echo ""
echo "Checking ArgoCD applications..."
argocd app list --insecure

echo ""
echo "╔════════════════════════════════════════════════════════════╗"
echo "║             ✅ Cluster Bootstrap Complete!                 ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""
echo "📋 Access Information:"
echo "════════════════════════════════════════════════════════════"
echo "🌐 ArgoCD UI:"
echo "   URL: http://${ARGOCD_SERVER}"
echo "   Username: admin"
echo "   Password: ${ARGOCD_PASSWORD}"
echo ""
echo "📁 Credentials saved to: argocd-password.txt"
echo ""
echo "🔧 Useful Commands:"
echo "════════════════════════════════════════════════════════════"
echo "  # View all applications"
echo "  argocd app list --insecure"
echo ""
echo "  # Check pods in production"
echo "  kubectl get pods -n production"
echo ""
echo "  # View gateway status"
echo "  kubectl get gateway -A"
echo ""
echo "  # Access ArgoCD CLI"
echo "  argocd login ${ARGOCD_SERVER} --username admin --password ${ARGOCD_PASSWORD} --insecure"
echo ""
echo "🎉 Your Kubernetes platform is ready!"
echo ""

# Kill port-forward if it was started
if [ -n "$PORT_FORWARD_PID" ]; then
    kill $PORT_FORWARD_PID 2>/dev/null || true
fi
```

### scripts/setup-terraform.sh
```bash
#!/bin/bash
set -e

echo "🏗️  Setting up Terraform infrastructure..."

cd terraform

# Initialize Terraform
terraform init

# Validate configuration
terraform validate

# Plan infrastructure
terraform plan -out=tfplan

# Apply (with confirmation)
read -p "Apply Terraform plan? (yes/no): " confirm
if [ "$confirm" = "yes" ]; then
    terraform apply tfplan
    
    # Display outputs
    echo ""
    echo "✅ Infrastructure created successfully!"
    echo ""
    terraform output
    
    # Save ArgoCD password
    terraform output -raw argocd_admin_password > ../argocd-password.txt
    echo "ArgoCD password saved to argocd-password.txt"
else
    echo "Terraform apply cancelled"
fi

cd ..