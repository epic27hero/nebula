# Project Nebula - FastAPI Kubernetes Platform

A production-ready, fully-automated Kubernetes platform for deploying containerized FastAPI applications with complete observability and GitOps management.

**Tech Stack:**
* GitLab CI/CD (automated build & deployment pipeline)
* Terraform (Infrastructure as Code)
* Helm (application packaging)
* ArgoCD (GitOps continuous delivery)
* K3s (lightweight Kubernetes)
* Gateway API (modern traffic management)
* MetalLB (external load balancing for bare-metal)
* Prometheus & Grafana (monitoring & observability)
* Kubernetes native networking & service mesh

---

## 🏗️ Architecture Overview

```
┌─────────────────────────────────────────────────────────────────────────┐
│                     EXTERNAL NETWORK (192.168.0.0/24)                   │
│  Developer → GitLab Server (192.168.0.190) → K3s Node (192.168.0.113)  │
└─────────────────────────────────────────────────────────────────────────┘
                                      │
        ┌─────────────────────────────┼─────────────────────────────┐
        │                             │                             │
        ▼                             ▼                             ▼
    ┌────────────┐            ┌─────────────────┐        ┌──────────────┐
    │ git push   │            │ CI/CD Pipeline  │        │ Docker Build │
    │ master     │            │ • Build image   │        │ & Push Image │
    └────────────┘            │ • Push registry │        └──────────────┘
                              │ • Deploy via SSH│               │
                              └─────────────────┘               │
                                      │                         │
                                      └─────────────────────────┘
                                              │
                                              ▼
        ┌──────────────────────────────────────────────────────────────┐
        │        KUBERNETES CLUSTER (K3s Single Node)                 │
        │        192.168.0.113:6443                                   │
        │                                                              │
        │  ┌────────────────────────────────────────────────────────┐ │
        │  │ ArgoCD (GitOps Controller)                            │ │
        │  │ • Watches: git@192.168.0.190:project_nebula.git      │ │
        │  │ • Access: http://192.168.0.202                        │ │
        │  │ • Syncs: manifests → cluster automatically            │ │
        │  └────────────────────────────────────────────────────────┘ │
        │              │                                              │
        │              └─────────────────────┐                       │
        │                                    │                       │
        │  ┌────────────────────────────────▼──────────────────────┐ │
        │  │ PRODUCTION NAMESPACE                                 │ │
        │  │                                                      │ │
        │  │  FastAPI Deployment (3 Replicas)                   │ │
        │  │  Pods: 10.42.0.114, 10.42.0.115, 10.42.0.116      │ │
        │  │  ↓                                                  │ │
        │  │  ClusterIP Service: 10.43.57.102                   │ │
        │  │  ↓                                                  │ │
        │  │  LoadBalancer Service: 192.168.0.203:80            │ │
        │  │                                                      │ │
        │  └──────────────────────────────────────────────────────┘ │
        │                                                              │
        │  ┌────────────────────────────────────────────────────────┐ │
        │  │ MONITORING NAMESPACE                                 │ │
        │  │                                                      │ │
        │  │  Prometheus: 192.168.0.204:9090                    │ │
        │  │  Grafana: 192.168.0.205:3000                       │ │
        │  │  (Collecting metrics from all pods)                 │ │
        │  │                                                      │ │
        │  └──────────────────────────────────────────────────────┘ │
        │                                                              │
        │  ┌────────────────────────────────────────────────────────┐ │
        │  │ METALLB LOAD BALANCER                               │ │
        │  │ • IP Pool: 192.168.0.201-250                        │ │
        │  │ • Mode: Layer 2 (ARP)                               │ │
        │  │ • Assigns external IPs automatically                │ │
        │  │                                                      │ │
        │  └──────────────────────────────────────────────────────┘ │
        │                                                              │
        └──────────────────────────────────────────────────────────────┘
                                      │
        ┌─────────────────────────────┼─────────────────────────────┐
        │                             │                             │
        ▼                             ▼                             ▼
    External Access            Monitoring Stack          Git-based Sync
    • FastAPI API              • Prometheus DB           • Automatic
    • Health checks            • Grafana Dashboards        updates
    • Swagger Docs             • Real-time metrics       • Self-healing
```

