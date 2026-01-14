# Complete End-to-End Setup Guide - Project Nebula

## Table of Contents
1. [Prerequisites](#prerequisites)
2. [Architecture Overview](#architecture-overview)
3. [Step 1: Infrastructure Setup](#step-1-infrastructure-setup)
4. [Step 2: Kubernetes Cluster Setup](#step-2-kubernetes-cluster-setup)
5. [Step 3: Network & Load Balancing](#step-3-network--load-balancing)
6. [Step 4: Container Registry](#step-4-container-registry)
7. [Step 5: Application Deployment](#step-5-application-deployment)
8. [Step 6: ArgoCD Installation](#step-6-argocd-installation)
9. [Step 7: Monitoring Stack](#step-7-monitoring-stack)
10. [Step 8: Gateway API & Routing](#step-8-gateway-api--routing)
11. [Step 9: Verify Everything](#step-9-verify-everything)
12. [Troubleshooting](#troubleshooting)

---

## Prerequisites

### Hardware Requirements
- **Server/VM**: Linux OS (Ubuntu 20.04+ or similar)
- **CPU**: 2+ cores
- **RAM**: 4GB minimum (8GB recommended)
- **Storage**: 30GB+ free space
- **Network**: Static IP address, internet connectivity

### Software Requirements
- Git
- Docker (optional, for local builds)
- kubectl
- Terraform 1.14+
- SSH client
- curl, wget

### Pre-installation Setup

```bash
# Update system packages
sudo apt-get update && sudo apt-get upgrade -y

# Install curl and wget
sudo apt-get install -y curl wget git

# Install Docker (optional, for local development)
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo usermod -aG docker $USER

# Create project directory
mkdir -p ~/project_nebula
cd ~/project_nebula
```

---

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────┐
│                  Project Nebula Architecture                 │
├─────────────────────────────────────────────────────────────┤
│                                                               │
│  ┌──────────────────────────────────────────────────────┐   │
│  │         K3s Kubernetes Cluster (192.168.0.113)       │   │
│  │                                                       │   │
│  │  ┌────────────────┐  ┌────────────────┐             │   │
│  │  │   FastAPI App  │  │   Monitoring   │             │   │
│  │  │   (3 replicas) │  │   (Prometheus, │             │   │
│  │  │                │  │    Grafana)    │             │   │
│  │  └────────────────┘  └────────────────┘             │   │
│  │                                                       │   │
│  │  ┌────────────────┐  ┌────────────────┐             │   │
│  │  │    ArgoCD      │  │    Gateway     │             │   │
│  │  │    (CD/Sync)   │  │    API/Envoy   │             │   │
│  │  └────────────────┘  └────────────────┘             │   │
│  │                                                       │   │
│  │  ┌────────────────┐  ┌────────────────┐             │   │
│  │  │    MetalLB     │  │  etcd/storage  │             │   │
│  │  │  (Load Balancer)│  │                │             │   │
│  │  └────────────────┘  └────────────────┘             │   │
│  │                                                       │   │
│  └──────────────────────────────────────────────────────┘   │
│           │                                                   │
│           ↓                                                   │
│  ┌──────────────────────────────────────────────────────┐   │
│  │          MetalLB External IPs (192.168.0.2xx)       │   │
│  │                                                       │   │
│  │  • 192.168.0.202 → ArgoCD UI                        │   │
│  │  • 192.168.0.203 → FastAPI LoadBalancer             │   │
│  │  • 192.168.0.204 → Prometheus                       │   │
│  │  • 192.168.0.205 → Grafana                          │   │
│  │  • 192.168.0.206 → Gateway API                      │   │
│  │                                                       │   │
│  └──────────────────────────────────────────────────────┘   │
│           │                                                   │
│           ↓                                                   │
│  ┌──────────────────────────────────────────────────────┐   │
│  │          GitLab CI/CD Pipeline                       │   │
│  │                                                       │   │
│  │  [BUILD] → [PUSH to Registry] → [DEPLOY]           │   │
│  │                                                       │   │
│  └──────────────────────────────────────────────────────┘   │
│           │                                                   │
│           ↓                                                   │
│  ┌──────────────────────────────────────────────────────┐   │
│  │       Private Docker Registry (192.168.0.113:5000)   │   │
│  │                                                       │   │
│  │  Stores: fastapi-demo:latest, base images           │   │
│  │                                                       │   │
│  └──────────────────────────────────────────────────────┘   │
│                                                               │
│  ┌──────────────────────────────────────────────────────┐   │
│  │              Terraform IaC Management                │   │
│  │                                                       │   │
│  │  Manages: ArgoCD, MetalLB, Gateway API              │   │
│  │                                                       │   │
│  └──────────────────────────────────────────────────────┘   │
│                                                               │
└─────────────────────────────────────────────────────────────┘
```

---

## Step 1: Infrastructure Setup

### 1.1 Clone Repository

```bash
# Clone the project repository
git clone ssh://git@192.168.0.190/root/project_nebula.git /root/project_nebula
cd /root/project_nebula

# Or if using HTTPS
git clone https://192.168.0.190/root/project_nebula.git
```

### 1.2 Install Required Tools

```bash
# Install kubectl (Kubernetes command-line tool)
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl

# Verify kubectl installation
kubectl version --client

# Install Terraform
wget https://releases.hashicorp.com/terraform/1.14.3/terraform_1.14.3_linux_amd64.zip
unzip terraform_1.14.3_linux_amd64.zip
sudo mv terraform /usr/local/bin/

# Verify Terraform
terraform version

# Install Helm (package manager for Kubernetes)
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
helm version
```

### 1.3 SSH Key Setup for Git

```bash
# Generate SSH key (if not exists)
ssh-keygen -t rsa -b 4096 -f ~/.ssh/id_rsa -N ""

# Copy public key to GitLab
cat ~/.ssh/id_rsa.pub

# Add to your GitLab user settings
# GitLab → Settings → SSH Keys → Add public key
```

---

## Step 2: Kubernetes Cluster Setup

### 2.1 Install K3s (Lightweight Kubernetes)

K3s is a lightweight, production-grade Kubernetes distribution. Perfect for edge, IoT, and resource-constrained environments.

```bash
# Install K3s (installs server and agent in single node)
curl -sfL https://get.k3s.io | sh -

# Verify installation
sudo k3s kubectl get nodes

# Set up kubeconfig for regular user
mkdir -p ~/.kube
sudo cp /etc/rancher/k3s/k3s.yaml ~/.kube/config
sudo chown $USER:$USER ~/.kube/config
chmod 600 ~/.kube/config

# Verify kubectl works
kubectl get nodes
kubectl get pods --all-namespaces
```

### 2.2 Understand K3s Components

**What is K3s?**
- Lightweight Kubernetes (single binary)
- 40MB download, 100MB RAM
- Built-in etcd (key-value store for cluster state)
- Includes container runtime (containerd)
- Perfect for single-node or edge deployments

**Key Components:**
- **kubelet**: Manages pods on nodes
- **kube-proxy**: Network proxy, manages services
- **kube-controller-manager**: Manages deployments, replicas
- **kube-apiserver**: REST API for cluster management
- **etcd**: Distributed key-value store (cluster database)
- **containerd**: Container runtime (runs your containers)

### 2.3 Verify K3s Cluster

```bash
# Check cluster status
kubectl cluster-info

# View nodes
kubectl get nodes -o wide

# View system pods
kubectl get pods -n kube-system

# View all namespaces
kubectl get namespaces
```

---

## Step 3: Network & Load Balancing

### 3.1 MetalLB Installation (Load Balancer for Bare Metal)

MetalLB provides load balancing for Kubernetes on bare metal (non-cloud) infrastructure.

```bash
# Install MetalLB
kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.13.7/config/manifests/namespace.yaml
kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.13.7/config/manifests/metallb.yaml

# Wait for MetalLB to be ready
kubectl wait --for=condition=ready pod -l app=metallb -n metallb-system --timeout=300s
```

### 3.2 Configure MetalLB IP Pool

```bash
# Create MetalLB ConfigMap with IP pool
cat > metallb-config.yaml <<'EOF'
apiVersion: v1
kind: ConfigMap
metadata:
  namespace: metallb-system
  name: config
data:
  config: |
    address-pools:
    - name: default
      protocol: layer2
      addresses:
      - 192.168.0.201-192.168.0.250
EOF

kubectl apply -f metallb-config.yaml
```

**What is MetalLB?**
- Load balancer for bare metal Kubernetes
- No dependency on cloud provider
- Assigns external IPs to LoadBalancer services
- IP pool: 192.168.0.201-250 (50 available IPs)
- Uses Layer 2 (ARP) for IP advertisement

### 3.3 Verify MetalLB

```bash
# Check MetalLB pods
kubectl get pods -n metallb-system

# Check ConfigMap
kubectl get configmap -n metallb-system config -o yaml
```

---

## Step 4: Container Registry

### 4.1 Docker Registry Setup

A private Docker registry stores container images for your cluster.

```bash
# Install Docker Registry (using registry:2 image)
docker run -d \
  -p 5000:5000 \
  --restart=always \
  --name registry \
  registry:2

# Or using Docker Compose
cat > docker-compose.yml <<'EOF'
version: '3'
services:
  registry:
    image: registry:2
    ports:
      - "5000:5000"
    volumes:
      - registry_data:/var/lib/registry
    restart: always

volumes:
  registry_data:
EOF

docker-compose up -d
```

### 4.2 Configure Kubernetes to Access Registry

```bash
# Create secret for K3s to pull from registry
kubectl create secret docker-registry registry-secret \
  --docker-server=192.168.0.113:5000 \
  --docker-username=unused \
  --docker-password=unused \
  -n default

# Link secret to default service account
kubectl patch serviceaccount default -p '{"imagePullSecrets": [{"name": "registry-secret"}]}'
```

**What is a Docker Registry?**
- Stores container images (like Docker Hub but private)
- Address: 192.168.0.113:5000
- Images stored in: /var/lib/registry/
- Accessible only on internal network

---

## Step 5: Application Deployment

### 5.1 Create Namespaces

Namespaces are logical groupings in Kubernetes for multi-tenancy.

```bash
# Create namespaces
kubectl create namespace production
kubectl create namespace monitoring
kubectl create namespace argocd

# Verify
kubectl get namespaces
```

### 5.2 Build & Push FastAPI Application

```bash
# Navigate to project
cd /root/project_nebula

# Build Docker image
docker build -t 192.168.0.113:5000/fastapi-demo:latest .

# Tag with commit SHA for version tracking
docker tag 192.168.0.113:5000/fastapi-demo:latest 192.168.0.113:5000/fastapi-demo:$(git rev-parse --short HEAD)

# Push to registry
docker push 192.168.0.113:5000/fastapi-demo:latest
docker push 192.168.0.113:5000/fastapi-demo:$(git rev-parse --short HEAD)

# Verify image in registry
curl http://192.168.0.113:5000/v2/_catalog
```

### 5.3 Deploy FastAPI Application

```bash
# Apply manifests in order
kubectl apply -f manifests/deployment.yaml
kubectl apply -f manifests/service.yaml
kubectl apply -f manifests/fastapi-service.yaml

# Verify deployment
kubectl get deployments -n production
kubectl get pods -n production
kubectl get services -n production

# Get LoadBalancer IP
kubectl get svc fastapi-app-lb -n production -o wide
```

---

## Step 6: ArgoCD Installation

### 6.1 What is ArgoCD?

ArgoCD is a declarative, GitOps continuous delivery tool:
- **Watches**: Git repository for configuration changes
- **Syncs**: Kubernetes cluster state with Git state
- **Autosync**: Automatically deploys when repo changes
- **Declarative**: Define desired state in YAML files
- **Multi-app**: Manages multiple applications

### 6.2 Install ArgoCD

```bash
# Create ArgoCD namespace and install
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/v2.13.2/manifests/install.yaml

# Wait for ArgoCD to be ready
kubectl wait --for=condition=ready pod -l app.kubernetes.io/part-of=argocd -n argocd --timeout=300s

# Verify installation
kubectl get pods -n argocd
```

### 6.3 Create LoadBalancer Service for ArgoCD

```bash
# Create LoadBalancer to expose ArgoCD UI
cat > argocd-loadbalancer.yaml <<'EOF'
apiVersion: v1
kind: Service
metadata:
  name: argocd-server-lb
  namespace: argocd
spec:
  type: LoadBalancer
  ports:
  - port: 80
    targetPort: 8080
    protocol: TCP
  selector:
    app.kubernetes.io/name: argocd-server
EOF

kubectl apply -f argocd-loadbalancer.yaml

# Get LoadBalancer IP
kubectl get svc argocd-server-lb -n argocd
```

### 6.4 Retrieve ArgoCD Credentials

```bash
# Get initial password (username: admin)
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d; echo

# Save password
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d > argocd-password.txt

# Access ArgoCD UI
# URL: http://192.168.0.202 (LoadBalancer IP)
# Username: admin
# Password: (from argocd-password.txt)
```

### 6.5 Add Git Repository to ArgoCD

```bash
# Create SSH secret for Git access
kubectl create secret generic argocd-repo-creds-github \
  --from-file=sshPrivateKey=$HOME/.ssh/id_rsa \
  -n argocd

# Create ArgoCD Repository
cat > argocd-repo.yaml <<'EOF'
apiVersion: v1
kind: Secret
metadata:
  name: argocd-repo-project-nebula
  namespace: argocd
  labels:
    argocd.argoproj.io/secret-type: repository
stringData:
  type: git
  url: ssh://git@192.168.0.190/root/project_nebula.git
  sshPrivateKey: |
    (paste your SSH private key here)
EOF

kubectl apply -f argocd-repo.yaml
```

### 6.6 Create ArgoCD Project

```bash
# Create Project (restricts what apps can be deployed)
cat > argocd-project.yaml <<'EOF'
apiVersion: argoproj.io/v1alpha1
kind: AppProject
metadata:
  name: nebula-project
  namespace: argocd
spec:
  destinations:
  - namespace: '*'
    server: https://kubernetes.default.svc
  sourceRepos:
  - 'ssh://git@192.168.0.190/root/project_nebula.git'
EOF

kubectl apply -f argocd-project.yaml
```

### 6.7 Create ArgoCD Applications

```bash
# FastAPI Application
cat > argocd-fastapi-app.yaml <<'EOF'
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: fastapi-prod
  namespace: argocd
spec:
  project: nebula-project
  source:
    repoURL: ssh://git@192.168.0.190/root/project_nebula.git
    targetRevision: master
    path: manifests
  destination:
    server: https://kubernetes.default.svc
    namespace: production
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
    - CreateNamespace=true
EOF

kubectl apply -f argocd-fastapi-app.yaml

# Verify
kubectl get applications -n argocd
argocd app list
```

---

## Step 7: Monitoring Stack

### 7.1 Install Prometheus

Prometheus scrapes metrics from applications and stores time-series data.

```bash
# Add Prometheus Helm repository
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update

# Create monitoring namespace
kubectl create namespace monitoring

# Create Prometheus values file
cat > prometheus-values.yaml <<'EOF'
prometheus:
  server:
    global:
      scrape_interval: 15s
      evaluation_interval: 15s
    service:
      type: ClusterIP
      port: 9090
EOF

# Install Prometheus using Helm
helm install prometheus prometheus-community/kube-prometheus-stack \
  -n monitoring \
  -f prometheus-values.yaml
```

### 7.2 Create Prometheus LoadBalancer

```bash
# Create LoadBalancer service for Prometheus
cat > prometheus-loadbalancer.yaml <<'EOF'
apiVersion: v1
kind: Service
metadata:
  name: prometheus-lb
  namespace: monitoring
spec:
  type: LoadBalancer
  ports:
  - port: 9090
    targetPort: 9090
    protocol: TCP
  selector:
    app.kubernetes.io/name: prometheus
    prometheus: kube-prometheus
EOF

kubectl apply -f prometheus-loadbalancer.yaml
```

### 7.3 Install Grafana

Grafana visualizes metrics collected by Prometheus.

```bash
# Add Grafana Helm repository
helm repo add grafana https://grafana.github.io/helm-charts
helm repo update

# Install Grafana
helm install grafana grafana/grafana \
  -n monitoring \
  --set adminPassword=grafana \
  --set persistence.enabled=false
```

### 7.4 Create Grafana LoadBalancer

```bash
# Create LoadBalancer service for Grafana
cat > grafana-loadbalancer.yaml <<'EOF'
apiVersion: v1
kind: Service
metadata:
  name: grafana-lb
  namespace: monitoring
spec:
  type: LoadBalancer
  ports:
  - port: 3000
    targetPort: 3000
    protocol: TCP
  selector:
    app.kubernetes.io/name: grafana
EOF

kubectl apply -f grafana-loadbalancer.yaml

# Get LoadBalancer IP
kubectl get svc grafana-lb -n monitoring
```

### 7.5 Configure Grafana

```bash
# Access Grafana UI
# URL: http://192.168.0.205:3000 (LoadBalancer IP)
# Username: admin
# Password: grafana

# Add Prometheus Data Source
# 1. Settings → Data Sources → Add
# 2. Type: Prometheus
# 3. URL: http://prometheus-server:80 (internal K8s DNS)
# 4. Save & Test

# Create Dashboard
# Dashboards → New → Add visualization
# Metric query: up, container_cpu_usage_seconds_total, container_memory_usage_bytes
```

**What is Monitoring?**
- **Prometheus**: Collects metrics (CPU, memory, requests, etc.)
- **Grafana**: Visualizes metrics in dashboards
- **Alerts**: Define thresholds for when to alert
- **Time-Series Data**: Metrics collected over time for trend analysis

---

## Step 8: Gateway API & Routing

### 8.1 Install Gateway API CRDs

Gateway API is next-generation ingress with advanced routing.

```bash
# Install Gateway API CRDs
kubectl apply -f https://github.com/kubernetes-sigs/gateway-api/releases/download/v1.0.0/standard-install.yaml

# Verify CRDs
kubectl get crd | grep gateway
```

### 8.2 Install Envoy Gateway

Envoy Gateway implements the Gateway API specification.

```bash
# Add Envoy Gateway Helm repository
helm repo add envoy-gateway https://envoyproxy.io/charts
helm repo update

# Install Envoy Gateway
helm install envoy-gateway envoy-gateway/gateway-helm \
  -n envoy-gateway-system \
  --create-namespace

# Wait for installation
kubectl wait --for=condition=ready pod -l control-plane=envoy-gateway \
  -n envoy-gateway-system --timeout=300s
```

### 8.3 Create Gateway

```bash
# Create Gateway resource
cat > manifests/gateway.yaml <<'EOF'
apiVersion: gateway.networking.k8s.io/v1beta1
kind: Gateway
metadata:
  name: main-gateway
  namespace: production
spec:
  gatewayClassName: envoy
  listeners:
  - name: http
    port: 80
    protocol: HTTP
EOF

kubectl apply -f manifests/gateway.yaml
```

### 8.4 Create HTTPRoute

```bash
# Create HTTPRoute for FastAPI
cat > manifests/httproute.yaml <<'EOF'
apiVersion: gateway.networking.k8s.io/v1beta1
kind: HTTPRoute
metadata:
  name: fastapi-route
  namespace: production
spec:
  parentRefs:
  - name: main-gateway
  hostnames:
  - "api.example.com"
  rules:
  - backendRefs:
    - name: fastapi-app
      port: 80
EOF

kubectl apply -f manifests/httproute.yaml
```

---

## Step 9: Verify Everything

### 9.1 Check All Services

```bash
# Verify all pods
kubectl get pods --all-namespaces

# Verify all services
kubectl get services --all-namespaces

# Check LoadBalancer IPs
kubectl get services -l type=LoadBalancer --all-namespaces
```

### 9.2 Test Connectivity

```bash
# Test FastAPI
curl http://192.168.0.203
curl http://192.168.0.203/health
curl http://192.168.0.203/metrics

# Test Prometheus
curl http://192.168.0.204:9090/metrics

# Test Grafana (UI)
curl http://192.168.0.205:3000

# Test ArgoCD (UI)
curl http://192.168.0.202
```

### 9.3 Run Status Check

```bash
# Use included status check script
cd /root/project_nebula
./scripts/quick-status.sh
./scripts/check-all-status.sh
./scripts/health-metrics.sh
```

---

## Step 10: GitLab CI/CD Setup (Optional)

### 10.1 Create GitLab Project

```bash
# Create project on GitLab server
# Settings → Create Project → project_nebula
```

### 10.2 Set CI/CD Variables

```bash
# In GitLab: Project → Settings → CI/CD Variables

SSH_PRIVATE_KEY_GITLAB_TESTING_CI = (your SSH private key)
DEPLOY_SERVER = 192.168.0.113
DEPLOY_USER = root
REGISTRY = 192.168.0.113:5000
IMAGE_NAME = fastapi-demo
ARGOCD_IP = 192.168.0.202
FASTAPI_LB_IP = 192.168.0.203
PROMETHEUS_IP = 192.168.0.204
GRAFANA_IP = 192.168.0.205
```

### 10.3 Enable CI/CD

```bash
# Pipeline auto-triggers on push to master
# .gitlab-ci.yml defines stages: BUILD, PUSH, DEPLOY
# View pipeline: Project → Pipelines
```

---

## Troubleshooting

### Issue: Pods stuck in "Pending"

```bash
# Check pod events
kubectl describe pod <pod-name> -n <namespace>

# Common causes:
# 1. Insufficient resources: kubectl top nodes
# 2. Image pull errors: kubectl logs <pod-name> -n <namespace>
# 3. PVC not bound: kubectl get pvc -n <namespace>
```

### Issue: Service has no endpoints

```bash
# Check service selector
kubectl get svc <service-name> -n <namespace> -o yaml | grep selector

# Check pod labels
kubectl get pods -n <namespace> -o wide --show-labels

# Labels should match selector
```

### Issue: MetalLB IP not assigned

```bash
# Check MetalLB ConfigMap
kubectl get configmap -n metallb-system config -o yaml

# Check MetalLB controller logs
kubectl logs -n metallb-system -l app=metallb --tail=50
```

### Issue: ArgoCD application out of sync

```bash
# Check application status
argocd app get <app-name>

# Sync manually
argocd app sync <app-name>

# Check sync errors
kubectl get application <app-name> -n argocd -o yaml
```

### Issue: Image pull from registry failing

```bash
# Check registry accessibility
curl http://192.168.0.113:5000/v2/_catalog

# Check image secret
kubectl get secrets -n production

# Recreate secret if needed
kubectl delete secret registry-secret -n production
kubectl create secret docker-registry registry-secret \
  --docker-server=192.168.0.113:5000 \
  --docker-username=unused \
  --docker-password=unused \
  -n production
```

---

## Next Steps

1. **Customize FastAPI Application**
   - Edit `src/main.py` with your business logic
   - Add new endpoints and features

2. **Create Custom Grafana Dashboards**
   - Import or create dashboards in Grafana
   - Define alert rules for monitoring

3. **Set Up Continuous Deployment**
   - Configure GitLab CI/CD for auto-deployment
   - Test deployment pipeline with changes

4. **Scale Applications**
   - Increase replicas in deployment.yaml
   - Use Horizontal Pod Autoscaler (HPA) for auto-scaling

5. **Implement Backup & Disaster Recovery**
   - Backup etcd database
   - Create Velero backup solution
   - Test recovery procedures

6. **Multi-Environment Deployment**
   - Create separate namespaces for staging/dev
   - Use ArgoCD ApplicationSets for multi-env deployment

---

## References

- [K3s Documentation](https://docs.k3s.io/)
- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [ArgoCD Documentation](https://argo-cd.readthedocs.io/)
- [MetalLB Documentation](https://metallb.universe.tf/)
- [Prometheus Documentation](https://prometheus.io/docs/)
- [Grafana Documentation](https://grafana.com/docs/grafana/)

