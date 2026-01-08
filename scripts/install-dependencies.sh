set -e

echo "🚀 Installing Core Dependencies..."

# Install Terraform
install_terraform() {
    echo "📦 Installing Terraform..."
    wget -O- https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
    echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
    sudo apt update && sudo apt install terraform -y
    terraform --version
}

# Install Helm
install_helm() {
    echo "📦 Installing Helm..."
    curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
    helm version
}

# Install kubectl (if not present)
install_kubectl() {
    if ! command -v kubectl &> /dev/null; then
        echo "📦 Installing kubectl..."
        curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
        sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
        kubectl version --client
    else
        echo "✅ kubectl already installed"
    fi
}

# Install ArgoCD CLI
install_argocd_cli() {
    echo "📦 Installing ArgoCD CLI..."
    curl -sSL -o /usr/local/bin/argocd https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-amd64
    sudo chmod +x /usr/local/bin/argocd
    argocd version --client
}

# Install Gateway API CRDs
install_gateway_api() {
    echo "📦 Installing Gateway API CRDs..."
    kubectl apply -f https://github.com/kubernetes-sigs/gateway-api/releases/download/v1.0.0/standard-install.yaml
    echo "✅ Gateway API CRDs installed"
}

# Execute installations
install_terraform
install_helm
install_kubectl
install_argocd_cli
install_gateway_api

echo "✅ All dependencies installed successfully!"