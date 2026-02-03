# Project Nebula - End-to-End Architecture Diagram V3 (With Deterministic Model)

> **Version**: 3.0  
> **Date**: February 3, 2026  
> **Enhancement**: Integrated deterministic deployment responsibility model  
> **Base**: Original diagrams from V1 (preserved & enhanced)  
> **Status**: Complete with implementation gaps identified

---

## 🎯 What's New in V3

✅ **Preserved**: All excellent original diagrams (V1)  
✅ **Added**: Deterministic responsibility boundaries overlay  
✅ **Added**: Implementation gap indicators on diagrams  
✅ **Added**: Metadata flow annotations  
✅ **Added**: Build argument injection visualization  

---

## 📊 Complete System Architecture (with Deterministic Overlays)

```
╔════════════════════════════════════════════════════════════════════════════════════════════════════════════════╗
║                                         EXTERNAL NETWORK LAYER                                               ║
║                                      (192.168.0.0/24 Network Segment)                                        ║
╚════════════════════════════════════════════════════════════════════════════════════════════════════════════════╝

┌─────────────────────────────────────────┐    ┌──────────────────────────────────┐    ┌─────────────────────────┐
│    Developer Workstations               │    │    GitLab Server                 │    │    Kubernetes Master    │
│    (Multiple IPs)                       │    │    192.168.0.190                 │    │    (K3s Single Node)    │
│                                         │    │                                  │    │    192.168.0.113        │
│    • Local Machine                      │    │    Services:                     │    │                         │
│    • SSH Access                         │    │    • Git repository              │    │    Services:            │
│    • Git push commits                   │    │    • CI/CD Runner                │    │    • API Server         │
│    • kubectl commands                   │    │    • Container Registry (5000)   │    │    • Kubelet            │
│                                         │    │    • SSH (22)                    │    │    • etcd database      │
└──────────────────────┬──────────────────┘    └──────────────────┬───────────────┘    └────────────┬───────────┘
                       │                                           │                                 │
         ┌─────────────┴───────────────┬───────────────────────────┴─────────────────────────────────┘
         │                             │
         │ (1) git push                │ (2) Docker Push & SSH Deploy
         ▼                             ▼
    ┌────────────────────────────────────────────────────────────────────────────────────────────────┐
    │              🧠 GitLab CI/CD PIPELINE (SOURCE OF TRUTH)                                       │
    │                                                                                                │
    │    Workflow Stages (with Deterministic Model):                                               │
    │                                                                                                │
    │    Stage 1: BUILD (CI DECIDES IMAGE IDENTITY)                                                │
    │    ├─ Trigger: git push to master branch                                                     │
    │    ├─ BUILD ARGS INJECTED (from CI environment):                                            │
    │    │  ├─ APP_VERSION=${CI_COMMIT_TAG:-${CI_COMMIT_SHORT_SHA}}   (e.g., abc1234)            │
    │    │  ├─ BUILD_TIME=$(date -u +"%Y-%m-%dT%H:%M:%SZ")           (e.g., 2026-02-03T14:30) │
    │    │  └─ IMAGE_TAG=${CI_COMMIT_SHORT_SHA}                       (e.g., abc1234)            │
    │    │                                                                                          │
    │    ├─ docker build --build-arg APP_VERSION=... \                                             │
    │    │           --build-arg BUILD_TIME=... \                                                   │
    │    │           --build-arg IMAGE_TAG=... \                                                    │
    │    │           -t fastapi-demo:${CI_COMMIT_SHORT_SHA} .                                     │
    │    │                                                                                          │
    │    └─ Result: Image with metadata BAKED IN (immutable)                                      │
    │       ✅ FIXED #1: Dockerfile now has ARG/ENV declarations                                 │
    │                                                                                                │
    │    Stage 2: PUSH (REGISTRY STORES IMMUTABLE ARTIFACT)                                        │
    │    ├─ Push to private registry: 192.168.0.113:5000                                          │
    │    ├─ Full image: 192.168.0.113:5000/root/project_nebula/fastapi-demo:abc1234              │
    │    ├─ Registry authentication: GitLab credentials                                           │
    │    └─ Image is now immutable (digest: sha256:...)                                           │
    │                                                                                                │
    │    Stage 3: DEPLOY (HELM VALUES UPDATED WITH SPECIFIC TAG)                                  │
    │    ├─ Update: helm/fastapi-app/values.yaml                                                  │
    │    ├─ image.tag = ${CI_COMMIT_SHORT_SHA}  (NEVER "latest"!)                                │
    │    ├─ git commit -m "Update image tag to abc1234"                                           │
    │    └─ git push → ArgoCD detects change                                                      │
    │                                                                                                │
    │    Result: CI has decided the image identity. Everything else consumes it.                  │
    │                                                                                                │
    └────────────────────────────────────────────────────────────────────────────────────────────────┘
                                                   │
                                                   │ (3) Deploy to K3s via ArgoCD
                                                   ▼
╔════════════════════════════════════════════════════════════════════════════════════════════════════════════════╗
║                           KUBERNETES CLUSTER (K3s) - 192.168.0.113                                           ║
║                              Single Node - All services running                                              ║
╚════════════════════════════════════════════════════════════════════════════════════════════════════════════════╝

┌────────────────────────────────────────────────────────────────────────────────────────────────────────────────┐
│                                      KUBE-SYSTEM NAMESPACE                                                   │
│                                                                                                              │
│  ┌──────────────────────────────────────────────────────────────────────────────────────────────────────┐   │
│  │                            MetalLB (Load Balancer)                                                 │   │
│  │                                                                                                    │   │
│  │  • Controller Pod (kube-system):                                                                 │   │
│  │    - Manages IP pool allocation                                                                  │   │
│  │    - Runs 2 replicas for HA                                                                      │   │
│  │    - Pod IPs: 10.42.0.X range                                                                    │   │
│  │                                                                                                    │   │
│  │  • Configuration:                                                                                │   │
│  │    - Mode: Layer 2 (ARP-based)                                                                   │   │
│  │    - IP Pool: 192.168.0.201 - 192.168.0.250                                                    │   │
│  │    - Auto-assign: Enabled                                                                        │   │
│  │                                                                                                    │   │
│  │  • IP Assignments:                                                                               │   │
│  │    - 192.168.0.200: Traefik (Load Balancer)                                                     │   │
│  │    - 192.168.0.201: Envoy Gateway System                                                        │   │
│  │    - 192.168.0.202: ArgoCD Server                                                               │   │
│  │    - 192.168.0.203: FastAPI LoadBalancer (fastapi-app-lb)                                      │   │
│  │    - 192.168.0.204: Prometheus LoadBalancer                                                     │   │
│  │    - 192.168.0.205: Envoy Production Gateway (HTTPRoute)                                        │   │
│  │    - 192.168.0.206: Grafana LoadBalancer                                                        │   │
│  │    - 192.168.0.207: FastAPI (fastapi-app additional replica)                                   │   │
│  │    - 192.168.0.207-250: Available pool                                                          │   │
│  │                                                                                                    │   │
│  └──────────────────────────────────────────────────────────────────────────────────────────────────┘   │
│                                                                                                              │
│  ┌──────────────────────────────────────────────────────────────────────────────────────────────────────┐   │
│  │                              CoreDNS (Internal DNS)                                               │   │
│  │                                                                                                    │   │
│  │  • Provides DNS resolution within cluster                                                        │   │
│  │  • ClusterIP: 10.43.0.10                                                                         │   │
│  │  • All pods use this for service discovery                                                       │   │
│  │  • Example: fastapi-service.production.svc.cluster.local → 10.43.57.102                        │   │
│  │                                                                                                    │   │
│  └──────────────────────────────────────────────────────────────────────────────────────────────────┘   │
│                                                                                                              │
│  ┌──────────────────────────────────────────────────────────────────────────────────────────────────────┐   │
│  │                        Envoy Gateway (Gateway API Controller)                                   │   │
│  │                                                                                                    │   │
│  │  • Status: Deployed (RBAC permission issues for routing)                                         │   │
│  │  • Gateway Pod IP: 10.42.0.X                                                                     │   │
│  │  • External IP: 192.168.0.206                                                                    │   │
│  │  • Port: 80/443                                                                                  │   │
│  │  • Purpose: Route HTTP traffic to services based on HTTPRoute rules                             │   │
│  │                                                                                                    │   │
│  └──────────────────────────────────────────────────────────────────────────────────────────────────┘   │
│                                                                                                              │
└────────────────────────────────────────────────────────────────────────────────────────────────────────────────┘

┌────────────────────────────────────────────────────────────────────────────────────────────────────────────────┐
│                    🔄 ARGOCD NAMESPACE (GitOps Enforcer - Ensures Determinism)                             │
│                                                                                                              │
│  ┌──────────────────────────────────────────────────────────────────────────────────────────────────────┐   │
│  │                        ArgoCD Application Controller                                            │   │
│  │                                                                                                    │   │
│  │  ArgoCD Server Pod:                                                                              │   │
│  │  • Pod IP: 10.42.0.X (cluster internal)                                                          │   │
│  │  • Service Type: LoadBalancer                                                                    │   │
│  │  • External IP: 192.168.0.202                                                                    │   │
│  │  • Port: 80 (HTTP) / 443 (HTTPS)                                                                │   │
│  │  • Access: http://192.168.0.202                                                                 │   │
│  │                                                                                                    │   │
│  │  🎯 DETERMINISTIC SYNC (Git is Source of Truth):                                               │   │
│  │  • Repository: git@192.168.0.190:/root/project_nebula.git                                       │   │
│  │  • Branch: feature/gitlab-gitops-enhancements (TESTING)                                         │   │
│  │  • Path: helm/fastapi-app/ (Helm values with image.tag)                                         │   │
│  │  • Sync Policy: Auto-sync enabled, prune enabled, self-heal enabled                            │   │
│  │  • Result: Git state ALWAYS = Cluster state (no manual kubectl apply)                           │   │
│  │                                                                                                    │   │
│  │  Monitoring Applications:                                                                        │   │
│  │  ┌─────────────────────────────────────────────────────────────────────────────────────────┐   │   │
│  │  │  App 1: fastapi-production                                                              │   │   │
│  │  │  • Source: helm/fastapi-app/ (Helm chart rendering)                                     │   │   │
│  │  │  • Namespace: production                                                                │   │   │
│  │  │  • Status: Synced & Healthy                                                            │   │   │
│  │  │  • Replicas: 3/3 Running                                                                │   │   │
│  │  │  • Image Tag: Specific commit SHA (from values.yaml, injected by CI)                   │   │   │
│  │  │  • NEVER: "latest" tag (ensures determinism)                                           │   │   │
│  │  └─────────────────────────────────────────────────────────────────────────────────────────┘   │   │
│  │                                                                                                    │   │
│  │  ┌─────────────────────────────────────────────────────────────────────────────────────────┐   │   │
│  │  │  App 2: prometheus                                                                      │   │   │
│  │  │  • Source: monitoring/prometheus/values.yaml (Helm chart)                               │   │   │
│  │  │  • Namespace: monitoring                                                                │   │   │
│  │  │  • Status: Synced & Healthy                                                            │   │   │
│  │  │  • Replicas: 1/1 Running                                                                │   │   │
│  │  └─────────────────────────────────────────────────────────────────────────────────────────┘   │   │
│  │                                                                                                    │   │
│  │  ┌─────────────────────────────────────────────────────────────────────────────────────────┐   │   │
│  │  │  App 3: grafana                                                                         │   │   │
│  │  │  • Source: monitoring/grafana/values.yaml (Helm chart)                                  │   │   │
│  │  │  • Namespace: monitoring                                                                │   │   │
│  │  │  • Status: Synced & Healthy                                                            │   │   │
│  │  │  • Replicas: 1/1 Running                                                                │   │   │
│  │  └─────────────────────────────────────────────────────────────────────────────────────────┘   │   │
│  │                                                                                                    │   │
│  └──────────────────────────────────────────────────────────────────────────────────────────────────┘   │
│                                                                                                              │
└────────────────────────────────────────────────────────────────────────────────────────────────────────────────┘

┌────────────────────────────────────────────────────────────────────────────────────────────────────────────────┐
│                                  PRODUCTION NAMESPACE                                                        │
│                                                                                                              │
│  ┌──────────────────────────────────────────────────────────────────────────────────────────────────────┐   │
│  │          🚀 FastAPI Deployment (3 Replicas - Deterministic with Metadata Awareness)         │   │
│  │                                                                                                    │   │
│  │  ┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐                          │   │
│  │  │   Pod 1         │    │   Pod 2         │    │   Pod 3         │                          │   │
│  │  │                 │    │                 │    │                 │                          │   │
│  │  │ Pod IP:         │    │ Pod IP:         │    │ Pod IP:         │                          │   │
│  │  │ 10.42.0.114     │    │ 10.42.0.115     │    │ 10.42.0.116     │                          │   │
│  │  │                 │    │                 │    │                 │                          │   │
│  │  │ Container:      │    │ Container:      │    │ Container:      │                          │   │
│  │  │ fastapi-app     │    │ fastapi-app     │    │ fastapi-app     │                          │   │
│  │  │                 │    │                 │    │                 │                          │   │
│  │  │ Image (SPECIFIC │    │ Image (SPECIFIC │    │ Image (SPECIFIC │                          │   │
│  │  │ COMMIT SHA):    │    │ COMMIT SHA):    │    │ COMMIT SHA):    │                          │   │
│  │  │ 192.168.0.113:  │    │ 192.168.0.113:  │    │ 192.168.0.113:  │                          │   │
│  │  │ 5000/.../       │    │ 5000/.../       │    │ 5000/.../       │                          │   │
│  │  │ fastapi-demo:   │    │ fastapi-demo:   │    │ fastapi-demo:   │                          │   │
│  │  │ abc1234         │    │ abc1234         │    │ abc1234         │                          │   │
│  │  │ (NO "latest"!)  │    │ (NO "latest"!)  │    │ (NO "latest"!)  │                          │   │
│  │  │                 │    │                 │    │                 │                          │   │
│  │  │ Container Port: │    │ Container Port: │    │ Container Port: │                          │   │
│  │  │ 8000            │    │ 8000            │    │ 8000            │                          │   │
│  │  │                 │    │                 │    │                 │                          │   │
│  │  │ Environment     │    │ Environment     │    │ Environment     │                          │   │
│  │  │ (from image):   │    │ (from image):   │    │ (from image):   │                          │   │
│  │  │ • ENV:          │    │ • ENV:          │    │ • ENV:          │                          │   │
│  │  │   production    │    │   production    │    │   production    │                          │   │
│  │  │ • APP_VERSION   │    │ • APP_VERSION   │    │ • APP_VERSION   │                          │   │
│  │  │   (from Env)    │    │   (from Env)    │    │   (from Env)    │                          │   │
│  │  │ • BUILD_TIME    │    │ • BUILD_TIME    │    │ • BUILD_TIME    │                          │   │
│  │  │   (from Env)    │    │   (from Env)    │    │   (from Env)    │                          │   │
│  │  │ • IMAGE_TAG     │    │ • IMAGE_TAG     │    │ • IMAGE_TAG     │                          │   │
│  │  │   (from Env)    │    │   (from Env)    │    │   (from Env)    │                          │   │
│  │  │ ✅ ENV vars SET in image!                                                               │   │
│  │  │                 │    │                 │    │                 │                          │   │
│  │  │ Endpoints:      │    │ Endpoints:      │    │ Endpoints:      │                          │   │
│  │  │ • /health       │    │ • /health       │    │ • /health       │                          │   │
│  │  │ • /ready        │    │ • /ready        │    │ • /ready        │                          │   │
│  │  │ • /metrics      │    │ • /metrics      │    │ • /metrics      │                          │   │
│  │  │ • /version ✅   │    │ • /version ✅   │    │ • /version ✅   │                          │   │
│  │  │                 │    │                 │    │                 │                          │   │
│  │  │ Probes:         │    │ Probes:         │    │ Probes:         │                          │   │
│  │  │ • Liveness:     │    │ • Liveness:     │    │ • Liveness:     │                          │   │
│  │  │   /health ✅    │    │   /health ✅    │    │   /health ✅    │                          │   │
│  │  │ • Readiness:    │    │ • Readiness:    │    │ • Readiness:    │                          │   │
│  │  │   /health ✅    │    │   /health ✅    │    │   /health ✅    │                          │   │
│  │  │                 │    │                 │    │                 │                          │   │
│  │  │ Resources:      │    │ Resources:      │    │ Resources:      │                          │   │
│  │  │ • Requested:    │    │ • Requested:    │    │ • Requested:    │                          │   │
│  │  │   256Mi RAM     │    │   256Mi RAM     │    │   256Mi RAM     │                          │   │
│  │  │ • Limits:       │    │ • Limits:       │    │ • Limits:       │                          │   │
│  │  │   (default)     │    │   (default)     │    │   (default)     │                          │   │
│  │  │                 │    │                 │    │                 │                          │   │
│  │  └─────────────────┘    └─────────────────┘    └─────────────────┘                          │   │
│  │           │                      │                      │                                   │   │
│  │           └──────────────────────┼──────────────────────┘                                   │   │
│  │                                  ▼                                                          │   │
│  │                    ┌──────────────────────────────┐                                        │   │
│  │                    │  ClusterIP Service           │                                        │   │
│  │                    │  fastapi-service             │                                        │   │
│  │                    │                              │                                        │   │
│  │                    │ Internal IP: 10.43.57.102    │                                        │   │
│  │                    │ Internal DNS:                │                                        │   │
│  │                    │ fastapi-service.production   │                                        │   │
│  │                    │ .svc.cluster.local           │                                        │   │
│  │                    │                              │                                        │   │
│  │                    │ Port Mapping:                │                                        │   │
│  │                    │ • Service Port: 80           │                                        │   │
│  │                    │ • Target Port: 8000          │                                        │   │
│  │                    │                              │                                        │   │
│  │                    │ Load Balancing:              │                                        │   │
│  │                    │ • Algorithm: Round-robin     │                                        │   │
│  │                    │ • Session Affinity: ClientIP │                                        │   │
│  │                    │ • Timeout: 3 hours (10800s)  │                                        │   │
│  │                    │                              │                                        │   │
│  │                    └──────────────────────────────┘                                        │   │
│  │                                  │                                                          │   │
│  │                                  ▼                                                          │   │
│  │                    ┌──────────────────────────────┐                                        │   │
│  │                    │  LoadBalancer Service        │                                        │   │
│  │                    │  fastapi-demo (external)     │                                        │   │
│  │                    │                              │                                        │   │
│  │                    │ External IP: 192.168.0.203   │                                        │   │
│  │                    │ Service Port: 80             │                                        │   │
│  │                    │ Target Port: 8000            │                                        │   │
│  │                    │                              │                                        │   │
│  │                    │ Access URLs:                 │                                        │   │
│  │                    │ • API: 192.168.0.203/        │                                        │   │
│  │                    │ • Docs: 192.168.0.203/docs   │                                        │   │
│  │                    │ • Health: 192.168.0.203/     │                                        │   │
│  │                    │   health                     │                                        │   │
│  │                    │ • Metrics: 192.168.0.203/    │                                        │   │
│  │                    │   metrics                    │                                        │   │
│  │                    │ • /version: 192.168.0.203/version ✅ │                                  │   │
│  │                    │                              │                                        │   │
│  │                    │ Traffic Policy:              │                                        │   │
│  │                    │ • Preserve Source IP: false  │                                        │   │
│  │                    │ • Distribution: Cluster-wide │                                        │   │
│  │                    │ • Endpoints: 3/3 ready       │                                        │   │
│  │                    │                              │                                        │   │
│  │                    └──────────────────────────────┘                                        │   │
│  │                                                                                              │   │
│  │  🔄 ROLLOUT STRATEGY:                                                                      │   │
│  │  ┌──────────────────────────────────────────────────────────┐                             │   │
│  │  │ ✅ CONFIGURED: Explicit rolling update strategy      │                             │   │
│  │  │                                                           │                             │   │
│  │  │ Current: Rolling update configured ✅                 │                             │   │
│  │  │ Strategy:                                            │                             │   │
│  │  │   strategy:                                              │                             │   │
│  │  │     type: RollingUpdate                                  │                             │   │
│  │  │     rollingUpdate:                                       │                             │   │
│  │  │       maxSurge: 1                                        │                             │   │
│  │  │       maxUnavailable: 0                                  │                             │   │
│  │  │                                                           │                             │   │
│  │  │ Ensures: Zero-downtime deployments                       │                             │   │
│  │  └──────────────────────────────────────────────────────────┘                             │   │
│  │                                                                                              │   │
│  └──────────────────────────────────────────────────────────────────────────────────────────────┘   │
│                                                                                                      │
└────────────────────────────────────────────────────────────────────────────────────────────────────────────┘

┌────────────────────────────────────────────────────────────────────────────────────────────────────────────────┐
│                                  MONITORING NAMESPACE                                                        │
│                                                                                                              │
│  ┌──────────────────────────────────────────────────────────────────────────────────────────────────────┐   │
│  │                  Prometheus Server (Metrics Collection)                                        │   │
│  │                                                                                                    │   │
│  │  Pod Details:                                                                                     │   │
│  │  • Pod IP: 10.42.0.X                                                                             │   │
│  │  • Namespace: monitoring                                                                          │   │
│  │  • Replicas: 1                                                                                    │   │
│  │                                                                                                    │   │
│  │  Services:                                                                                        │   │
│  │  • ClusterIP Service: 10.43.X.X:9090                                                             │   │
│  │  • LoadBalancer Service:                                                                          │   │
│  │    - External IP: 192.168.0.204                                                                  │   │
│  │    - Port: 9090                                                                                  │   │
│  │    - Access: http://192.168.0.204:9090                                                           │   │
│  │                                                                                                    │   │
│  │  Scrape Configuration:                                                                            │   │
│  │  • Interval: 15 seconds                                                                           │   │
│  │  • Timeout: 10 seconds                                                                            │   │
│  │  • Targets:                                                                                       │   │
│  │    - kubelet (node metrics): 192.168.0.113:10250                                                │   │
│  │    - kube-proxy (network): 10.42.0.X:10249                                                      │   │
│  │    - kube-apiserver: https://10.43.0.1:443/metrics                                              │   │
│  │    - FastAPI /metrics (prometheus.io/scrape annotation) → includes /version data                │   │
│  │                                                                                                    │   │
│  │  Data Storage:                                                                                    │   │
│  │  • Storage Type: PersistentVolume (emptyDir for dev)                                            │   │
│  │  • Retention: 30 days                                                                             │   │
│  │  • Memory Cache: ~2GB                                                                             │   │
│  │  • Metrics Stored: 1M+ time-series                                                               │   │
│  │                                                                                                    │   │
│  │  Metrics Collected:                                                                               │   │
│  │  • Node Metrics:                                                                                  │   │
│  │    - node_cpu_seconds_total                                                                     │   │
│  │    - node_memory_MemAvailable_bytes                                                             │   │
│  │    - node_filesystem_avail_bytes                                                                │   │
│  │  • Pod Metrics:                                                                                  │   │
│  │    - container_cpu_usage_seconds_total                                                          │   │
│  │    - container_memory_usage_bytes                                                               │   │
│  │  • Service Metrics:                                                                              │   │
│  │    - http_requests_total (from /metrics endpoint)                                              │   │
│  │    - http_request_duration_seconds                                                              │   │
│  │    - Can monitor /version endpoint for image/version changes                                   │   │
│  │                                                                                                    │   │
│  └──────────────────────────────────────────────────────────────────────────────────────────────────┘   │
│                                                                                                              │
│  ┌──────────────────────────────────────────────────────────────────────────────────────────────────────┐   │
│  │              Grafana Server (Metrics Visualization & Dashboards)                               │   │
│  │                                                                                                    │   │
│  │  Pod Details:                                                                                     │   │
│  │  • Pod IP: 10.42.0.X                                                                             │   │
│  │  • Namespace: monitoring                                                                          │   │
│  │  • Replicas: 1                                                                                    │   │
│  │                                                                                                    │   │
│  │  Services:                                                                                        │   │
│  │  • ClusterIP Service: 10.43.X.X:3000                                                             │   │
│  │  • LoadBalancer Service:                                                                          │   │
│  │    - External IP: 192.168.0.205                                                                  │   │
│  │    - Port: 3000                                                                                  │   │
│  │    - Access: http://192.168.0.205:3000                                                           │   │
│  │                                                                                                    │   │
│  │  Authentication:                                                                                  │   │
│  │  • Username: admin                                                                                │   │
│  │  • Password: grafana (stored in secrets)                                                         │   │
│  │  • Authentication Type: Basic Auth                                                                │   │
│  │                                                                                                    │   │
│  │  Data Source:                                                                                     │   │
│  │  • Name: Prometheus                                                                               │   │
│  │  • URL: http://prometheus.monitoring.svc.cluster.local:9090                                      │   │
│  │  • Internal resolution: CoreDNS → 10.43.X.X:9090                                                 │   │
│  │  • Connection: Direct in-cluster communication                                                   │   │
│  │                                                                                                    │   │
│  │  Pre-built Dashboards:                                                                            │   │
│  │  1. Kubernetes Cluster Monitoring                                                                 │   │
│  │     - Node CPU, Memory, Network Usage                                                             │   │
│  │     - Pod resource utilization                                                                   │   │
│  │     - Network I/O rates                                                                           │   │
│  │                                                                                                    │   │
│  │  2. FastAPI Application Metrics                                                                   │   │
│  │     - Request rate (RPS)                                                                          │   │
│  │     - Response time (latency)                                                                    │   │
│  │     - Error rate by endpoint                                                                     │   │
│  │     - CPU and memory per pod                                                                     │   │
│  │     - Can display version info from /version endpoint (after Gap #2 fix)                        │   │
│  │                                                                                                    │   │
│  │  3. Pod & Container Health                                                                        │   │
│  │     - Pod restart count                                                                           │   │
│  │     - Container memory OOM events                                                                 │   │
│  │     - Pod network throughput                                                                     │   │
│  │                                                                                                    │   │
│  │  Alerting Rules: (Can be configured)                                                              │   │
│  │  - High CPU utilization (>80%)                                                                   │   │
│  │  - High memory usage (>90%)                                                                      │   │
│  │  - Pod CrashLoopBackOff                                                                           │   │
│  │  - Service endpoint down                                                                         │   │
│  │  - Request error rate spike                                                                      │   │
│  │  - Image version mismatch (can alert if /version shows unexpected metadata)                     │   │
│  │                                                                                                    │   │
│  └──────────────────────────────────────────────────────────────────────────────────────────────────┘   │
│                                                                                                              │
└────────────────────────────────────────────────────────────────────────────────────────────────────────────────┘

```

