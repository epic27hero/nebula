# Project Nebula - End-to-End Architecture Diagram with IPs

## 📊 Complete System Architecture

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
    │                                    GitLab CI/CD PIPELINE                                       │
    │                                                                                                │
    │    Workflow Stages:                                                                           │
    │                                                                                                │
    │    Stage 1: BUILD                                                                             │
    │    ├─ Trigger: git push to master branch                                                     │
    │    ├─ Build Docker image: 192.168.0.113:5000/fastapi-demo:latest                           │
    │    └─ Build context: /src/Dockerfile                                                         │
    │                                                                                                │
    │    Stage 2: PUSH                                                                              │
    │    ├─ Push to private registry: 192.168.0.113:5000                                          │
    │    ├─ Registry authentication: GitLab credentials                                           │
    │    └─ Image tags: latest + commit SHA                                                        │
    │                                                                                                │
    │    Stage 3: DEPLOY                                                                            │
    │    ├─ SSH to K3s server: 192.168.0.113                                                      │
    │    ├─ kubectl apply -f manifests/                                                           │
    │    ├─ Update image pull policy: Always                                                      │
    │    └─ Trigger rolling deployment                                                             │
    │                                                                                                │
    └────────────────────────────────────────────────────────────────────────────────────────────────┘
                                                   │
                                                   │ (3) Deploy to K3s
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
│                                    ARGOCD NAMESPACE                                                          │
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
│  │  Configuration:                                                                                  │   │
│  │  • Repository: git@192.168.0.190:/root/project_nebula.git                                       │   │
│  │  • Branch: master                                                                                │   │
│  │  • Sync Policy: Auto-sync enabled                                                                │   │
│  │  • Sync Interval: Every 3 minutes                                                                │   │
│  │  • Prune: Enabled (removes deleted resources)                                                    │   │
│  │  • Self-heal: Enabled (reconciles drift)                                                        │   │
│  │                                                                                                    │   │
│  │  Monitoring Applications:                                                                        │   │
│  │  ┌─────────────────────────────────────────────────────────────────────────────────────────┐   │   │
│  │  │  App 1: fastapi-production                                                              │   │   │
│  │  │  • Source: manifests/deployment.yaml (3 replicas)                                      │   │   │
│  │  │  • Namespace: production                                                                │   │   │
│  │  │  • Status: Synced & Healthy                                                            │   │   │
│  │  │  • Replicas: 3/3 Running                                                                │   │   │
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
│  │                    FastAPI Deployment (3 Replicas)                                            │   │
│  │                                                                                                    │   │
│  │  ┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐                          │   │
│  │  │   Pod 1         │    │   Pod 2         │    │   Pod 3         │                          │   │
│  │  │                 │    │                 │    │                 │                          │   │
│  │  │ Pod IP:         │    │ Pod IP:         │    │ Pod IP:         │                          │   │
│  │  │ 10.42.0.114     │    │ 10.42.0.115     │    │ 10.42.0.116     │                          │   │
│  │  │                 │    │                 │    │                 │                          │   │
│  │  │ Container:      │    │ Container:      │    │ Container:      │                          │   │
│  │  │ fastapi-app     │    │ fastapi-app     │    │ fastapi-app     │                          │   │
│  │  │ Image:          │    │ Image:          │    │ Image:          │                          │   │
│  │  │ 192.168.0.113:  │    │ 192.168.0.113:  │    │ 192.168.0.113:  │                          │   │
│  │  │ 5000/fastapi-   │    │ 5000/fastapi-   │    │ 5000/fastapi-   │                          │   │
│  │  │ demo:latest     │    │ demo:latest     │    │ demo:latest     │                          │   │
│  │  │                 │    │                 │    │                 │                          │   │
│  │  │ Container Port: │    │ Container Port: │    │ Container Port: │                          │   │
│  │  │ 8000            │    │ 8000            │    │ 8000            │                          │   │
│  │  │                 │    │                 │    │                 │                          │   │
│  │  │ Environment:    │    │ Environment:    │    │ Environment:    │                          │   │
│  │  │ • ENV:          │    │ • ENV:          │    │ • ENV:          │                          │   │
│  │  │   production    │    │   production    │    │   production    │                          │   │
│  │  │ • LOG_LEVEL:    │    │ • LOG_LEVEL:    │    │ • LOG_LEVEL:    │                          │   │
│  │  │   info          │    │   info          │    │   info          │                          │   │
│  │  │ • POD_IP:       │    │ • POD_IP:       │    │ • POD_IP:       │                          │   │
│  │  │   10.42.0.114   │    │   10.42.0.115   │    │   10.42.0.116   │                          │   │
│  │  │ • NODE_IP:      │    │ • NODE_IP:      │    │ • NODE_IP:      │                          │   │
│  │  │   192.168.0.113 │    │   192.168.0.113 │    │   192.168.0.113 │                          │   │
│  │  │ • NODE_NAME:    │    │ • NODE_NAME:    │    │ • NODE_NAME:    │                          │   │
│  │  │   k3s-server    │    │   k3s-server    │    │   k3s-server    │                          │   │
│  │  │                 │    │                 │    │                 │                          │   │
│  │  │ Resources:      │    │ Resources:      │    │ Resources:      │                          │   │
│  │  │ • Requested:    │    │ • Requested:    │    │ • Requested:    │                          │   │
│  │  │   256Mi RAM     │    │   256Mi RAM     │    │   256Mi RAM     │                          │   │
│  │  │ • Limits:       │    │ • Limits:       │    │ • Limits:       │                          │   │
│  │  │   (default)     │    │   (default)     │    │   (default)     │                          │   │
│  │  │                 │    │                 │    │                 │                          │   │
│  │  │ Endpoints:      │    │ Endpoints:      │    │ Endpoints:      │                          │   │
│  │  │ • /docs         │    │ • /docs         │    │ • /docs         │                          │   │
│  │  │ • /health       │    │ • /health       │    │ • /health       │                          │   │
│  │  │ • /metrics      │    │ • /metrics      │    │ • /metrics      │                          │   │
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
│  │                    │                              │                                        │   │
│  │                    │ Traffic Policy:              │                                        │   │
│  │                    │ • Preserve Source IP: false  │                                        │   │
│  │                    │ • Distribution: Cluster-wide │                                        │   │
│  │                    │ • Endpoints: 3/3 ready       │                                        │   │
│  │                    │                              │                                        │   │
│  │                    └──────────────────────────────┘                                        │   │
│  │                                                                                              │   │
│  │  HTTPRoute (Gateway API Routing - Optional)                                                │   │
│  │  ┌──────────────────────────────────────────────────────────┐                             │   │
│  │  │ • Listeners: http://0.0.0.0:80                          │                             │   │
│  │  │ • Backend: fastapi-service:80                           │                             │   │
│  │  │ • Status: Active (backend available)                    │                             │   │
│  │  │ • Routes: /docs, /health, /metrics                      │                             │   │
│  │  │ • Accessed via: 192.168.0.206 (when RBAC fixed)         │                             │   │
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
│  │    - Endpoints in all namespaces with scrape annotations                                         │   │
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
│  │    - node_network_receive_bytes_total                                                           │   │
│  │    - node_network_transmit_bytes_total                                                          │   │
│  │  • Pod Metrics:                                                                                  │   │
│  │    - container_cpu_usage_seconds_total                                                          │   │
│  │    - container_memory_usage_bytes                                                               │   │
│  │    - container_network_transmit_bytes_total                                                     │   │
│  │    - container_network_receive_bytes_total                                                      │   │
│  │  • Service Metrics:                                                                              │   │
│  │    - Custom metrics from /metrics endpoints                                                     │   │
│  │    - HTTP request duration and count                                                            │   │
│  │    - Request success/error rates                                                                │   │
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
│  │                                                                                                    │   │
│  └──────────────────────────────────────────────────────────────────────────────────────────────────┘   │
│                                                                                                              │
└────────────────────────────────────────────────────────────────────────────────────────────────────────────────┘