---

## 📂 Repository Structure

```
project_nebula/
├── src/
│   ├── main.py                          # FastAPI application with /metrics
│   └── requirements.txt                 # Python dependencies
│
├── Dockerfile                           # Container image build
├── .gitlab-ci.yml                       # GitLab CI/CD pipeline
│
├── terraform/                           # Infrastructure as Code
│   ├── main.tf
│   ├── variables.tf
│   ├── outputs.tf
│   ├── providers.tf
│   ├── versions.tf
│   ├── terraform.tfstate
│   └── modules/
│       ├── metallb/                     # MetalLB load balancer
│       ├── argocd/                      # ArgoCD deployment
│       └── gateway-api/                 # Gateway API controller
│
├── helm/
│   └── fastapi-app/
│       ├── Chart.yaml
│       ├── values.yaml
│       └── templates/
│           └── deployment.yaml
│
├── argocd/                              # GitOps configuration
│   ├── projects/
│   │   └── fastapi-project.yaml
│   ├── applications/
│   │   ├── fastapi-app-production.yaml
│   │   ├── prometheus.yaml
│   │   └── grafana.yaml
│   └── app-of-apps.yaml
│
├── manifests/                           # Kubernetes manifests
│   ├── deployment.yaml                  # 3-replica FastAPI deployment
│   ├── service.yaml                     # ClusterIP + LoadBalancer services
│   ├── fastapi-service.yaml
│   ├── httproute.yaml                   # Gateway API routing
│   ├── monitoring-loadbalancer.yaml
│   └── kustomization.yaml
│
├── monitoring/                          # Monitoring stack values
│   ├── prometheus/
│   │   └── values.yaml
│   └── grafana/
│       └── values.yaml
│
├── scripts/                             # Bootstrap and utility scripts
│   ├── install-dependencies.sh          # Install Terraform, Helm, etc.
│   ├── setup-terraform.sh               # Initialize infrastructure
│   ├── bootstrap-cluster.sh
│   ├── install-argocd.sh
│   ├── install-gateway-api.sh
│   ├── install-metallb.sh
│   ├── check-cluster.sh                 # Cluster health status
│   ├── check-all-status.sh              # Complete system status
│   ├── quick-status.sh                  # Quick 2-3 second status
│   ├── health-metrics.sh                # Detailed health metrics
│   ├── run-status-check.sh              # Interactive menu
│   └── README.md
│
│
│
├── argocd-password.txt                  # ArgoCD admin password
├── grafana-password.txt                 # Grafana admin password
└── README.md                            # This file
```

---

## ⚙️ Prerequisites

Your environment must have:

* **Kubernetes Cluster**: K3s with sufficient permissions (we use K3s 1.x)
* **Docker**: Docker daemon running on K3s node
* **kubectl**: Configured with kubeconfig pointing to K3s cluster
* **GitLab**: Repository access with SSH key configured
* **Private Docker Registry**: Either GitLab registry or standalone (port 5000)
* **Linux/MacOS**: Bash shell for scripts
* **Git**: For repository management

**Minimum Hardware:**
* CPU: 4 cores
* RAM: 8GB
* Storage: 50GB

---

## 🎯 Quick Start

### Access Live Services (Already Deployed)

```bash
# FastAPI Application
curl http://192.168.0.203          # API endpoint
curl http://192.168.0.203/docs     # Swagger documentation
curl http://192.168.0.203/health   # Health check
curl http://192.168.0.203/metrics  # Prometheus metrics

# Monitoring
curl http://192.168.0.204:9090     # Prometheus
curl http://192.168.0.205:3000     # Grafana (admin/grafana)

# Management
curl http://192.168.0.202          # ArgoCD UI (see argocd-password.txt)
```

### Check System Status

```bash
# Quick status (2-3 seconds)
./scripts/quick-status.sh

# Complete status (10-15 seconds)
./scripts/check-all-status.sh

# Health metrics with details
./scripts/health-metrics.sh

# Interactive status menu
./scripts/run-status-check.sh
```

### View Application Pods

```bash
# All production pods
kubectl get pods -n production -o wide

# All services with IPs
kubectl get svc -A

# ArgoCD application status
kubectl get applications -n argocd

# Service endpoints
kubectl get endpoints -n production
```