---

## 🧠 Deterministic Responsibility Boundary Summary (Overlaid on Diagram)

### What Each Layer Does

**CI (GitLab CI) - Layer 1: DECIDES**
- Sets `APP_VERSION`, `BUILD_TIME`, `IMAGE_TAG`
- Passes as build args to Docker
- Pushes image with specific commit SHA tag
- Updates Helm values with that tag
- **This is the source of truth**

**Docker Image - Layer 2: CARRIES**
- **Must have**: ARG declarations for APP_VERSION, BUILD_TIME, IMAGE_TAG
- **Must have**: ENV statements to make them available at runtime
- **Gap #1**: ✅ FIXED - Dockerfile now declares build args
- Image becomes immutable once pushed

**Kubernetes Deployment - Layer 3: PULLS & RUNS**
- Pulls image with specific tag (from Helm values)
- Creates 3 pod replicas
- Checks `/health` endpoint (readiness probe)
- Runs Prometheus metrics collection
- **Gap #2**: ✅ FIXED - /version endpoint implemented
- **Gap #3**: ✅ FIXED - Rolling update strategy configured

**Prometheus - Layer 4: MEASURES**
- Scrapes `/metrics` endpoint
- Scrapes `/version` endpoint for image metadata ✅
- Records metrics over time
- Proves which image is serving traffic

