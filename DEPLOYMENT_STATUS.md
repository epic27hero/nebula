# PROJECT NEBULA - DEPLOYMENT STATUS

## ✅ ALL SERVICES DEPLOYED & ACCESSIBLE

### Service Access Points

| Service | IP Address | Port | URL | Status |
|---------|------------|------|-----|--------|
| **ArgoCD** | 192.168.0.202 | 80 | http://192.168.0.202 | ✅ RUNNING |
| **FastAPI** | 192.168.0.203 | 80 | http://192.168.0.203 | ✅ RUNNING |
| **Grafana** | 192.168.0.204 | 80 | http://192.168.0.204 | ✅ RUNNING |
| **Prometheus** | 192.168.0.205 | 80 | http://192.168.0.205 | ✅ RUNNING |

### Login Credentials

| Service | User | Password |
|---------|------|----------|
| ArgoCD | admin | Check `argocd-password.txt` |
| Grafana | admin | admin123 |
| Prometheus | - | No auth (public) |
| FastAPI | - | No auth (public) |

---

## Architecture Answer

### Question: Should Prometheus & Grafana be INSIDE or OUTSIDE ArgoCD?

**Answer: ✅ OUTSIDE (but managed by ArgoCD)**

They are:
- **Outside** the ArgoCD namespace
- **Inside** the Kubernetes cluster (in `monitoring` namespace)
- **Managed by** ArgoCD (deployed via application manifests)

```
KUBERNETES CLUSTER
├─ argocd namespace (ArgoCD control plane)
│  └─ ArgoCD Server
├─ production namespace (Applications deployed here)
│  └─ FastAPI (3 pods)
└─ monitoring namespace (Monitoring stack here)
   ├─ Prometheus (deployed by ArgoCD)
   └─ Grafana (deployed by ArgoCD)
```

---

## Ports & Networking

✅ **All services use port 80 (HTTP)**
- No additional ports needed for access
- MetalLB assigns IPs from pool `192.168.0.200-250`
- All services are LoadBalancer type

| Service | Internal Port | External Port | IP |
|---------|---|---|---|
| ArgoCD | 8080 | 80 | 192.168.0.202 |
| FastAPI | 8000 | 80 | 192.168.0.203 |
| Grafana | 3000 | 80 | 192.168.0.204 |
| Prometheus | 9090 | 80 | 192.168.0.205 |

---

## Data Flow

```
FastAPI Pods
    ↓
  GET /metrics (http_requests_total)
    ↓
Prometheus (scrapes every 15s)
    ↓
Grafana (queries Prometheus)
    ↓
Dashboard visualization
```

---

## FastAPI Endpoints

- `GET http://192.168.0.203/` - Root endpoint (returns pod info)
- `GET http://192.168.0.203/health` - Health check
- `GET http://192.168.0.203/metrics` - Prometheus metrics

---

## Kubernetes Commands

### Monitor Applications
```bash
kubectl -n argocd get applications
kubectl -n argocd get application prometheus -o yaml
kubectl -n argocd get application grafana -o yaml
```

### Monitor Pods
```bash
kubectl -n production get pods -w
kubectl -n monitoring get pods -w
```

### View Logs
```bash
kubectl -n argocd logs -f deployment/argocd-server
kubectl -n production logs -f deployment/fastapi-app
kubectl -n monitoring logs -f deployment/prometheus-kube-prometheus-operator
kubectl -n monitoring logs -f deployment/grafana
```

### Port Forward
```bash
# Access services locally
kubectl -n production port-forward svc/fastapi-app 8000:80
kubectl -n monitoring port-forward svc/prometheus 9090:80
kubectl -n monitoring port-forward svc/grafana 3000:80
kubectl -n argocd port-forward svc/argocd-server 8080:443
```

---

## Verification Checklist

- [x] Kubernetes cluster is running
- [x] MetalLB is assigning IPs
- [x] ArgoCD is deployed
- [x] FastAPI app is deployed (3 replicas)
- [x] Prometheus is deployed
- [x] Grafana is deployed
- [x] All services have LoadBalancer IPs
- [x] All services are accessible on port 80
- [x] FastAPI /metrics endpoint is working
- [x] Prometheus is scraping metrics
- [x] Grafana has Prometheus datasource

---

## Next Steps

1. **Access ArgoCD**
   - Open http://192.168.0.202
   - Login with admin credentials
   - Verify all applications are synced

2. **Access Grafana**
   - Open http://192.168.0.204
   - Login with admin/admin123
   - View Kubernetes metrics dashboards

3. **Test FastAPI Metrics**
   ```bash
   curl http://192.168.0.203/metrics
   ```

4. **Check Prometheus Targets**
   - Open http://192.168.0.205/targets
   - Verify `fastapi-app` job is healthy

5. **Test the GitOps Pipeline**
   - Push code to master branch
   - GitLab CI/CD builds image
   - ArgoCD auto-syncs deployment
   - New image deployed to pods

---

## Troubleshooting

### Service not accessible?
```bash
kubectl get svc -A | grep LoadBalancer
# Verify service has EXTERNAL-IP assigned
```

### Pod not starting?
```bash
kubectl get pods -n monitoring -o wide
kubectl describe pod <pod-name> -n monitoring
```

### Prometheus not scraping?
```bash
# Check targets
curl http://192.168.0.205/api/v1/targets
```

### Grafana dashboards empty?
```bash
# Verify datasource is connected
# Settings → Data Sources → Prometheus
# Test connection
```

---

## Status Summary

✅ **All 4 services running and accessible**
✅ **Ports configured correctly (all use :80)**
✅ **MetalLB IPs assigned**
✅ **GitOps workflow active**
✅ **Monitoring stack operational**

**System is ready for production use!**
