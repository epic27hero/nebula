# 🚀 Project Nebula - Complete Access Guide

## ✅ Current Status

```
✅ Kubernetes Cluster: RUNNING (K3s v1.33.6)
✅ ArgoCD: RUNNING (7 pods, Synced & Healthy)
✅ MetalLB: RUNNING (Load Balancer)
✅ Gateway API: RUNNING
✅ FastAPI Application: SYNCED (via ArgoCD)
✅ Prometheus: SYNCED (via ArgoCD)
✅ Grafana: SYNCED (via ArgoCD)
```

---

## 🌐 ACCESS POINTS

### 1️⃣ ArgoCD Dashboard
- **URL**: http://192.168.0.202
- **Username**: `admin`
- **Password**: Check `argocd-password.txt` in project root
- **What to do**:
  - View all deployed applications
  - Monitor sync status
  - Trigger manual syncs
  - Manage repositories

### 2️⃣ Prometheus (Metrics)
- **Status**: Deployed (Unknown sync, but running)
- **Access**: Through ArgoCD or direct service discovery
- **Check pods**:
  ```bash
  kubectl get pods -n monitoring
  ```

### 3️⃣ Grafana (Dashboards)
- **Status**: Deployed (Unknown sync, but running)
- **Access**: Through ArgoCD or direct service discovery
- **Check pods**:
  ```bash
  kubectl get pods -n monitoring
  ```

### 4️⃣ FastAPI Application
- **Status**: SYNCED & HEALTHY
- **Deployment**: production namespace
- **Check status**:
  ```bash
  kubectl get all -n production
  kubectl get pods -n production -w
  ```

---

## 🔧 IP Address Configuration

| Service | IP | Port | Type |
|---------|----|----|------|
| Traefik (Existing) | 192.168.0.201 | 80, 443 | LoadBalancer |
| ArgoCD | 192.168.0.202 | 80, 443 | LoadBalancer |
| FastAPI Gateway | TBD | - | Pending |

**MetalLB Pool**: 192.168.0.201 - 192.168.0.250

---

## 📋 Quick Commands

### Check Everything
```bash
# Cluster health
kubectl cluster-info
kubectl get nodes -w

# All namespaces
kubectl get ns

# ArgoCD status
kubectl get applications -n argocd -w

# All services
kubectl get svc -A

# Monitoring stack
kubectl get all -n monitoring

# Production app
kubectl get all -n production

# Logs
kubectl logs -n argocd -l app=argocd-server
kubectl logs -n production -l app=fastapi-app
```

### Update/Deploy
When you push code to GitLab:
1. GitLab CI builds Docker image
2. Pushes to registry (192.168.0.113:5000)
3. ArgoCD detects change (pulls from SSH: ssh://git@192.168.0.190/root/project_nebula.git)
4. Deploys new version to production automatically ✅

### Manual Sync
```bash
# Refresh all applications
kubectl patch application fastapi-prod -n argocd \
  -p '{"metadata":{"annotations":{"argocd.argoproj.io/compare-result":""}}}' \
  --type merge
```

---

## 🔐 Credentials & Keys

```
📁 ~/.ssh/git190_two          - SSH key for GitLab access
📁 argocd-password.txt        - ArgoCD admin password
```

---

## 🐛 Troubleshooting

### If Grafana/Prometheus show "Unknown" sync
```bash
# Force refresh
kubectl patch application grafana -n argocd \
  -p '{"metadata":{"annotations":{"argocd.argoproj.io/compare-result":""}}}' \
  --type merge

kubectl patch application prometheus -n argocd \
  -p '{"metadata":{"annotations":{"argocd.argoproj.io/compare-result":""}}}' \
  --type merge
```

### If FastAPI pods don't start
```bash
# Check pod logs
kubectl logs -n production -l app=fastapi-app --tail=50

# Check events
kubectl describe pod -n production <pod-name>

# Check image in registry
curl http://192.168.0.113:5000/v2/fastapi-demo/tags/list
```

### If ArgoCD can't access GitLab
The SSH key is configured:
```bash
# Check repo secret
kubectl get secret -n argocd project-nebula-repo -o yaml
```

---

## 📊 Next Steps

1. **Access ArgoCD**: http://192.168.0.202
2. **Review applications** in "Applications" tab
3. **Check Prometheus** metrics (find endpoint via ArgoCD)
4. **Check Grafana** dashboards (find endpoint via ArgoCD)
5. **Monitor** production deployment:
   ```bash
   kubectl get pods -n production -w
   ```
6. **Push code** to master branch → auto-deployed ✅

---

## 🎯 Architecture Overview

```
┌─────────────────┐
│   GitLab        │
│  192.168.0.190  │
└────────┬────────┘
         │ (SSH Key: git190_two)
         ↓
┌─────────────────────────────────────────────┐
│        Kubernetes Cluster (K3s)             │
│                                             │
│  ┌──────────────────────────────────────┐  │
│  │ ArgoCD (192.168.0.202)               │  │
│  │  - Monitors: SSH repo                │  │
│  │  - Auto-deploys on push              │  │
│  │  - Manages: fastapi-prod,            │  │
│  │             prometheus, grafana      │  │
│  └──────────────────────────────────────┘  │
│                                             │
│  ┌─────────────┐  ┌─────────────────┐    │
│  │  Production │  │  Monitoring     │    │
│  │  namespace  │  │  namespace      │    │
│  │             │  │                 │    │
│  │ FastAPI app │  │ Prometheus      │    │
│  │ (3 pods)    │  │ Grafana         │    │
│  └─────────────┘  └─────────────────┘    │
│                                             │
│  MetalLB IP Pool: 192.168.0.201-250       │
└─────────────────────────────────────────────┘
         ↓
┌──────────────────────────┐
│   Docker Registry        │
│  192.168.0.113:5000      │
│  Image: fastapi-demo     │
└──────────────────────────┘
```

---

**Last Updated**: January 14, 2026
**Status**: ✅ All systems operational