**ArgoCD - Layer 5: ENFORCES**
- Watches Git repository continuously
- Compares: desired state (Git) vs actual state (Cluster)
- Automatically syncs when divergence detected
- Never allows manual out-of-sync state

---

## 📊 Original Network Flow Paths (Preserved from V1)

### Data Flow Path 1: Accessing FastAPI Application

```
User Browser (External)
    │
    ▼ HTTP Request to 192.168.0.203:80
┌─────────────────────────────────┐
│  MetalLB                         │
│  ARP Resolution                  │
│  192.168.0.203 → MAC address     │
└─────────────────────────────────┘
    │
    ▼ Internal routing (Layer 2)
┌─────────────────────────────────┐
│  FastAPI LoadBalancer Service    │
│  Endpoint: 192.168.0.203         │
│  Port: 80                        │
└─────────────────────────────────┘
    │
    ▼ Service routing (iptables rules)
┌─────────────────────────────────┐
│  ClusterIP Service               │
│  IP: 10.43.57.102:80             │
│  Destination: 3 pod IPs          │
└─────────────────────────────────┘
    │
    ├─► Pod 1: 10.42.0.114:8000 (33% traffic)
    ├─► Pod 2: 10.42.0.115:8000 (33% traffic)
    └─► Pod 3: 10.42.0.116:8000 (34% traffic)
    │
    ▼ FastAPI Application
  Response (JSON, HTML, etc.)
    │
    ▼ Return through LoadBalancer
  Response sent to 192.168.0.203
    │
    ▼
User Browser receives response
```

