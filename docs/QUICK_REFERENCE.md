# 🚀 QUICK REFERENCE - PROJECT NEBULA

## 🌐 IMMEDIATE ACCESS URLs

| Service | URL | Credentials |
|---------|-----|------------|
| **ArgoCD** | http://192.168.0.200 | admin / q19i1gL3PGSz2ZuL |
| **FastAPI App** | Waiting for Gateway IP | N/A |
| **Grafana** | Waiting (5-10 mins) | admin / prom-operator |
| **Prometheus** | Waiting (5-10 mins) | N/A |

---

## ⚡ FASTEST STATUS CHECK

```bash
# Run comprehensive status check
./scripts/check-all-status.sh

# Watch live updates
kubectl get applications -n argocd -w
kubectl get pods -n production -w
```

---

## 🎯 COMMON TASKS

### Get Gateway IP (FastAPI Access)
```bash
kubectl get gateway prod-gateway -n production \
  -o jsonpath='{.status.addresses[0].value}'
```

### Test FastAPI Application
```bash
# Port-forward method (if Gateway not ready)
kubectl port-forward -n production svc/fastapi-app 8000:80
# Then: http://localhost:8000/docs
```

### Get Grafana Access
```bash
kubectl get svc -n monitoring prometheus-community-grafana \
  -o jsonpath='{.status.loadBalancer.ingress[0].ip}'
```

### Get Prometheus Access
```bash
kubectl get svc -n monitoring prometheus-community-kube-prom-prometheus \
  -o jsonpath='{.status.loadBalancer.ingress[0].ip}'
```

---

## 📝 DEPLOYMENT CYCLE

```
Your Code Changes
      ↓
    git push origin master
      ↓
GitLab CI/CD (auto)
  • Build Docker image
  • Push to registry
      ↓
ArgoCD Detects (auto)
  • Syncs latest Helm chart
  • Updates deployment
      ↓
Kubernetes Rolling Update
  • Pulls new image
  • Starts 3 pods
      ↓
✅ Done in ~5 minutes
```

---

## 🔍 TROUBLESHOOTING

| Issue | Command |
|-------|---------|
| App not syncing | `kubectl describe application fastapi-prod -n argocd` |
| FastAPI pod errors | `kubectl logs -n production -l app=fastapi-app` |
| Gateway not assigned IP | `kubectl get gateway prod-gateway -n production` |
| Check all pods | `kubectl get all -n production` |

---

## 📊 INFRASTRUCTURE

```
┌─────────────────────────────────────────┐
│  KUBERNETES (192.168.0.113)             │
├─────────────────────────────────────────┤
│                                         │
│  🔹 ArgoCD (192.168.0.200:80)          │
│     └─ Manages: fastapi-prod, grafana, │
│        prometheus                       │
│                                         │
│  🔹 Production Namespace               │
│     └─ 3x FastAPI pods running         │
│     └─ MetalLB service IP pending      │
│     └─ Envoy Gateway (Waiting for IP)  │
│                                         │
│  🔹 Monitoring Namespace               │
│     └─ Prometheus (deploying)          │
│     └─ Grafana (deploying)             │
│                                         │
│  🔹 MetalLB (LoadBalancer)             │
│     └─ IP Pool: 192.168.0.200-250      │
│                                         │
└─────────────────────────────────────────┘
```

---

## 🎓 KEY FILES

| File | Purpose |
|------|---------|
| `src/main.py` | Your FastAPI application |
| `helm/fastapi-app/` | Helm chart for deployment |
| `argocd/applications/` | ArgoCD application configs |
| `.gitlab-ci.yml` | CI/CD pipeline definition |
| `Dockerfile` | Container image definition |
| `terraform/` | Infrastructure as Code |

---

## ⚙️ SERVICES ARCHITECTURE

```
GitLab Server (192.168.0.190)
    ↑ (You push code here)
    ↓ CI/CD Triggered
    
Docker Registry (192.168.0.113:5000)
    ↑ (Images pushed here)
    ↓ K8s pulls images from here
    
Kubernetes Cluster (192.168.0.113)
    ├─ ArgoCD → Syncs from Git
    ├─ FastAPI → Helm deployed
    ├─ MetalLB → Assigns IPs (192.168.0.200+)
    ├─ Prometheus → Collects metrics
    └─ Grafana → Visualizes metrics
```

---

## 📞 GETTING HELP

1. **Check Logs**: `kubectl logs <pod> -n <namespace>`
2. **Describe Resource**: `kubectl describe <resource> -n <namespace>`
3. **Check Events**: `kubectl get events -n <namespace>`
4. **Full Status**: `./scripts/check-all-status.sh`
5. **ArgoCD Events**: Check ArgoCD UI → Application details

---

**Last Updated**: Jan 14, 2026
**Status**: ✅ Production Ready (Monitoring Deploying)
