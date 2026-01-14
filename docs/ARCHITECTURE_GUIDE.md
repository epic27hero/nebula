# Complete Architecture Guide - Project Nebula

**A comprehensive explanation of the entire infrastructure, all components, how they work together, what each piece does, and why this architecture is powerful.**

---

## Table of Contents

1. [Project Overview](#project-overview)
2. [Complete Architecture Diagram](#complete-architecture-diagram)
3. [Core Concepts Explained](#core-concepts-explained)
4. [Component Deep Dive](#component-deep-dive)
5. [End-to-End Data Flow](#end-to-end-data-flow)
6. [Benefits of This Architecture](#benefits-of-this-architecture)
7. [Key Technologies Explained](#key-technologies-explained)
8. [Operational Workflows](#operational-workflows)
9. [Commands Reference](#commands-reference)
10. [Troubleshooting & Monitoring](#troubleshooting--monitoring)

---

## Project Overview

**Project Nebula** is a complete, production-ready Kubernetes infrastructure with:

- ✅ **Containerized FastAPI Application** - REST API with automatic scaling
- ✅ **Kubernetes Cluster** - Container orchestration and management
- ✅ **Continuous Delivery** - ArgoCD GitOps deployment
- ✅ **Load Balancing** - MetalLB for external access
- ✅ **Monitoring** - Prometheus + Grafana for observability
- ✅ **Automation** - GitLab CI/CD for automatic deployment
- ✅ **Infrastructure as Code** - Terraform for reproducible setup

**Problem it solves:**
- Deploy applications reliably at scale
- Automatic failover and healing
- Visibility into application performance
- Automated deployment pipeline
- Multi-replica load balancing
- Easy horizontal scaling

---

## Complete Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                         EXTERNAL NETWORK (192.168.0.0/24)                  │
│                                                                             │
│  Developer Machine    GitLab Server    Docker Registry    K3s Server       │
│  (anywhere)          (192.168.0.190)  (192.168.0.113)   (192.168.0.113)    │
└─────────────────────────────────────────────────────────────────────────────┘
              │                 │              │                    │
              │ git push        │              │                    │
              └─────────────────┼──────────────┼────────────────────┤
                                │              │                    │
                    ┌───────────▼──────────────▼────────┐           │
                    │    GitLab CI/CD Pipeline          │           │
                    │                                   │           │
                    │  [BUILD] → [PUSH] → [DEPLOY]     │           │
                    │  • Docker image builds            │           │
                    │  • Pushes to registry             │           │
                    │  • Connects via SSH to deploy     │           │
                    └───────────┬──────────────┬────────┘           │
                                │              │                    │
                                │ image push   │ SSH deploy         │
                                ▼              ▼                    ▼
    ┌──────────────────────────────────────────────────────────────────────┐
    │              K3s KUBERNETES CLUSTER (Single Node)                    │
    │              (192.168.0.113)                                         │
    │                                                                      │
    │  ┌────────────────────────────────────────────────────────────────┐ │
    │  │                   PRODUCTION NAMESPACE                        │ │
    │  │                                                               │ │
    │  │  FastAPI Deployment                                          │ │
    │  │  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐       │ │
    │  │  │  Pod 1       │  │  Pod 2       │  │  Pod 3       │       │ │
    │  │  │ fastapi:     │  │ fastapi:     │  │ fastapi:     │       │ │
    │  │  │ 10.42.0.114  │  │ 10.42.0.115  │  │ 10.42.0.116  │       │ │
    │  │  │              │  │              │  │              │       │ │
    │  │  │ Port: 8000   │  │ Port: 8000   │  │ Port: 8000   │       │ │
    │  │  └──────────────┘  └──────────────┘  └──────────────┘       │ │
    │  │         │                 │                 │               │ │
    │  │         └─────────────────┼─────────────────┘               │ │
    │  │                           │                                 │ │
    │  │                    FastAPI Service                          │ │
    │  │                  Type: LoadBalancer                         │ │
    │  │                Internal: 10.43.57.102:80                    │ │
    │  │                                                              │ │
    │  │  HTTPRoute (Gateway API Routing)                           │ │
    │  │  └─ /docs, /health, /metrics routed to Pod                │ │
    │  │                                                              │ │
    │  └────────────────────────────────────────────────────────────────┘ │
    │                                                                      │
    │  ┌────────────────────────────────────────────────────────────────┐ │
    │  │                   ARGOCD NAMESPACE                            │ │
    │  │                                                               │ │
    │  │  ArgoCD Server                                               │ │
    │  │  ┌──────────────────────────────────────────────┐            │ │
    │  │  │ Watches: git@192.168.0.190/project_nebula   │            │ │
    │  │  │ Branch: master                              │            │ │
    │  │  │ Action: Auto-syncs changes to cluster      │            │ │
    │  │  │ Status: 3 apps Synced & Healthy            │            │ │
    │  │  │ UI Access: 192.168.0.202                    │            │ │
    │  │  └──────────────────────────────────────────────┘            │ │
    │  │                                                               │ │
    │  │  Applications:                                               │ │
    │  │  • fastapi-prod (production app)                            │ │
    │  │  • prometheus (metrics collection)                          │ │
    │  │  • grafana (metrics visualization)                          │ │
    │  │                                                               │ │
    │  └────────────────────────────────────────────────────────────────┘ │
    │                                                                      │
    │  ┌────────────────────────────────────────────────────────────────┐ │
    │  │                   MONITORING NAMESPACE                        │ │
    │  │                                                               │ │
    │  │  Prometheus Server                                           │ │
    │  │  ┌──────────────────────────────────────────────┐            │ │
    │  │  │ Scrapes metrics every 15 seconds             │            │ │
    │  │  │ From: Kubelet, kube-proxy, Services          │            │ │
    │  │  │ Stores: Time-series data (30 day retention) │            │ │
    │  │  │ Port: 9090                                   │            │ │
    │  │  │ Access: 192.168.0.204:9090                  │            │ │
    │  │  └──────────────────────────────────────────────┘            │ │
    │  │                                                               │ │
    │  │  Grafana Server                                              │ │
    │  │  ┌──────────────────────────────────────────────┐            │ │
    │  │  │ Data Source: Prometheus                      │            │ │
    │  │  │ Dashboards: CPU, Memory, Pod Status          │            │ │
    │  │  │ Port: 3000                                   │            │ │
    │  │  │ Username: admin / Password: grafana          │            │ │
    │  │  │ Access: 192.168.0.205:3000                   │            │ │
    │  │  └──────────────────────────────────────────────┘            │ │
    │  │                                                               │ │
    │  └────────────────────────────────────────────────────────────────┘ │
    │                                                                      │
    │  ┌────────────────────────────────────────────────────────────────┐ │
    │  │                   KUBE-SYSTEM NAMESPACE                       │ │
    │  │                                                               │ │
    │  │  MetalLB Controller                                          │ │
    │  │  ┌──────────────────────────────────────────────┐            │ │
    │  │  │ Assigns LoadBalancer services to IPs         │            │ │
    │  │  │ IP Pool: 192.168.0.201 - 192.168.0.250      │            │ │
    │  │  │ Pods: 2 replicas for HA                      │            │ │
    │  │  │ Protocol: Layer 2 (ARP)                      │            │ │
    │  │  └──────────────────────────────────────────────┘            │ │
    │  │                                                               │ │
    │  │  CoreDNS                                                     │ │
    │  │  ┌──────────────────────────────────────────────┐            │ │
    │  │  │ Internal DNS for pods                        │            │ │
    │  │  │ Service discovery by name                    │            │ │
    │  │  │ Example: prometheus-server.monitoring       │            │ │
    │  │  └──────────────────────────────────────────────┘            │ │
    │  │                                                               │ │
    │  │  Kubelet, Kube-proxy, Container Runtime                      │ │
    │  │                                                               │ │
    │  └────────────────────────────────────────────────────────────────┘ │
    │                                                                      │
    │  ┌────────────────────────────────────────────────────────────────┐ │
    │  │                 DATA STORAGE (etcd)                           │ │
    │  │                                                               │ │
    │  │  etcd Key-Value Store                                        │ │
    │  │  • All cluster state stored here                             │ │
    │  │  • Pod definitions, configs, secrets                        │ │
    │  │  • Highly available and fault-tolerant                       │ │
    │  │  • Backup location: ~/k3s-etcd-backup                       │ │
    │  │                                                               │ │
    │  └────────────────────────────────────────────────────────────────┘ │
    │                                                                      │
    └──────────────────────────────────────────────────────────────────────┘
              │                           │
              │ MetalLB IP               │ MetalLB IP
              │ Assignment               │ Assignment
              ▼                           ▼
    ┌──────────────────────────┐   ┌──────────────────────────┐
    │   External IPs           │   │   Service Endpoints      │
    │                          │   │                          │
    │ 192.168.0.202 → ArgoCD   │   │ Routing happens inside   │
    │ 192.168.0.203 → FastAPI  │   │ the LoadBalancer service │
    │ 192.168.0.204 → Prometheus│   │ to pod network (10.42.*) │
    │ 192.168.0.205 → Grafana  │   │                          │
    │ 192.168.0.206 → Gateway  │   │ Requests are translated  │
    │                          │   │ from external IP to      │
    └──────────────────────────┘   │ internal pod IP via      │
                                    │ kube-proxy rules         │
                                    │                          │
                                    └──────────────────────────┘
```

---

## Core Concepts Explained

### 1. **Pods** (The smallest deployable unit)

**What is a Pod?**
- Wrapper around one or more containers
- Shares networking namespace (same IP address)
- Containers in same pod share storage volumes
- Usually contains 1 container (rarely more)

**How it works:**
```
Pod: fastapi-app-78d65658cb-9zzwk
├── Container: fastapi
│   ├── Image: 192.168.0.113:5000/fastapi-demo:latest
│   ├── Port: 8000
│   └── CPU: 250m, RAM: 512Mi
└── Network:
    ├── IP: 10.42.0.114 (internal K8s network)
    ├── Hostname: fastapi-app-78d65658cb-9zzwk
    └── Shared storage if needed
```

**Pod lifecycle:**
- Created when deployment scales up
- Running while application is healthy
- Deleted when deployment scales down or updated

---

### 2. **Kubernetes Services** (Networking & Discovery)

Services provide stable network identity and load balancing for pods.

**Types of Services:**

| Type | Use Case | Access | IP Type |
|------|----------|--------|---------|
| ClusterIP | Internal communication | Only within cluster | Internal (10.x.x.x) |
| LoadBalancer | External access | External network | External IP + Port |
| NodePort | External access (alt) | Node IP + high port | Fixed port 30000-32767 |
| ExternalName | DNS alias | DNS only | None |

**How Service load balancing works:**

```
Request → 192.168.0.203:80 (External IP)
    ↓
LoadBalancer Service
    ↓
kube-proxy (on node) adds iptables rules
    ↓
Selects one pod randomly from matching labels
    ↓
Pod IP: 10.42.0.114:8000 (or .115, or .116)
    ↓
Response sent back through same path
```

**Service Selector:**
```yaml
apiVersion: v1
kind: Service
metadata:
  name: fastapi-app-lb
spec:
  type: LoadBalancer
  selector:
    app: fastapi-app  # Pods with this label
  ports:
  - port: 80
    targetPort: 8000
```

---

### 3. **Deployments** (Managing Pod Replicas)

Deployments manage the creation and updating of pods.

**What a Deployment does:**
- Specifies desired number of replicas
- Creates ReplicaSets to manage pods
- Rolls out updates with zero downtime
- Auto-restarts failed pods
- Scales up/down on demand

**Deployment lifecycle:**

```
Define Deployment (3 replicas)
    ↓
Creates ReplicaSet (manages 3 pods)
    ↓
ReplicaSet creates 3 Pods
    ↓
Each Pod pulls image and starts container
    ↓
Pods become Ready and Running
    ↓
Service routes traffic to pods
    ↓
Update image version
    ↓
New pods created with new image
    ↓
Old pods gracefully terminated
    ↓
Zero downtime achieved!
```

---

### 4. **Namespaces** (Logical Isolation)

Namespaces partition cluster resources for multi-tenancy.

**Built-in Namespaces:**
- `default` - Default namespace for user resources
- `kube-system` - K8s system components
- `kube-public` - Public resources
- `kube-node-lease` - Kubelet lease objects

**Project Nebula Namespaces:**
- `production` - FastAPI application
- `monitoring` - Prometheus and Grafana
- `argocd` - ArgoCD deployment tool
- `envoy-gateway-system` - Gateway API controller

**Benefits:**
- Isolation of resources
- Separate RBAC policies per namespace
- Resource quotas per namespace
- Easy cleanup (delete namespace = delete all resources)

---

### 5. **Labels & Selectors** (Organizing Resources)

Labels are key-value pairs that identify Kubernetes objects.

**Examples in Project Nebula:**

```yaml
# Pod labels
metadata:
  labels:
    app: fastapi-app          # Application name
    version: v1               # Version
    instance: production      # Environment

# Service selector (finds pods with these labels)
spec:
  selector:
    app: fastapi-app          # Selects all pods with this label
    instance: production
```

**Use Cases:**
- Service discovery (find pods by label)
- Resource filtering (`kubectl get pods -l app=fastapi`)
- Multi-version deployments
- A/B testing (route to specific version)
- Environment isolation (prod vs staging)

---

## Component Deep Dive

### **1. FastAPI Application**

**Purpose:** REST API providing business logic

**Structure:**
```
src/main.py
├── @app.get("/")
│   └── Returns: hostname, IP, environment
├── @app.get("/health")
│   └── Health check for liveness/readiness probes
└── @app.get("/metrics")
    └── Prometheus metrics for monitoring
```

**Deployment Model:**
- 3 replicas for high availability
- LoadBalancer service for external access
- Auto-restart on failure
- Rolling updates for deployments

**Access:**
- External: `http://192.168.0.203` (LoadBalancer IP)
- Internal (from other pods): `http://fastapi-app.production.svc.cluster.local`
- Swagger UI: `http://192.168.0.203/docs`

---

### **2. Kubernetes (K3s)**

**What is Kubernetes?**
- Container orchestration platform
- Automates deployment, scaling, management of containerized apps
- Declarative (you describe desired state, K8s makes it happen)
- Self-healing (automatically restarts failed pods)

**What is K3s?**
- Lightweight Kubernetes distribution
- Single binary (easier to install than full K8s)
- 40MB download vs 1GB for full K8s
- Perfect for single-node or edge deployments
- Includes: kubelet, kube-proxy, kube-controller-manager, kube-apiserver, etcd

**K3s Components:**

| Component | Function |
|-----------|----------|
| kubelet | Node agent, manages pod lifecycle |
| kube-proxy | Network proxy, routes traffic |
| kube-apiserver | REST API for cluster management |
| kube-controller-manager | Runs controllers (deployment, replica, service) |
| etcd | Distributed key-value store (cluster database) |
| containerd | Container runtime (runs Docker images) |

**How K3s Manages Applications:**

```
1. User applies YAML manifest
   kubectl apply -f deployment.yaml

2. YAML sent to kube-apiserver

3. Controllers watch for changes
   deployment-controller notices new deployment

4. Deployment controller creates ReplicaSet
   ReplicaSet controller notices target replicas

5. ReplicaSet controller creates Pods
   scheduler assigns pod to node

6. kubelet on node pulls image and starts container
   containerd manages the actual container

7. Pod becomes Running

8. Service routes traffic to pod via kube-proxy
   kube-proxy adds iptables rules

9. App is live!
```

---

### **3. ArgoCD (Continuous Delivery)**

**What is ArgoCD?**
- GitOps continuous delivery tool
- Watches Git repository for changes
- Automatically syncs Kubernetes cluster to match Git
- Declarative deployment (YAML files are source of truth)

**How ArgoCD works:**

```
Git Repository (192.168.0.190)
    ↑
    │ (ArgoCD watches every 3 minutes)
    │ SSHclone with SSH key
    │
ArgoCD Controller Pod
    │
    ├─ Read YAML manifests from Git
    │
    ├─ Compare with current cluster state
    │
    ├─ If different, apply changes
    │  (Auto-sync enabled)
    │
    └─ Update application status in UI
```

**ArgoCD Applications in Project Nebula:**

```yaml
# 1. fastapi-prod
Application:
  Source: git repo, path: manifests/
  Destination: production namespace
  Status: Synced & Healthy

# 2. prometheus
Application:
  Source: Helm chart (from Helm repo)
  Destination: monitoring namespace
  Status: Synced & Healthy

# 3. grafana
Application:
  Source: Helm chart (from Helm repo)
  Destination: monitoring namespace
  Status: Synced & Healthy
```

**Benefits:**
- Git is single source of truth
- Easy rollback (revert Git commit)
- Audit trail (see all changes in Git history)
- Declarative (you say what you want, ArgoCD makes it happen)
- Self-healing (if someone manually changes something, ArgoCD reverts it)

---

### **4. MetalLB (Load Balancer)**

**What is MetalLB?**
- Load balancer for bare metal Kubernetes
- Assigns external IPs to LoadBalancer services
- Uses Layer 2 (ARP) for IP advertisement
- Replaces cloud provider load balancers (like AWS ELB)

**How MetalLB works:**

```
LoadBalancer Service created
    ↓
MetalLB controller watches for new services
    ↓
Checks IP pool: 192.168.0.201-192.168.0.250
    ↓
Assigns next available IP to service
    Example: 192.168.0.203 → fastapi-app-lb
    ↓
MetalLB speaker pods announce ARP
    "I have 192.168.0.203!"
    ↓
Network sees IP is reachable on network
    ↓
External traffic routes to service
    ↓
kube-proxy routes to pod
```

**IP Pool Configuration:**

```yaml
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
      - 192.168.0.201-192.168.0.250  # 50 available IPs
```

**Assigned IPs in Project Nebula:**

| Service | External IP | Access |
|---------|------------|--------|
| argocd-server-lb | 192.168.0.202 | http://192.168.0.202 |
| fastapi-app-lb | 192.168.0.203 | http://192.168.0.203 |
| prometheus-lb | 192.168.0.204 | http://192.168.0.204:9090 |
| grafana-lb | 192.168.0.205 | http://192.168.0.205:3000 |
| gateway | 192.168.0.206 | Gateway API controller |

---

### **5. Prometheus (Metrics Collection)**

**What is Prometheus?**
- Time-series database for metrics
- Scrapes metrics from applications every 15 seconds
- Stores data with 30-day retention
- Used for monitoring and alerting

**Metrics Collected:**

```
From kubelet:
  • container_cpu_usage_seconds_total (CPU usage)
  • container_memory_usage_bytes (Memory usage)
  • container_network_receive_bytes (Network I/O)

From kube-proxy:
  • Total requests
  • Latencies
  • Error rates

From applications:
  • Custom app metrics
  • Request counts, latencies
  • Business metrics
```

**Scrape Interval:** 15 seconds (adjustable)

**Retention:** 30 days of data (adjustable)

**Data Storage:**
- Time-series format (timestamp, value)
- Efficient compression
- Query language: PromQL

**PromQL Examples:**

```promql
# CPU usage of pod
container_cpu_usage_seconds_total{pod_name="fastapi-app-78d65658cb-9zzwk"}

# Memory usage of all FastAPI pods
container_memory_usage_bytes{pod_name=~"fastapi-app-.*"}

# Request rate (requests per second)
rate(http_requests_total[5m])

# 95th percentile latency
histogram_quantile(0.95, http_request_duration_seconds)
```

**Access:**
- URL: http://192.168.0.204:9090
- Query interface available
- Used by Grafana for visualization

---

### **6. Grafana (Metrics Visualization)**

**What is Grafana?**
- Dashboarding and visualization platform
- Connects to Prometheus as data source
- Creates beautiful dashboards
- Sends alerts based on metric thresholds

**Dashboard Components:**

```
Dashboard: "Kubernetes Cluster Health"
├── Panel: CPU Usage
│   ├── Query: container_cpu_usage_seconds_total
│   ├── Visualization: Graph
│   └── Update every: 10 seconds
├── Panel: Memory Usage
│   ├── Query: container_memory_usage_bytes
│   └── Visualization: Gauge
└── Panel: Pod Status
    ├── Query: up (whether pod is up)
    ├── Visualization: Table
    └── Colors: Green (up), Red (down)
```

**Access:**
- URL: http://192.168.0.205:3000
- Username: admin
- Password: grafana

**Pre-built Dashboards:**
- Kubernetes Cluster Overview
- Pod Resources
- Node Exporter Detailed View
- Prometheus Stats

---

### **7. Docker & Container Registry**

**What is Docker?**
- Containerization platform
- Packages application + dependencies into image
- Image is immutable (same everywhere)
- Container is running instance of image

**Image to Container Flow:**

```
Dockerfile
    ↓
docker build → Image (blueprint)
    ↓
docker push → Registry (192.168.0.113:5000)
    ↓
Registry stores image layers
    ↓
kubelet pulls image for pod creation
    ↓
containerd unpacks image layers
    ↓
Creates Container (running instance)
    ↓
Application starts
```

**Project Nebula Dockerfile:**

```dockerfile
# Multi-stage build for smaller image
FROM python:3.11-slim as builder

WORKDIR /app

# Install dependencies in builder stage
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Runtime stage (smaller)
FROM python:3.11-slim

WORKDIR /app

# Copy only installed packages from builder
COPY --from=builder /usr/local/lib/python3.11/site-packages \
  /usr/local/lib/python3.11/site-packages

# Copy app source
COPY src/ .

# Non-root user for security
RUN useradd -m appuser
USER appuser

# Health check
HEALTHCHECK --interval=30s --timeout=3s CMD curl -f http://localhost:8000/health || exit 1

EXPOSE 8000
CMD ["uvicorn", "main:app", "--host", "0.0.0.0"]
```

**Image Versioning:**
- `fastapi-demo:latest` - Always latest version
- `fastapi-demo:abc123def` - Specific commit SHA for version tracking
- Both pushed to registry on every build

---

### **8. Terraform (Infrastructure as Code)**

**What is Terraform?**
- Infrastructure as Code tool
- Declarative way to manage infrastructure
- Creates resources by code (reproducible)
- Tracks state in terraform.tfstate file

**Project Nebula Terraform:**

```
terraform/
├── main.tf                 # Main configuration
├── providers.tf           # Provider (Kubernetes provider)
├── variables.tf           # Input variables
├── versions.tf            # Terraform/provider versions
├── outputs.tf             # Output values
└── modules/
    ├── argocd/            # ArgoCD configuration
    ├── metallb/           # MetalLB configuration
    └── gateway-api/       # Gateway API configuration
```

**What Terraform manages:**
- ArgoCD installation and configuration
- MetalLB IP pool assignment
- Gateway API resources
- Application manifests

**Terraform Commands:**

```bash
terraform init      # Initialize terraform (download providers)
terraform plan      # Show what will be created
terraform apply     # Create resources
terraform destroy   # Delete resources
terraform state     # View current state
```

**State Management:**
- File: `terraform.tfstate`
- Tracks all created resources
- Backup: `terraform.tfstate.backup`
- Security: Should be encrypted and backed up

---

## End-to-End Data Flow

### **Scenario: Developer pushes FastAPI code change**

```
1. DEVELOPMENT
   Developer writes new feature in src/main.py
   │
   ├─ git add src/main.py
   ├─ git commit -m "Add new endpoint"
   └─ git push origin master
      │
      
2. GIT SERVER (192.168.0.190)
   Repository receives push
   │
   └─ Triggers webhook to GitLab CI/CD
      │
      
3. GITLAB CI/CD PIPELINE
   
   a) BUILD STAGE
      ├─ Docker image builds on CI runner
      ├─ Uses Dockerfile from repo
      ├─ Tags with :latest and :abc123 (commit SHA)
      └─ Build time: ~2-3 minutes
      │
   
   b) PUSH STAGE
      ├─ Docker image pushed to 192.168.0.113:5000
      ├─ Layer caching speeds up future builds
      └─ Push time: ~1 minute
      │
   
   c) DEPLOY STAGE
      ├─ SSH to 192.168.0.113 (K3s server)
      ├─ Trigger kubectl rollout (optional, ArgoCD does this)
      ├─ Show infrastructure status (6-part report)
      └─ Deploy time: ~1 minute
      │
      
4. DOCKER REGISTRY (192.168.0.113:5000)
   New image available: fastapi-demo:abc123
   │
   │
   
5. K3S CLUSTER DETECTS CHANGE (via ArgoCD)
   
   a) ArgoCD watches Git repository (master branch)
   b) ArgoCD polls every 3 minutes OR triggered by webhook
   c) ArgoCD sees new image tag in Git
   d) Compares with current cluster state
   e) Detects mismatch (old image vs new image)
   f) ArgoCD auto-syncs if enabled
   │
   
6. DEPLOYMENT UPDATE
   
   a) Deployment controller creates new ReplicaSet
      ├─ New RS: 0 pods running
      └─ Old RS: 3 pods still running
   
   b) First pod update (Rolling update)
      ├─ New pod created with new image
      ├─ Kubelet pulls image from registry
      ├─ Pod starts and becomes Ready
      ├─ Service routes traffic to it
      └─ Old pod still handles traffic
   
   c) Second pod update
      ├─ New pod created
      ├─ Old pod gracefully terminated
      └─ Requests drained before termination
   
   d) Third pod update
      ├─ New pod created
      ├─ Old pod terminated
      └─ All traffic now on new pods
   
   e) Old ReplicaSet deleted
      └─ No downtime! Service available entire time

   Update time: ~2-3 minutes
   
   
7. VERIFICATION
   
   a) Pod status
      kubectl get pods -n production
      fastapi-app-abc123xyz-1 (new image)
      fastapi-app-abc123xyz-2 (new image)
      fastapi-app-abc123xyz-3 (new image)
   
   b) Service still routing
      curl http://192.168.0.203
      Returns: "FastAPI running on Kubernetes..."
      
   c) Load balancing works
      Multiple requests go to different pods
      Request 1 → Pod 1
      Request 2 → Pod 2
      Request 3 → Pod 3
      Request 4 → Pod 1 (cycle)
   
   d) Metrics collected
      Prometheus scrapes new pod metrics
      Grafana updates dashboards
      
   e) ArgoCD status
      Application: Synced & Healthy
      Last sync: 2 minutes ago


8. MONITORING & OBSERVABILITY
   
   Prometheus scraping new pods:
   ├─ container_cpu_usage (CPU metric)
   ├─ container_memory_usage (Memory metric)
   ├─ http_requests_total (Request count)
   └─ http_request_duration_seconds (Latency)
   
   Grafana dashboards update:
   ├─ Shows new pod metrics
   ├─ Graphs update every 10 seconds
   └─ No downtime visible in graphs


TOTAL TIME: ~5-7 minutes from push to production
DOWNTIME: 0 seconds (zero downtime deployment!)
DEVELOPER ACTION: 1 git push (everything else is automated!)
```

---

## Benefits of This Architecture

### **1. High Availability**
- **3 replicas:** If 1 pod fails, 2 still serve traffic
- **Auto-restart:** Failed pods restarted automatically
- **Multi-zone ready:** Can extend to multiple nodes
- **No single point of failure**

### **2. Automatic Scaling**
- **Resource efficient:** Only use needed resources
- **Horizontal scaling:** Add more pods on demand
- **Vertical scaling:** Increase resources per pod
- **Future-proof:** Can add HPA (Horizontal Pod Autoscaler)

### **3. Zero-Downtime Deployments**
- **Rolling updates:** Gradually replace old pods
- **Graceful shutdown:** Old pods finish requests
- **Health checks:** Only traffic to healthy pods
- **Automatic rollback:** Can revert to previous version

### **4. Self-Healing**
- **Restarts failed pods:** Automatic recovery
- **Replaces dead nodes:** Multi-node support
- **Reconciliation:** K8s always maintains desired state
- **No manual intervention:** System heals itself

### **5. Observability**
- **Metrics collection:** Every component monitored
- **Beautiful dashboards:** Grafana visualizations
- **Alerting:** Can set thresholds and get notified
- **Historical data:** 30 days of metrics retained

### **6. GitOps Deployment**
- **Single source of truth:** Git repository
- **Declarative:** You describe desired state
- **Automatic sync:** Changes deployed automatically
- **Easy rollback:** Revert Git commit to rollback
- **Audit trail:** See all changes in Git history

### **7. Infrastructure as Code**
- **Reproducible:** Deploy same infrastructure anywhere
- **Version controlled:** Track infrastructure changes
- **Scriptable:** Automated deployments
- **Documentation:** Code IS documentation
- **Testing:** Can test infrastructure changes

### **8. Cost Efficient**
- **Resource isolation:** Multi-tenant on single server
- **Container efficiency:** Lightweight containers
- **No cloud dependencies:** Works on any Linux
- **Minimal infrastructure:** Single server can run everything

### **9. Security**
- **Isolation:** Namespaces isolate resources
- **RBAC:** Control who can do what
- **Network policies:** Control pod-to-pod traffic
- **Image scanning:** Scan containers for vulnerabilities
- **Non-root containers:** Apps don't run as root

### **10. Scalability**
- **Horizontal:** Add more pods
- **Vertical:** Add more replicas
- **Multi-node:** Scale across many servers
- **Federation:** Multiple clusters
- **Ready for growth**

---

## Key Technologies Explained

### **Kubernetes Concepts**

| Concept | Analogy | Purpose |
|---------|---------|---------|
| Cluster | Data Center | Collection of nodes running K8s |
| Node | Server | Individual machine running kubelet |
| Pod | Container | Smallest deployable unit (usually 1 container) |
| Deployment | Blueprint | Defines how to deploy pods |
| ReplicaSet | Manager | Maintains desired number of pod replicas |
| Service | Load Balancer | Provides stable network access |
| Namespace | Partition | Logical grouping of resources |
| Label | Tag | Metadata for organizing resources |
| Selector | Filter | Selects resources by labels |

### **Observability Stack**

```
Application → Metrics → Prometheus → Grafana → Dashboard
                ↓
            Time-series DB
                ↓
          30-day retention
                ↓
        PromQL queries available
                ↓
          Beautiful graphs
```

### **Deployment Pipeline**

```
Git → GitLab CI/CD → Docker Build → Registry → K3s → Pods
                         ↓
                    Docker Image
                         ↓
                    Version Control
                         ↓
                    Reproducible
```

### **State Management**

```
Desired State (YAML) → etcd (cluster database) → Current State
     ↓
Controllers continuously reconcile
If Current != Desired → Take action
```

---

## Operational Workflows

### **Workflow 1: Deploy New Feature**

```bash
# 1. Make changes
nano src/main.py

# 2. Commit and push
git add src/main.py
git commit -m "Add new endpoint /api/users"
git push origin master

# 3. Watch pipeline
# Go to GitLab → Pipelines → View running

# 4. Monitor deployment
kubectl get pods -n production --watch

# 5. Test new feature
curl http://192.168.0.203/api/users

# Done! Zero downtime deployment!
```

### **Workflow 2: Scale Application**

```bash
# Current: 3 replicas
# Desired: 5 replicas

# Option 1: Edit deployment YAML
nano manifests/deployment.yaml
# Change: replicas: 3 → replicas: 5
git add manifests/deployment.yaml
git commit -m "Scale to 5 replicas"
git push origin master
# ArgoCD syncs automatically

# Option 2: Direct kubectl (for testing)
kubectl scale deployment fastapi-app -n production --replicas=5

# Verify
kubectl get pods -n production
# See 5 pods now
```

### **Workflow 3: Update Resource Limits**

```bash
# Check current resource usage
kubectl top pods -n production

# Update resources in deployment
nano manifests/deployment.yaml

# Change requests/limits:
resources:
  requests:
    memory: "512Mi"      # Guaranteed
    cpu: "250m"
  limits:
    memory: "1Gi"        # Maximum
    cpu: "500m"

git add manifests/deployment.yaml
git commit -m "Increase resource limits"
git push origin master

# ArgoCD automatically applies
```

### **Workflow 4: View Logs**

```bash
# Latest logs from specific pod
kubectl logs <pod-name> -n production

# Stream logs
kubectl logs <pod-name> -n production -f

# Logs from all pods with label
kubectl logs -n production -l app=fastapi -f

# Specific number of lines
kubectl logs <pod-name> -n production --tail=100

# Previous pod (if crashed and restarted)
kubectl logs <pod-name> -n production --previous
```

### **Workflow 5: Execute Command in Pod**

```bash
# Execute command
kubectl exec -it <pod-name> -n production -- /bin/bash

# Example: Check Python version
kubectl exec -it <pod-name> -n production -- python --version

# Example: Check installed packages
kubectl exec -it <pod-name> -n production -- pip list

# Example: Check files
kubectl exec -it <pod-name> -n production -- ls -la /app
```

### **Workflow 6: Troubleshoot Pod Issue**

```bash
# 1. Check pod status
kubectl describe pod <pod-name> -n production

# Look for: Events, Status, Conditions

# 2. Check logs
kubectl logs <pod-name> -n production

# 3. Check resource usage
kubectl top pod <pod-name> -n production

# 4. Get pod YAML
kubectl get pod <pod-name> -n production -o yaml

# 5. Common issues:
# - Pending: Insufficient resources, image pull errors
# - CrashLoopBackOff: Application crashing
# - ImagePullBackOff: Can't pull Docker image
# - Terminating: Stuck pod termination

# Fix: Delete pod (replicaset will recreate)
kubectl delete pod <pod-name> -n production
```

---

## Commands Reference

### **Cluster Information**

```bash
# Cluster info
kubectl cluster-info

# Nodes
kubectl get nodes
kubectl get nodes -o wide
kubectl describe node <node-name>

# Resources
kubectl top nodes
kubectl top pods -n production

# Events
kubectl get events -n production
kubectl get events --all-namespaces
```

### **Pods & Deployments**

```bash
# List pods
kubectl get pods -n production
kubectl get pods --all-namespaces
kubectl get pods -n production -o wide

# Pod details
kubectl describe pod <pod-name> -n production
kubectl get pod <pod-name> -n production -o yaml

# Deployment
kubectl get deployments -n production
kubectl describe deployment fastapi-app -n production
kubectl scale deployment fastapi-app --replicas=5 -n production

# Logs
kubectl logs <pod-name> -n production
kubectl logs <pod-name> -n production -f
kubectl logs -n production -l app=fastapi -f

# Execute in pod
kubectl exec -it <pod-name> -n production -- /bin/bash

# Delete pod
kubectl delete pod <pod-name> -n production

# Watch pods
kubectl get pods -n production --watch
watch kubectl get pods -n production
```

### **Services & Networking**

```bash
# List services
kubectl get services -n production
kubectl get svc --all-namespaces
kubectl get svc -o wide

# Service details
kubectl describe service fastapi-app-lb -n production

# Port forward (access service locally)
kubectl port-forward svc/fastapi-app-lb 8000:80 -n production
# Then: curl localhost:8000

# Endpoints
kubectl get endpoints -n production
kubectl describe endpoints fastapi-app-lb -n production

# Network policy
kubectl get networkpolicies -n production
```

### **Configuration & Storage**

```bash
# ConfigMaps
kubectl get configmap -n production
kubectl describe configmap <name> -n production
kubectl get configmap <name> -o yaml -n production

# Secrets
kubectl get secret -n production
kubectl get secret <name> -o yaml -n production

# Persistent Volumes
kubectl get pv
kubectl get pvc -n production

# Storage Classes
kubectl get storageclass
```

### **Debugging**

```bash
# Status
kubectl rollout status deployment/fastapi-app -n production

# History
kubectl rollout history deployment/fastapi-app -n production

# Rollback
kubectl rollout undo deployment/fastapi-app -n production

# Restart pods
kubectl rollout restart deployment/fastapi-app -n production

# Get all resources
kubectl get all -n production
kubectl get all --all-namespaces

# Dry-run (test without applying)
kubectl apply -f deployment.yaml --dry-run=client
```

### **Namespaces**

```bash
# List
kubectl get namespaces

# Create
kubectl create namespace <name>

# Delete
kubectl delete namespace <name>

# Switch default namespace
kubectl config set-context --current --namespace=production
```

### **ArgoCD**

```bash
# List applications
argocd app list

# Application status
argocd app get fastapi-prod

# Sync application
argocd app sync fastapi-prod

# Watch sync
argocd app wait fastapi-prod

# Delete application
argocd app delete fastapi-prod

# Login to ArgoCD
argocd login <argocd-server>

# Get password
kubectl -n argocd get secret argocd-initial-admin-secret \
  -o jsonpath="{.data.password}" | base64 -d
```

### **Prometheus & Grafana**

```bash
# Port forward to Prometheus
kubectl port-forward -n monitoring svc/prometheus-lb 9090:9090

# Port forward to Grafana
kubectl port-forward -n monitoring svc/grafana-lb 3000:3000

# Get Grafana password
kubectl get secret grafana -n monitoring \
  -o jsonpath="{.data.admin-password}" | base64 -d
```

### **Useful Aliases**

```bash
# Add to ~/.bashrc

alias k='kubectl'
alias kgp='kubectl get pods'
alias kdp='kubectl describe pod'
alias kgs='kubectl get svc'
alias kgd='kubectl get deployment'
alias kl='kubectl logs'
alias kex='kubectl exec -it'
alias kgpa='kubectl get pods --all-namespaces'
alias kdesc='kubectl describe'

# Usage:
k get pods -n production
kl pod-name -n production -f
kex pod-name -n production -- /bin/bash
```

---

## Troubleshooting & Monitoring

### **Common Issues**

**Issue: Pod stuck in "Pending"**
```bash
# Check why
kubectl describe pod <pod-name> -n production

# Common causes:
1. Insufficient CPU/Memory: Add more resources to node or request less
2. Image pull error: Check image name and registry access
3. PVC not bound: Check storage class and PVC status
4. Node selector mismatch: Check node labels

# Solution:
kubectl top nodes  # Check available resources
```

**Issue: Pod in "CrashLoopBackOff"**
```bash
# Check logs
kubectl logs <pod-name> -n production --previous

# Check events
kubectl describe pod <pod-name> -n production

# Common causes:
1. Application crash: Fix code
2. Missing environment variable: Add to deployment
3. Configuration error: Check YAML syntax

# Solution:
kubectl logs <pod-name> -n production -f
# Watch for error messages
```

**Issue: Service has no endpoints**
```bash
# Check service selector
kubectl get service <service-name> -n production -o yaml

# Check pod labels
kubectl get pods -n production -o yaml | grep -A5 labels:

# Labels must match selector
# Fix: Update pod labels or service selector

kubectl patch service <service-name> -n production \
  -p '{"spec":{"selector":{"app":"fastapi-app"}}}'
```

**Issue: MetalLB IP not assigned**
```bash
# Check MetalLB controller
kubectl get pods -n metallb-system

# Check ConfigMap
kubectl get configmap -n metallb-system config -o yaml

# Check service
kubectl describe service <service-name> -n production

# View logs
kubectl logs -n metallb-system -l app=metallb
```

**Issue: ArgoCD application out of sync**
```bash
# Check status
argocd app get fastapi-prod

# Check Git connection
argocd repo list

# Sync manually
argocd app sync fastapi-prod

# Force sync
argocd app sync fastapi-prod --force

# Check events
kubectl get events -n argocd -l app.kubernetes.io/name=argocd
```

---

## Summary

Project Nebula demonstrates:

✅ **Container Orchestration** - K3s manages containerized apps at scale
✅ **Declarative Infrastructure** - YAML defines desired state
✅ **GitOps** - Git is source of truth, ArgoCD keeps cluster in sync
✅ **Zero-Downtime Deployment** - Rolling updates maintain availability
✅ **Observability** - Prometheus + Grafana provide visibility
✅ **Automation** - GitLab CI/CD automates entire deployment pipeline
✅ **Self-Healing** - Kubernetes automatically fixes failures
✅ **Scalability** - Add replicas for horizontal scaling
✅ **Security** - Isolation, RBAC, non-root containers
✅ **Production-Ready** - Can be deployed at scale

This architecture is used by thousands of companies running production workloads!