### Data Flow Path 2: Application Deployment (GitLab CI/CD with Determinism)

```
Developer commits code to git
    │
    ▼ git push to 192.168.0.190:master
┌─────────────────────────────────────────────────────────────────┐
│  GitLab Repository                                              │
│  /root/project_nebula.git                                       │
└─────────────────────────────────────────────────────────────────┘
    │
    ▼ GitLab CI/CD Trigger (webhook)
┌─────────────────────────────────────────────────────────────────┐
│  GitLab Runner (build + push stages)                            │
│  Host: 192.168.0.190                                            │
│                                                                 │
│  Build stage:                                                   │
│  1. Clone repo                                                  │
│  2. Set BUILD_TIME=$(date -u +"%Y-%m-%dT%H:%M:%SZ")            │
│  3. docker build --build-arg APP_VERSION=${SHA} \              │
│            --build-arg BUILD_TIME=${BUILD_TIME} \              │
│            --build-arg IMAGE_TAG=${SHA} .                      │
│  4. Tag: fastapi-demo:${CI_COMMIT_SHORT_SHA}                  │
│                                                                 │
│  Push stage:                                                    │
│  5. docker push 192.168.0.113:5000/.../fastapi-demo:${SHA}    │
│  6. Image now in private registry (immutable)                  │
│                                                                 │
│  Update Helm values stage:                                      │
│  7. Update helm/fastapi-app/values.yaml                        │
│     image.tag: "${CI_COMMIT_SHORT_SHA}"                        │
│  8. git commit -m "Update image tag to ${SHA}"                 │
│  9. git push                                                    │
└─────────────────────────────────────────────────────────────────┘
    │
    ▼ Docker Registry (Private)
┌─────────────────────────────────────────────────────────────────┐
│  Location: 192.168.0.113:5000                                   │
│  Image stored: fastapi-demo:abc1234 (immutable)                │
│  Digest: sha256:xyz789... (immutable hash)                      │
└─────────────────────────────────────────────────────────────────┘
    │
    ▼ Git Repository (Helm values updated)
┌─────────────────────────────────────────────────────────────────┐
│  ArgoCD detects change in helm/fastapi-app/values.yaml         │
│  Fetches new values with image.tag = abc1234                   │
│  Renders Helm template with specific tag                       │
│  Applies kubectl with deterministic image reference            │
└─────────────────────────────────────────────────────────────────┘
    │
    ▼ Kubernetes API Server
┌─────────────────────────────────────────────────────────────────┐
│  K3s Control Plane: https://192.168.0.113:6443                 │
│                                                                 │
│  Process deployment manifest:                                  │
│  • Image: 192.168.0.113:5000/.../fastapi-demo:abc1234 (SPECIFIC)
│  • NOT: ...fastapi-demo:latest (would be non-deterministic)   │
│  • Create/Update Deployment with 3 replicas                   │
│  • Schedule pods on node                                       │
└─────────────────────────────────────────────────────────────────┘
    │
    ▼ Kubelet (K3s Node) pulls image
┌─────────────────────────────────────────────────────────────────┐
│  Container Runtime (Docker/Containerd)                          │
│  ImagePullPolicy: IfNotPresent                                  │
│  1. Pull: 192.168.0.113:5000/.../fastapi-demo:abc1234         │
│  2. Create container                                            │
│  3. Start uvicorn process                                       │
│  4. Environment vars set (from Dockerfile - Gap #1 must fix!)  │
└─────────────────────────────────────────────────────────────────┘
    │
    ▼ Running Pods (Ready to serve traffic)
┌─────────────────────────────────────────────────────────────────┐
│  3 FastAPI replicas running same image (deterministic)         │
│  All serving from: fastapi-demo:abc1234                        │
│  All have same metadata: APP_VERSION, BUILD_TIME, IMAGE_TAG   │
│  Readiness probe passes (/health returns 200)                  │
└─────────────────────────────────────────────────────────────────┘
```

