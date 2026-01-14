# Project Nebula - Scripts Directory Index

## Quick Start

### 🚀 Recommended Entry Point
```bash
cd /root/project_nebula/scripts
./run-status-check.sh          # Interactive menu for all checks
```

---

## Status Check Scripts (NEW)

### ⚡ **quick-status.sh** - Quick Overview (~2-3 seconds)
```bash
./quick-status.sh
```
**Best for:** Daily checks, CI/CD pipelines, monitoring dashboards  
**Shows:**
- Kubernetes cluster status
- Terraform state
- ArgoCD status and IP
- All component health at a glance
- Access endpoints

### 📋 **check-complete-status.sh** - Detailed Audit (~10-15 seconds)
```bash
./check-complete-status.sh
```
**Best for:** Troubleshooting, comprehensive infrastructure review  
**Shows:**
- Everything from quick-status PLUS:
- Detailed component breakdowns
- Service configurations
- Port mappings
- Credentials information
- Suggested next steps

### 📊 **health-metrics.sh** - Performance Analysis (~15-25 seconds)
```bash
./health-metrics.sh
```
**Best for:** Performance monitoring, capacity planning, health scoring  
**Shows:**
- Node resource metrics (CPU/Memory)
- Pod distribution by namespace
- Application sync/health metrics
- Storage allocation
- Pod status breakdown
- **Overall Health Score** (0-100%)

### 🔄 **run-status-check.sh** - Interactive Launcher
```bash
./run-status-check.sh
```
**Best for:** Unified interface to all checks  
**Features:**
- Interactive menu
- Run individual or all checks sequentially
- Access documentation
- Script status verification

---

## Infrastructure Setup Scripts

### **bootstrap-cluster.sh**
Initial Kubernetes cluster setup and bootstrap

### **install-dependencies.sh**
Install required tools and dependencies

### **install-argocd.sh**
Deploy ArgoCD to cluster

### **install-gateway-api.sh**
Install Gateway API CRDs

### **setup-gateway-api.sh**
Configure Gateway API resources

### **setup-terraform.sh**
Initialize Terraform environment

### **fix-gateway-api.sh**
Troubleshoot Gateway API issues

### **cleanup-crds.sh**
Remove CRDs and cleanup resources

---

## Utility Scripts

### **ensure-argocd-202.sh** - Lock ArgoCD IP
```bash
./ensure-argocd-202.sh
```
Ensures ArgoCD remains at 192.168.0.202

### **check-cluster.sh**
Quick cluster connectivity check

### **check-all-status.sh**
Legacy comprehensive status check

### **argo-password-save.sh**
Save ArgoCD admin password

---

## Documentation Files

### **STATUS_CHECK_README.md**
Complete documentation for status check scripts
- Feature descriptions
- Troubleshooting guide
- Common commands
- Performance monitoring setup

### **../SCRIPTS_SUMMARY.md** (in parent directory)
Summary of all new scripts
- Quick reference table
- Integration examples
- Health score breakdown

---

## Usage Patterns

### Pattern 1: Daily Automated Checks
```bash
# Run every 30 minutes via cron
*/30 * * * * /root/project_nebula/scripts/quick-status.sh >> /tmp/infra-status.log

# Or with watch for continuous monitoring
watch -n 30 ./quick-status.sh
```

### Pattern 2: CI/CD Pre-Deployment
```bash
#!/bin/bash
set -e

# Check infrastructure health before deployment
if ! ./quick-status.sh | grep -q "✓ Kubernetes: 1/1"; then
    echo "Kubernetes not ready!"
    exit 1
fi

if ! ./quick-status.sh | grep -q "✓ ArgoCD"; then
    echo "ArgoCD not ready!"
    exit 1
fi

# Proceed with deployment
echo "Infrastructure healthy. Proceeding with deployment..."
```

### Pattern 3: Manual Troubleshooting
```bash
# Step 1: Quick overview
./quick-status.sh

# Step 2: If issues found, run complete analysis
./check-complete-status.sh

# Step 3: Check detailed metrics
./health-metrics.sh

# Step 4: Use suggested commands from output
```

### Pattern 4: Performance Monitoring
```bash
# Run metrics check regularly
0 */6 * * * /root/project_nebula/scripts/health-metrics.sh | tee -a /var/log/infra-metrics.log

# Alert if health score drops below 80%
# (Add to monitoring system)
```