```

---

## 📋 Network Flow Summary

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

### Data Flow Path 2: Application Deployment (GitLab CI/CD)

```
Developer commits code to git
    │
    ▼ git push to 192.168.0.190:master
┌─────────────────────────────────┐
│  GitLab Repository              │
│  /root/project_nebula.git        │
└─────────────────────────────────┘
    │
    ▼ GitLab CI/CD Trigger (webhook)
┌─────────────────────────────────┐
│  GitLab Runner (build stage)     │
│  Host: 192.168.0.190             │
│                                  │
│  1. Clone repo                   │
│  2. Build Docker image           │
│  3. Tag: 192.168.0.113:5000/...  │
└─────────────────────────────────┘
    │
    ▼ Docker push
┌─────────────────────────────────┐
│  Docker Registry (Private)       │
│  Location: 192.168.0.113:5000    │
│  Image stored in registry        │
└─────────────────────────────────┘
    │
    ▼ SSH Deploy (GitLab CI/CD script)
┌─────────────────────────────────┐
│  SSH to K3s Server               │
│  192.168.0.113:22                │
│  Execute kubectl apply           │
└─────────────────────────────────┘
    │
    ▼ Kubernetes API Server
┌─────────────────────────────────┐
│  K3s Control Plane               │
│  https://192.168.0.113:6443      │
│                                  │
│  Process deployment manifest     │
│  • Create/Update Deployment      │
│  • Create/Update Service         │
│  • Schedule pods on nodes        │
└─────────────────────────────────┘
    │
    ▼ Kubelet (K3s Node)