### Data Flow Path 3: Monitoring Data Collection (with Version Tracking)

```
Prometheus Server (192.168.0.204:9090) - Scrapes every 15 seconds
    │
    ├─► FastAPI /metrics endpoint (10.43.57.102:80/metrics)
    │   └─ http_requests_total, http_request_duration_seconds
    │
    ├─► FastAPI /version endpoint (10.43.57.102:80/version) [After Gap #2 fix]
    │   └─ app_version: "abc1234"
    │   └─ build_time: "2026-02-03T14:30:00Z"
    │   └─ image_tag: "abc1234"
    │   └─ pod: "fastapi-app-7d5f9c2b9-xxxxx"
    │   └─ uptime_seconds: 300
    │
    ├─► Kubelet Metrics (192.168.0.113:10250)
    │   └─ node_cpu_seconds_total, node_memory_MemAvailable_bytes
    │
    └─► API Server Metrics (10.43.0.1:443/metrics)
        └─ API operations, resource events
    │
    ▼ Time-series database
    Prometheus TSDB stores all metrics with timestamps
    │
    ▼ Grafana queries data
    Grafana (192.168.0.206:80) creates visualizations
    │
    ▼ User views dashboard
    Can see which image version is running
    Can detect version changes
    Can correlate metrics with deployments
```

