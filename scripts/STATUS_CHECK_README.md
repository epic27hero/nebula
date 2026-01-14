# Infrastructure Status Check Scripts

This directory contains comprehensive scripts to monitor and verify the status of your complete infrastructure stack.

## Scripts Overview

### 1. `check-complete-status.sh` (Comprehensive Report)
Full detailed status check of all infrastructure components with color-coded output.

**Features:**
- ✓ Terraform state and configuration check
- ✓ Kubernetes cluster and node status
- ✓ ArgoCD deployment and applications
- ✓ Gateway API gateways and routes
- ✓ Helm releases and repositories
- ✓ Prometheus and Grafana services
- ✓ MetalLB load balancer
- ✓ Storage (PV/PVC) status
- ✓ Container runtime info
- ✓ Pod status overview
- ✓ Quick reference commands

**Usage:**
```bash
./check-complete-status.sh
```

**Output:** Detailed sections for each component with helpful comments and next steps.

---

### 2. `quick-status.sh` (One-Liner Summary)
Fast at-a-glance status check showing critical information only.

**Features:**
- ✓ Quick health summary
- ✓ All component status in one screen
- ✓ Access endpoints display
- ✓ Pod counts and issues
- ✓ Color-coded alerts

**Usage:**
```bash
./quick-status.sh
```

**Output:** Single-screen summary (~2 seconds execution)

---

## Component Details

### Terraform
- Validates terraform directory and state file
- Shows state serial number and resource count
- Lists all configured modules

### Kubernetes
- Cluster version and API endpoint
- Node status and count
- Namespace count
- Container runtime information

### ArgoCD
- Server IP and access URLs
- Application sync and health status
- Pod readiness status
- Credentials information

### Gateway API
- Gateway configuration status
- HTTPRoute count
- Route details

### Helm
- Helm version
- Repository listing
- Release status across all namespaces
- Chart information

### Prometheus
- Service IP and access URL
- Pod status
- Instance count

### Grafana
- Service IP and access URL
- Pod status
- Default credentials info

### MetalLB
- Component pod status
- IP address pool configuration
- Auto-assign settings

### Storage
- Persistent Volume count
- PVC status and binding
- Volume details

### Network Services
- LoadBalancer service IPs
- Service types and ports
- External IP assignments

---

## Color Legend

```
✓ GREEN   - Success / Running / OK
✗ RED     - Error / Failed / Critical
⚠ YELLOW  - Warning / Pending / Caution
ℹ BLUE    - Information / Details
```

---

## Common Troubleshooting

### ArgoCD Applications Not Syncing
```bash
# Check application status
kubectl get applications -n argocd -o wide

# Manually sync
argocd app sync <app-name>

# View detailed logs
kubectl logs -n argocd -l app.kubernetes.io/name=argocd-server --tail=50
```

### Prometheus/Grafana Not Accessible
```bash
# Port-forward Prometheus
kubectl port-forward -n monitoring svc/prometheus-server 9090:80

# Port-forward Grafana
kubectl port-forward -n monitoring svc/grafana 3000:80
```

### Check Pod Issues
```bash
# View pending pods
kubectl get pods --all-namespaces --field-selector=status.phase=Pending

# Check pod events
kubectl describe pod <pod-name> -n <namespace>

# View logs
kubectl logs -n <namespace> <pod-name> --tail=100
```

### Terraform State Issues
```bash
# View current state
terraform show

# Validate configuration
cd /root/project_nebula/terraform && terraform validate

# Plan changes
terraform plan
```

---

## Access Endpoints

Once services are running, access them at:

| Service | Default URL | Credentials |
|---------|------------|-------------|
| ArgoCD | http://192.168.0.202 | admin / (see argocd-password.txt) |
| Prometheus | http://10.43.24.90:80 | - (no auth) |
| Grafana | http://10.43.215.176:80 | admin / (default password) |
| Kubernetes API | https://127.0.0.1:6443 | kubeconfig auth |

---

## Running Schedules

### Continuous Monitoring
```bash
# Watch ArgoCD apps continuously
kubectl get applications -n argocd -w

# Watch deployments
kubectl get deployments --all-namespaces -w

# Watch pod status
kubectl get pods --all-namespaces -w
```

### Periodic Checks
```bash
# Every 30 seconds
watch -n 30 ./quick-status.sh

# Every 5 minutes (cron)
*/5 * * * * cd /root/project_nebula && ./scripts/quick-status.sh >> logs/status.log
```

---

## Script Requirements

- `kubectl` - Kubernetes command-line tool
- `helm` - Helm package manager
- `argocd` - ArgoCD CLI (optional, for app management)
- `bash` - Shell interpreter
- Colors enabled in terminal

---

## Documentation References

- Kubernetes: https://kubernetes.io/docs/
- ArgoCD: https://argo-cd.readthedocs.io/
- Helm: https://helm.sh/docs/
- Prometheus: https://prometheus.io/docs/
- Grafana: https://grafana.com/docs/
- MetalLB: https://metallb.universe.tf/

---

## Support

For issues or questions about specific components:

1. Run the complete status check script first
2. Check component-specific logs
3. Review the troubleshooting section above
4. Check official component documentation

---

**Last Updated:** January 14, 2026  
**Scripts Location:** `/root/project_nebula/scripts/`