---

---

## 🚀 Deployment Pipeline (GitLab CI/CD → ArgoCD)

### How It Works

1. **Developer pushes code** to `master` branch
2. **GitLab CI/CD triggers**:
   - Builds Docker image
   - Tags: `192.168.0.113:5000/fastapi-demo:latest`
   - Pushes to private registry (192.168.0.113:5000)
   - SSH deploys via kubectl (updates manifests)
3. **ArgoCD detects changes** (every 3 minutes):
   - Watches git repository (git@192.168.0.190:/root/project_nebula.git)
   - Compares Git state vs Cluster state
   - Auto-syncs if differences found
4. **Kubernetes orchestrates**:
   - Pulls new image from registry
   - Performs rolling update (1 extra pod max)
   - Maintains 3 replicas available
5. **MetalLB routes traffic**:
   - Assigns external IP: 192.168.0.203
   - Load balances across 3 pods
   - Session affinity: ClientIP (3 hours)

### CI/CD Pipeline Stages

| Stage | Action | Trigger |
|-------|--------|---------|
| **BUILD** | Build Docker image from Dockerfile | git push to any branch |
| **PUSH** | Push image to 192.168.0.113:5000 | BUILD succeeds |
| **DEPLOY** | SSH to K3s, run kubectl apply | PUSH succeeds |

### ArgoCD Sync Policy

* **Sync Type**: Automatic
* **Sync Interval**: 3 minutes
* **Prune**: Enabled (deletes removed resources)
* **Self-heal**: Enabled (reconciles drift)
* **Retry**: 5 times, exponential backoff

---

## 📊 Monitoring & Observability Stack

### Prometheus Server (192.168.0.204:9090)

**Purpose**: Time-series metrics collection and storage

**Scrape Targets** (every 15 seconds):
* Kubelet metrics (node CPU, memory, disk): 192.168.0.113:10250
* kube-proxy metrics (network): 10.42.0.X:10249
* FastAPI metrics endpoint: /metrics
* Kubernetes API server: https://10.43.0.1:443/metrics

**Data Storage**:
* Retention: 30 days
* Storage: 1M+ time-series
* Memory: ~2GB

**Metrics Collected**:
* Node: CPU, memory, disk, network usage
* Pod: CPU, memory, network per container
* Service: HTTP requests, latency, errors
* Custom: Application-specific metrics

### Grafana Dashboard (192.168.0.205:3000)

**Purpose**: Metrics visualization and alerting

**Credentials**: admin / grafana

**Pre-built Dashboards**:
1. **Kubernetes Cluster Monitoring**
   - Node CPU, Memory, Disk
   - Pod resource utilization
   - Network I/O rates

2. **FastAPI Application Metrics**
   - Request rate (RPS)
   - Response time (latency)
   - Error rates by endpoint
   - CPU & memory per pod

3. **Pod & Container Health**
   - Pod restart counts
   - Container OOM events
   - Pod network throughput

### Data Flow

```
FastAPI Pods (/metrics)
    ↓
Prometheus (scrapes every 15s)
    ↓ (stores time-series)
Prometheus TSDB
    ↓ (queries PromQL)
Grafana Dashboard
    ↓
User views real-time metrics
```

### Access Monitoring

```bash
# Prometheus queries
curl http://192.168.0.204:9090/api/v1/query?query=up

# Grafana dashboards
curl http://192.168.0.205:3000

# Check Prometheus scrape targets
kubectl logs -n monitoring prometheus-0 | grep "scrape_configs"
```

---

## 🌐 Traffic Flow & Load Balancing

### External Access Path

```
User Request (192.168.0.203:80)
    ↓ (MetalLB ARP resolution)
MetalLB Layer 2 → MAC address of node
    ↓ (node ingress interface)
K3s Node Network Stack (192.168.0.113)
    ↓ (iptables rules - LoadBalancer service)
FastAPI LoadBalancer Service (192.168.0.203)
    ↓ (selects endpoints)
3 Pod endpoints (10.42.0.114, 10.42.0.115, 10.42.0.116)
    ↓ (round-robin or session affinity)
FastAPI Pod (port 8000)
    ↓ (response)
User receives response
```