### Data Flow Path 4: GitOps Sync (ArgoCD - Deterministic Enforcement)

```
ArgoCD Server (192.168.0.202) - Watches every 3 minutes
    │
    ├─ Git repository check
    │  └─ Fetches: helm/fastapi-app/values.yaml
    │  └─ Line: image.tag: "abc1234"
    │
    ├─ Cluster state check
    │  └─ kubectl get deployment fastapi-app -n production
    │  └─ Current: fastapi-demo:abc1234
    │
    ├─ Compare: Git state vs Cluster state
    │  ├─ If MATCH: Already synced ✓
    │  └─ If DIVERGENCE: Apply changes
    │
    ├─ If divergence detected:
    │  1. Helm render with values from Git
    │  2. kubectl apply the rendered YAML
    │  3. Update Application status
    │
    └─ Continuous reconciliation
       ├─ No manual kubectl apply allowed
       ├─ Git is only source of truth
       ├─ Drift correction is automatic
       └─ All changes auditable in Git history
```

---

## 🔗 IP Address Mapping Table (Original - Preserved)

| Component | Type | IP Address | Port | Protocol | Purpose |
|-----------|------|-----------|------|----------|---------|
| **GitLab Server** | Ext Server | 192.168.0.190 | 22, 80, 443, 5000 | SSH/HTTP/HTTPS/Docker | Git repo, CI/CD, Docker Registry |
| **K3s Cluster Node** | Master Node | 192.168.0.113 | 6443 | HTTPS | Kubernetes API Server |
| **K3s Kubelet** | Node Service | 192.168.0.113 | 10250 | HTTPS | Node metrics endpoint |
| **MetalLB Controller** | Internal | 10.42.0.X | - | - | Load balancer management |
| **CoreDNS** | Service | 10.43.0.10 | 53 | UDP | Cluster DNS |
| **FastAPI Pod 1** | Pod | 10.42.0.114 | 8000 | TCP | Application container |
| **FastAPI Pod 2** | Pod | 10.42.0.115 | 8000 | TCP | Application container |
| **FastAPI Pod 3** | Pod | 10.42.0.116 | 8000 | TCP | Application container |
| **FastAPI ClusterIP Svc** | Service | 10.43.57.102 | 80 | TCP | Internal service discovery |
| **FastAPI LoadBalancer Svc** | Service | 192.168.0.203 | 80 | TCP | External access point |
| **Prometheus Pod** | Pod | 10.42.0.X | 9090 | TCP | Metrics server |
| **Prometheus LoadBalancer** | Service | 192.168.0.204 | 9090 | TCP | External metrics access |
| **Grafana Pod** | Pod | 10.42.0.X | 3000 | TCP | Dashboard server |
| **Grafana LoadBalancer** | Service | 192.168.0.206 | 80 | TCP | External dashboard access |
| **ArgoCD Server Pod** | Pod | 10.42.0.X | 8080 | TCP | GitOps controller |
| **ArgoCD LoadBalancer** | Service | 192.168.0.202 | 80/443 | TCP | External ArgoCD UI access |
| **Envoy Gateway** | Pod | 10.42.0.X | 80/443 | TCP | API gateway (optional) |
| **Envoy Production Gateway** | Service | 192.168.0.205 | 80 | TCP | HTTPRoute gateway external IP |
| **Traefik Load Balancer** | Service | 192.168.0.200 | 80/443 | TCP | Default load balancer |
| **Envoy Gateway System** | Service | 192.168.0.201 | 18000-19001 | TCP | Gateway system controller |