┌─────────────────────────────────┐
│  Container Runtime               │
│  (Docker/Containerd)             │
│                                  │
│  1. Pull image from 192.168.0... │
│  2. Create containers            │
│  3. Start processes              │
└─────────────────────────────────┘
    │
    ▼ Running Pods
  3 FastAPI replicas
  Ready to serve traffic
```

### Data Flow Path 3: Monitoring Data Collection

```
Prometheus Server (192.168.0.204:9090)
    │
    ├─ Scrape every 15 seconds
    │
    ├─► Kubelet Metrics
    │   └─ 192.168.0.113:10250/metrics
    │      • CPU, Memory, Disk usage
    │      • Pod metrics
    │
    ├─► kube-proxy Metrics
    │   └─ 10.42.0.X:10249/metrics
    │      • Network rules applied
    │      • Service connections
    │
    ├─► FastAPI /metrics endpoint
    │   └─ 10.43.57.102/metrics (via service)
    │      • HTTP requests/responses
    │      • Processing time
    │      • Custom app metrics
    │
    └─► API Server Metrics
        └─ https://10.43.0.1:443/metrics
           • API operations
           • Resource operations
│
▼ Time-series data storage
┌─────────────────────────────────┐
│  Prometheus TSDB                 │
│  Location: /prometheus (volume)  │
│  Data Retention: 30 days         │
│  Queries per second: 1000+       │
└─────────────────────────────────┘
    │
    ▼ Grafana queries data