### Service Architecture

**FastAPI LoadBalancer Service** (External IP: 192.168.0.203)
* Type: LoadBalancer (assigned by MetalLB)
* Port: 80 (external)
* Target Port: 8000 (container)
* Endpoints: 3 pods
* Session Affinity: ClientIP (3 hours)
* Traffic Policy: Cluster-wide distribution

**FastAPI ClusterIP Service** (Internal IP: 10.43.57.102)
* Type: ClusterIP (internal only)
* DNS: `fastapi-service.production.svc.cluster.local`
* Used by: Internal services, Prometheus scraping
* Isolates internal traffic from external

### MetalLB Configuration

* **Mode**: Layer 2 (ARP-based, no BGP)
* **IP Pool**: 192.168.0.201-250
* **Available IPs**: 50 total
* **Used IPs**:
  - 192.168.0.202: ArgoCD
  - 192.168.0.203: FastAPI
  - 192.168.0.204: Prometheus
  - 192.168.0.205: Grafana
  - 192.168.0.206: Envoy Gateway (optional)

### Gateway API (Experimental)

**Status**: Deployed (RBAC permission pending)

* Alternative routing layer (not currently used)
* Envoy Gateway controller at 192.168.0.206
* HTTPRoute resources defined but inactive
* Primary access: Use MetalLB LoadBalancer IPs

**When RBAC is configured**, can provide:
* Advanced routing rules
* HTTP/2 support
* Sophisticated traffic management
* TLS termination

---

## 🔍 Verification & Health Checks

### System Status Commands

```bash
# Quick 2-3 second status
./scripts/quick-status.sh

# Detailed 10-15 second status
./scripts/check-all-status.sh

# Health metrics with pod details
./scripts/health-metrics.sh

# Interactive menu for status checks
./scripts/run-status-check.sh
```

### Kubernetes Verification

```bash
# Check all pods are running
kubectl get pods -A

# Check all services and their IPs
kubectl get svc -A

# View ArgoCD applications
kubectl get applications -n argocd -o wide

# Check pod endpoints
kubectl get endpoints -n production

# View pod logs
kubectl logs -n production <pod-name>

# Describe a pod for detailed info
kubectl describe pod -n production <pod-name>

# Check resource usage
kubectl top nodes
kubectl top pods -n production
```

### Service Connectivity Tests

```bash
# Test FastAPI from outside cluster
curl http://192.168.0.203/health
curl http://192.168.0.203/docs
curl http://192.168.0.203/metrics

# Test Prometheus
curl http://192.168.0.204:9090/api/v1/query?query=up

# Test Grafana
curl -H "Authorization: Bearer <token>" http://192.168.0.205:3000/api/datasources

# Test ArgoCD API
curl http://192.168.0.202/api/version
```

### Internal Cluster DNS Resolution

```bash
# Test DNS from a pod
kubectl exec -it <pod-name> -n production -- nslookup fastapi-service.production.svc.cluster.local
kubectl exec -it <pod-name> -n production -- nslookup prometheus.monitoring.svc.cluster.local

# Expected: resolves to ClusterIP (10.43.x.x)
```

---

## 🧹 Cleanup & Troubleshooting

### Cleanup Resources

```bash
# Destroy all Terraform infrastructure
cd terraform
terraform destroy -auto-approve

# OR manually delete
kubectl delete namespace production monitoring argocd

# Check for remaining resources
kubectl get all -A
```

### Common Issues & Solutions

**Problem**: Pods not starting / CrashLoopBackOff
```bash
# Check pod logs
kubectl logs -n production <pod-name> --previous

# Check pod events
kubectl describe pod -n production <pod-name>

# Check resource constraints
kubectl top pods -n production
```

**Problem**: Service external IP pending
```bash
# Check MetalLB controller
kubectl get pods -n metallb-system

# Check MetalLB IP pools
kubectl get ipaddresspools -n metallb-system

# Check service endpoints
kubectl get endpoints -n production
```

**Problem**: ArgoCD stuck "OutOfSync"
```bash
# Force sync
argocd app sync <app-name>

# Or via kubectl
kubectl patch applications -n argocd <app-name> -p '{"spec":{"syncPolicy":{"syncOptions":["Force=true"]}}}'

# Check ArgoCD logs
kubectl logs -n argocd argocd-server-0
```

