# Infrastructure Access Points - Project Nebula

## ✅ All Services Now Accessible via LoadBalancer IPs

### 📊 Monitoring Stack
- **Prometheus**: http://192.168.0.204:9090
- **Grafana**: http://192.168.0.205:3000
  - Default Credentials: `admin / grafana`

### 🚀 Application
- **FastAPI**: http://192.168.0.203
- **Swagger UI**: http://192.168.0.203/docs
- **Health Check**: http://192.168.0.203/health
- **Metrics**: http://192.168.0.203/metrics

### 🌐 Infrastructure Management
- **ArgoCD**: http://192.168.0.202
  - Username: `admin`
  - Password: Check `argocd-password.txt`

### 🔍 Status Check Commands
Run status checks anytime to verify all services:
```bash
# Quick status (2-3 seconds)
./scripts/quick-status.sh

# Complete status (10-15 seconds)
./scripts/check-all-status.sh

# Health metrics (15-25 seconds)
./scripts/health-metrics.sh

# Interactive menu
./scripts/run-status-check.sh
```

## 📝 Services Deployed

| Service | Type | IP Address | Port | Status |
|---------|------|-----------|------|--------|
| FastAPI | LoadBalancer | 192.168.0.203 | 80 | ✅ Running |
| Prometheus | LoadBalancer | 192.168.0.204 | 9090 | ✅ Running |
| Grafana | LoadBalancer | 192.168.0.205 | 3000 | ✅ Running |
| ArgoCD | LoadBalancer | 192.168.0.202 | 80 | ✅ Running |
| MetalLB Pool | - | 192.168.0.201-250 | - | ✅ Available |

## 🔧 What Was Fixed

1. **FastAPI Service**
   - Created ClusterIP service for HTTPRoute backend
   - Created LoadBalancer service for external access
   - Now accessible at http://192.168.0.203

2. **Prometheus**
   - Created LoadBalancer service
   - Now accessible at http://192.168.0.204:9090

3. **Grafana**
   - Created LoadBalancer service
   - Now accessible at http://192.168.0.205:3000
   - Default credentials: admin/grafana

4. **Scripts Updated**
   - `check-all-status.sh` - Shows all service IPs and access points
   - `quick-status.sh` - Quick 2-3 second status check with IPs
   - `health-metrics.sh` - Health metrics with LoadBalancer IPs

## 📡 Network Configuration

- **MetalLB IP Pool**: 192.168.0.201 - 192.168.0.250
- **Auto-assign**: Enabled
- **Services using MetalLB**:
  - FastAPI LoadBalancer: 192.168.0.203
  - Prometheus LoadBalancer: 192.168.0.204
  - Grafana LoadBalancer: 192.168.0.205
  - ArgoCD Server: 192.168.0.202 (locked)
  - Envoy Gateway: 192.168.0.206 (for Gateway API)

## 🚨 Gateway API Note

- The Gateway API is deployed but experiencing RBAC permission issues
- This doesn't affect FastAPI access - use the LoadBalancer IP (192.168.0.203) instead
- Gateway would allow routing through Envoy Gateway if RBAC were fully configured

## ✨ Ready for Use

All infrastructure is now fully operational and accessible:
- ✅ Prometheus collecting metrics
- ✅ Grafana ready for dashboards
- ✅ FastAPI running with 3 replicas
- ✅ ArgoCD managing applications
- ✅ MetalLB assigning external IPs
- ✅ All services accessible via their assigned IPs