┌─────────────────────────────────┐
│  Grafana (192.168.0.205:3000)    │
│  • Data source: Prometheus       │
│  • Runs PromQL queries           │
│  • Renders dashboards            │
│  • User views metrics            │
└─────────────────────────────────┘
```

### Data Flow Path 4: GitOps Sync (ArgoCD)

```
ArgoCD Server (192.168.0.202)
    │
    ├─ Watches Git repository
    │  Every 3 minutes
    │  git@192.168.0.190:/root/project_nebula.git
    │
    ├─► Cluster state verification
    │   kubectl get all (continuous)
    │
    └─► Compare: Git vs Cluster
        │
        ├─ Git state: argocd/applications/*.yaml
        ├─ Cluster state: Live Kubernetes objects
        │
        ▼ Drift detected?
        │
        YES: Apply changes via kubectl apply
        NO: Sync already complete
        │
        ▼ Update applications
        └─► fastapi-prod deployment
        └─► prometheus deployment
        └─► grafana deployment
        │
        ▼ Health check
        └─ All pods running? → Synced ✓
           Failed? → OutOfSync ✗
```

---

## 🔗 IP Address Mapping Table

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
| **Prometheus ClusterIP** | Service | 10.43.X.X | 9090 | TCP | Internal metrics discovery |
| **Prometheus LoadBalancer** | Service | 192.168.0.204 | 9090 | TCP | External metrics access |
| **Grafana Pod** | Pod | 10.42.0.X | 3000 | TCP | Dashboard server |
| **Grafana ClusterIP** | Service | 10.43.X.X | 3000 | TCP | Internal dashboard discovery |
| **Grafana LoadBalancer** | Service | 192.168.0.206 | 80 | TCP | External dashboard access |
| **ArgoCD Server Pod** | Pod | 10.42.0.X | 8080 | TCP | GitOps controller |
| **ArgoCD LoadBalancer** | Service | 192.168.0.202 | 80/443 | TCP | External ArgoCD UI access |
| **Envoy Gateway** | Pod | 10.42.0.X | 80/443 | TCP | API gateway (optional) |
| **Envoy Production Gateway** | Service | 192.168.0.205 | 80 | TCP | HTTPRoute gateway external IP |
| **Traefik Load Balancer** | Service | 192.168.0.200 | 80/443 | TCP | Default load balancer |
| **Envoy Gateway System** | Service | 192.168.0.201 | 18000-19001 | TCP | Gateway system controller |
| **MetalLB IP Pool** | Range | 192.168.0.201-250 | - | - | Available external IPs |

---

## 🔐 Access Endpoints Summary

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

## 🏗️ Architecture Layers Explained

### Layer 1: External Network (192.168.0.0/24)
- Developer machines
- GitLab server (Git + CI/CD + Registry)
- K3s master node
- All communicate over LAN via fixed IPs

### Layer 2: MetalLB (Load Balancing)
- Bridges external network and Kubernetes cluster
- Assigns IPs from 192.168.0.201-250 range
- Layer 2 ARP-based protocol for local network
- Automatic failover between pods

### Layer 3: Kubernetes Services
- ClusterIP: Internal service discovery (10.x.x.x)
- LoadBalancer: External access (192.168.0.x)
- Endpoints: Maps services to active pods
- DNS: CoreDNS at 10.43.0.10

### Layer 4: Kubernetes Pods
- Container runtime (Docker/Containerd)
- Pod IP range: 10.42.0.0/24
- Each pod has unique IP, hostname, storage
- Automatic retry and restart on failure

### Layer 5: Application Layer
- FastAPI: REST API on port 8000
- Prometheus: Metrics scraping on port 9090
- Grafana: Dashboard on port 3000
- ArgoCD: GitOps on port 80/443

---

## 🔄 Key Communication Patterns

### 1. **Pod-to-Pod Communication**
- Direct IP communication: 10.42.0.114 → 10.42.0.115:8000
- Network overlay: CNI (Flannel in K3s)
- No additional firewall between pods

### 2. **Pod-to-Service Communication**
- DNS: `fastapi-service.production.svc.cluster.local` → 10.43.57.102
- Service IP resolves via CoreDNS
- iptables rules forward to backend pods

### 3. **External-to-Service Communication**
- MetalLB ARP: 192.168.0.203 → MAC address
- Layer 2 routing to node interface
- Service forwarding to pod

### 4. **Service-to-Service Communication**
- Prometheus → Kubelet: 192.168.0.113:10250
- Prometheus → FastAPI: fastapi-service.production:80 (internal)
- Grafana → Prometheus: prometheus.monitoring:9090 (DNS)

---

## 📈 Scaling & High Availability Features

```
┌────────────────────────────────────────────────────────────┐
│           DEPLOYMENT SCALABILITY                          │
├────────────────────────────────────────────────────────────┤
│                                                            │
│  Horizontal Pod Autoscaling (can be enabled):             │
│  • Monitor: CPU, Memory, Custom metrics                   │
│  • Min replicas: 3                                         │
│  • Max replicas: 10                                        │
│  • Scale-up trigger: >70% resource utilization            │
│  • Scale-down: <30% (after cooldown)                      │
│                                                            │
│  Rolling Updates:                                          │
│  • Strategy: RollingUpdate                                │
│  • maxSurge: 1 (1 extra pod during update)               │
│  • maxUnavailable: 1 (1 pod can be down)                 │
│  • Ensures 2/3 pods always available                      │
│                                                            │
│  Load Distribution:                                        │
│  • Algorithm: Round-robin (default)                       │
│  • Session affinity: ClientIP (3 hours)                   │
│  • Endpoint randomization: Enabled                        │
│                                                            │
│  Monitoring & Alerts:                                     │
│  • Pod CPU > 80%: Scale up                                │
│  • Pod Memory > 90%: Alert + Possible scale up           │
│  • Pod Restart Count: Alert if > 5 in 1 hour             │
│  • Deployment Replicas: Alert if < desired                │
│                                                            │
└────────────────────────────────────────────────────────────┘
```

---

## 🔒 Network Security Overview

```
┌────────────────────────────────────────────────────────────┐
│              NETWORK SECURITY LAYERS                       │
├────────────────────────────────────────────────────────────┤
│                                                            │
│  1. External Network Isolation                            │
│     • MetalLB IP pool: 192.168.0.201-250                 │
│     • Only these IPs published externally                 │
│     • Other services remain internal (10.x.x.x)          │
│                                                            │
│  2. Service Type Boundaries                               │
│     • ClusterIP: Internal only (10.43.57.102)            │
│     • LoadBalancer: External (192.168.0.203)             │
│     • No external access to ClusterIP services           │
│                                                            │
│  3. Namespace Isolation (can be enhanced)                 │
│     • Production: Isolated from other namespaces         │
│     • Monitoring: Separate metrics infrastructure        │
│     • ArgoCD: Separate control plane                     │
│                                                            │
│  4. Port Exposure                                         │
│     • Only service ports exposed (80, 3000, 9090)        │
│     • Container ports (8000) internal only               │
│     • Kubelet API (10250): Metrics only                  │
│                                                            │
│  5. DNS Resolution                                        │
│     • Internal DNS: 10.43.0.10 (CoreDNS)                 │
│     • FQDN: service.namespace.svc.cluster.local          │
│     • External DNS: Not configured (local network only)  │
│                                                            │
│  Recommended Enhancements:                                │
│  • NetworkPolicies: Restrict pod-to-pod communication    │
│  • RBAC: Fine-grained access control                     │
│  • TLS: Encrypted communication (istio/service mesh)     │
│  • WAF: Web Application Firewall for API                 │
│                                                            │
└────────────────────────────────────────────────────────────┘
```

---

## ✅ Verification Commands

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

# Check ArgoCD application status
kubectl get applications -n argocd

# View running Prometheus scrape jobs
kubectl logs -n monitoring <prometheus-pod> | grep "scrape_configs"

# Monitor traffic in real-time
kubectl top nodes
kubectl top pods -n production

```

---

This comprehensive diagram shows:
- ✅ All IP addresses with their roles
- ✅ Complete data flow paths
- ✅ Service communication patterns
- ✅ Load balancing and routing
- ✅ Monitoring data collection
- ✅ GitOps deployment pipeline
- ✅ Network security boundaries
- ✅ Scaling capabilities