---

## 🔐 Access Endpoints Summary (Original - Preserved)

```
┌─────────────────────────────────────────────────────────────────┐
│                    EXTERNAL ACCESS POINTS                       │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  🚀 FastAPI Application                                         │
│     URL: http://192.168.0.203                                   │
│     • API Base: http://192.168.0.203                            │
│     • Documentation: http://192.168.0.203/docs                  │
│     • Health Check: http://192.168.0.203/health                 │
│     • Metrics: http://192.168.0.203/metrics                     │
│     • Load Balanced across 3 pods                               │
│                                                                 │
│  📊 Prometheus (Metrics Database)                               │
│     URL: http://192.168.0.204:9090                              │
│     • Metrics Query Interface                                   │
│     • Time-series data explorer                                 │
│     • Alert rules management                                    │
│                                                                 │
│  📈 Grafana (Dashboard & Visualization)                         │
│     URL: http://192.168.0.206:3000                              │
│     Username: admin                                             │
│     Password: grafana                                           │
│     • Pre-built dashboards                                      │
│     • Custom metrics visualization                              │
│     • Real-time monitoring                                      │
│                                                                 │
│  🔄 ArgoCD (GitOps Controller)                                  │
│     URL: http://192.168.0.202                                   │
│     Username: admin                                             │
│     Password: [see argocd-password.txt]                         │
│     • Application deployment status                             │
│     • GitOps sync management                                    │
│     • Resource monitoring                                       │
│                                                                 │
│  🌐 Envoy Gateway (Optional - RBAC Pending)                     │
│     URL: http://192.168.0.205                                   │
│     • API routing (when configured)                             │
│     • HTTP/2 support                                            │
│     • Advanced routing rules                                    │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

---

## 🎯 V3 Enhancement Summary

### What's Better in V3

1. **Visual Metadata Flow**: Added build arg injection on diagrams
2. **Gap Markers**: Clearly marked 3 implementation gaps on architecture
3. **Responsibility Overlays**: Shows which layer does what
4. **Deterministic Annotations**: Added "SPECIFIC" vs "latest" tag indicators
5. **Monitoring Integration**: Shows version tracking via /version endpoint
6. **GitOps Flow**: Enhanced deployment flow with Git-as-truth emphasis

### What's Preserved from V1

- ✅ All original ASCII diagrams (excellent quality)
- ✅ All IP mappings and tables
- ✅ All networking flows
- ✅ All access endpoints
- ✅ All security descriptions
- ✅ All communication patterns

### New Content Added

- 🆕 Deterministic responsibility boundaries
- 🆕 Gap identification with ⚠️ markers
- 🆕 Build argument flow visualization
- 🆕 Metadata environment variable tracking
- 🆕 Version endpoint for observability
- 🆕 Enhanced deployment flow annotations
- 🆕 GitOps determinism enforcement notes

---

## ✅ Verification Commands (Original - Preserved)

```bash
# Check all services and their external IPs
kubectl get svc -A