**Problem**: Prometheus not scraping
```bash
# Check Prometheus targets
curl http://192.168.0.204:9090/api/v1/targets

# Check Prometheus config
kubectl describe configmap prometheus-server-config -n monitoring
```

### View Logs

```bash
# FastAPI pod logs
kubectl logs -n production <pod-name>

# Follow logs in real-time
kubectl logs -n production <pod-name> -f

# ArgoCD server logs
kubectl logs -n argocd argocd-server-0

# Prometheus logs
kubectl logs -n monitoring prometheus-0

# Grafana logs
kubectl logs -n monitoring grafana-0
```

---

## ✅ What This Platform Provides

✔ **Fully Automated Deployment**: Git push → Build → Deploy (no manual kubectl)
✔ **High Availability**: 3 pod replicas with automatic failover
✔ **Zero-Downtime Updates**: Rolling updates with health checks
✔ **Production Monitoring**: Real-time metrics and dashboards
✔ **GitOps Management**: All infrastructure defined in Git
✔ **Load Balancing**: Automatic external IP assignment
✔ **Self-Healing**: Automatic pod restart on failure
✔ **Scalability**: Easily increase replicas or add nodes
✔ **Security**: Network isolation, RBAC, secret management
✔ **Observability**: Prometheus + Grafana for complete visibility

---


## 🔐 Security Considerations

* **Network Isolation**: Services only accessible via MetalLB IPs
* **RBAC**: Kubernetes role-based access control enabled
* **Secrets**: Passwords stored in Kubernetes secrets
* **Pod Security**: Resource limits and requests configured
* **Service Accounts**: Minimal permissions per component

**Recommended Enhancements**:
* Enable NetworkPolicies for pod-to-pod restrictions
* Configure TLS certificates (self-signed or Let's Encrypt)
* Set up Ingress authentication (OAuth, OIDC)
* Enable audit logging
* Use a service mesh (Istio/Linkerd) for advanced networking

---

## 📝 Environment Details

**Current Setup**:
* Kubernetes: K3s (single node)
* Cluster IP: 192.168.0.113
* Network: 192.168.0.0/24
* Git Server: 192.168.0.190
* Docker Registry: 192.168.0.113:5000

**Resource Allocation**:
* FastAPI Pod Memory: 256Mi (minimum)
* Prometheus Storage: 30 days retention
* Grafana: Stateless (uses Prometheus as datasource)

---

## 🆘 Support & Troubleshooting

**Quick Status Check** (recommended first step):
```bash
./scripts/quick-status.sh
```

This shows:
* All service IPs
* Pod replicas status
* Replica readiness
* External access points

**For Detailed Help**:
1. Run `./scripts/health-metrics.sh` for comprehensive diagnostics
2. Check [INFRASTRUCTURE_ACCESS.md](docs/INFRASTRUCTURE_ACCESS.md) for access points
3. Review [DEPLOYMENT_GUIDE.md](docs/DEPLOYMENT_GUIDE.md) for common tasks
4. Check pod logs: `kubectl logs -n production <pod-name>`

---

## 📊 Project Nebula - Status

**All Services Running ✅**

| Service | Status | Access Point | Port |
|---------|--------|--------------|------|
| FastAPI | ✅ Running | 192.168.0.203 | 80 |
| Prometheus | ✅ Running | 192.168.0.204 | 9090 |
| Grafana | ✅ Running | 192.168.0.205 | 3000 |
| ArgoCD | ✅ Running | 192.168.0.202 | 80 |
| K3s Cluster | ✅ Running | 192.168.0.113 | 6443 |
| MetalLB | ✅ Running | 192.168.0.201-250 | - |

---

## 👤 Author

**Souvik Das**
Technical Manager – FactEntry

---

## 🏁 Project Overview

**Project Nebula** - A comprehensive, production-ready Kubernetes platform for FastAPI applications.

Built with best practices for:
* Infrastructure as Code
* GitOps workflows
* Cloud-native development
* Operational excellence

Once bootstrapped:
* Developers only push code
* Platform runs itself
* Operations become predictable