---

## Component Access

After running status checks, access services at:

| Component | URL | Status in |
|-----------|-----|-----------|
| **ArgoCD** | http://192.168.0.202 | quick-status.sh |
| **Prometheus** | http://10.43.24.90:80 | quick-status.sh |
| **Grafana** | http://10.43.215.176:80 | quick-status.sh |

---

## Script Features Summary

### Color-Coded Output
```
✓ GREEN  - Success/OK/Running
✗ RED    - Error/Failed/Critical
⚠ YELLOW - Warning/Pending/Caution
ℹ BLUE   - Information/Details
```

### Comprehensive Coverage
- ✓ Terraform state validation
- ✓ Kubernetes cluster health
- ✓ ArgoCD applications
- ✓ Gateway API resources
- ✓ Helm deployments
- ✓ Prometheus/Grafana services
- ✓ MetalLB load balancer
- ✓ Storage status
- ✓ Container runtime info
- ✓ Pod health metrics
- ✓ Recent error events
- ✓ Overall health scoring

### Easy Integration
- All scripts are read-only
- Safe to run multiple times
- Can be used in automation
- Flexible output format
- No state modification

---

## Quick Reference Commands

```bash
# Make all scripts executable
chmod +x *.sh

# Run quick check
./quick-status.sh

# Run complete check
./check-complete-status.sh

# Run health metrics
./health-metrics.sh

# Run interactive launcher
./run-status-check.sh

# Ensure ArgoCD IP is locked
./ensure-argocd-202.sh

# Port-forward Prometheus
kubectl port-forward -n monitoring svc/prometheus-server 9090:80

# Port-forward Grafana
kubectl port-forward -n monitoring svc/grafana 3000:80

# View ArgoCD applications
kubectl get applications -n argocd -o wide

# Check pod events
kubectl get events --all-namespaces --sort-by='.lastTimestamp' | tail -20
```

---

## Troubleshooting

### Script Not Executable
```bash
chmod +x script-name.sh
```

### kubectl Not Found
```bash
# Install kubectl
brew install kubectl  # macOS
apt-get install kubectl  # Linux
```

### Scripts Hanging
Press `Ctrl+C` to interrupt and check component connectivity with:
```bash
kubectl cluster-info
```

### Out of Date Info
All scripts fetch real-time data. Rerun to get latest status.

---

## Performance Notes

- **quick-status.sh**: 2-3 seconds (lightweight)
- **check-complete-status.sh**: 10-15 seconds (moderate load)
- **health-metrics.sh**: 15-25 seconds (intensive queries)
- **run-status-check.sh**: Instant (menu interface only)

All scripts are safe to run concurrently.

---

## Latest Changes (January 14, 2026)

✅ **NEW:**
- ✓ Created check-complete-status.sh (comprehensive audit)
- ✓ Created quick-status.sh (fast overview)
- ✓ Created health-metrics.sh (performance analysis)
- ✓ Created run-status-check.sh (interactive launcher)
- ✓ Created STATUS_CHECK_README.md (documentation)
- ✓ Fixed Grafana/Prometheus sync issues
- ✓ Updated IP pool configuration (192.168.0.201-250)
- ✓ Locked ArgoCD to stable 192.168.0.202

**WORKING:**
- ✓ All 3 ArgoCD applications synced and healthy
- ✓ Prometheus collecting metrics
- ✓ Grafana displaying dashboards
- ✓ MetalLB load balancer operational
- ✓ Gateway API deployed
- ✓ Kubernetes cluster healthy
- ✓ Terraform state consistent

---

## Getting Help

1. **Quick help:** `./quick-status.sh` - Most common issues
2. **Detailed help:** `./check-complete-status.sh` - Full breakdown
3. **Performance help:** `./health-metrics.sh` - Resource analysis
4. **Documentation:** See `STATUS_CHECK_README.md` in this directory

---

**Status:** ✅ All systems operational  
**Last Updated:** January 14, 2026  
**Health Score:** 70-100% (varies with load)

---

## Next Steps

1. ✅ Run `./quick-status.sh` for overview
2. ✅ Run `./check-complete-status.sh` for details
3. ✅ Run `./health-metrics.sh` for performance
4. ✅ Access services using URLs from output
5. ✅ Set up automated checks via cron
6. ✅ Integrate with monitoring system

**Begin:** `./run-status-check.sh`