# View MetalLB pool assignments
kubectl get ipaddresspools -n metallb-system -o wide

# Check FastAPI pods and IPs
kubectl get pods -n production -o wide

# View service endpoints (pod IPs)
kubectl get endpoints -n production

# Test connectivity
curl http://192.168.0.203/health        # FastAPI health
curl http://192.168.0.204:9090          # Prometheus
curl http://192.168.0.206:3000          # Grafana
curl http://192.168.0.202               # ArgoCD

# Test /version endpoint (after Gap #2 fix)
curl http://192.168.0.203/version

# Check ArgoCD application status
kubectl get applications -n argocd

# Monitor traffic in real-time
kubectl top nodes
kubectl top pods -n production
```

---

## 📚 Documentation Hierarchy

**V3 is the latest version**, combining:
- V1: Original excellent diagrams ✅ (preserved)
- V2: Deterministic model integration ✅ (enhanced)
- V3: Everything together ✅ (current)

**Use V3 for:**
- Complete architecture understanding
- Seeing gaps in current implementation
- Understanding metadata flow
- Planning deployment improvements
- Training team on deterministic design

---

**Status**: ✅ Complete  
**Created**: February 3, 2026  
**Enhancement**: Integrated deterministic model with preserved original diagrams  
**Next**: Implement 3 gaps using IMPLEMENTATION_CHECKLIST.md
