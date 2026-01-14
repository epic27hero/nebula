# 🎯 Infrastructure Status Check - Quick Reference Card

## 🚀 Start Here

```bash
cd /root/project_nebula/scripts
./run-status-check.sh    # Interactive menu (recommended)
```

---

## ⚡ Three Main Scripts

### 1. Quick Check (~2-3 seconds) - USE FOR DAILY MONITORING
```bash
./quick-status.sh
# Shows: Kubernetes, Terraform, ArgoCD, Helm, Services, IPs
# Best for: Daily checks, CI/CD, monitoring dashboards
```

### 2. Complete Check (~10-15 seconds) - USE FOR TROUBLESHOOTING
```bash
./check-complete-status.sh
# Shows: Everything from quick-check + detailed breakdown
# Best for: Diagnostics, detailed audits, debugging
```

### 3. Health Metrics (~15-25 seconds) - USE FOR PERFORMANCE
```bash
./health-metrics.sh
# Shows: Resource usage, pod distribution, health score
# Best for: Capacity planning, performance analysis
```

---

## 🎨 Color Legend

```
✓ GREEN  = Working/Healthy/Ready
✗ RED    = Error/Failed/Not Ready
⚠ YELLOW = Warning/Pending/Caution
ℹ BLUE   = Information/Details
```

---

## 🌐 Service Access

| Service | URL | Auth |
|---------|-----|------|
| **ArgoCD** | `http://192.168.0.202` | `admin` / (see argocd-password.txt) |
| **Prometheus** | `http://10.43.24.90:80` | None |
| **Grafana** | `http://10.43.215.176:80` | `admin` / (default) |

---

## 📊 Current Status

```
✓ Kubernetes:      1/1 nodes Ready
✓ Terraform:       137 state serial, 31 resources
✓ ArgoCD:          192.168.0.202 (3/3 apps synced)
✓ Gateway API:     1 gateway operational
✓ Helm:            6 releases deployed
✓ Prometheus:      Running and collecting metrics
✓ Grafana:         Running with dashboards
✓ MetalLB:         Load balancer operational
✓ Pods:            29 running (1 pending acceptable)
```

---

## 📝 Common Commands

### Check Status
```bash
./quick-status.sh                              # Quick overview
./check-complete-status.sh                     # Full audit
./health-metrics.sh                            # Performance
```

### Kubernetes
```bash
kubectl get nodes                              # Node status
kubectl get pods --all-namespaces -w           # Watch pods
kubectl get deployments --all-namespaces       # Deployments
```

### ArgoCD
```bash
kubectl get applications -n argocd -o wide     # Apps status
argocd app sync <app-name>                     # Sync app
kubectl logs -n argocd -l app.kubernetes.io/name=argocd-server  # Logs
```

### Port Forward
```bash
kubectl port-forward -n monitoring svc/prometheus-server 9090:80
kubectl port-forward -n monitoring svc/grafana 3000:80
```

### Terraform
```bash
cd /root/project_nebula/terraform
terraform show                                 # View state
terraform plan                                 # Preview changes
terraform validate                             # Validate config
```

### Helm
```bash
helm list --all-namespaces                    # All releases
helm status <release> -n <namespace>          # Release status
helm upgrade <release> <chart>                # Upgrade
```

---

## 🔧 Troubleshooting

### Pod Not Starting?
```bash
./health-metrics.sh
# Check "Pod Status Breakdown" section
# Look for "Failed" or "Pending" pods
kubectl describe pod <pod-name> -n <namespace>
```

### ArgoCD Apps Not Synced?
```bash
./quick-status.sh
# Check if ArgoCD shows all apps synced
kubectl describe application <app-name> -n argocd
```

### Prometheus/Grafana Not Accessible?
```bash
kubectl get svc -n monitoring -o wide
# Check if IPs are assigned (not <pending>)
```

### Terraform State Issues?
```bash
./quick-status.sh
# Check Terraform state serial number
cd /root/project_nebula/terraform && terraform validate
```

---

## 📈 Health Score Interpretation

From `health-metrics.sh`:

```
90-100%  ✓ EXCELLENT   - All systems optimal
75-89%   ⚠ GOOD        - Minor issues present
Below 75% ✗ NEEDS ATTENTION - Action required
```

Deductions:
- Pending pods: -5%
- Failed pods: -10%
- Error events: -5%
- Apps not synced: -10%

---

## ⏰ Automation Setup

### Run Every 30 Minutes (Cron)
```bash
*/30 * * * * /root/project_nebula/scripts/quick-status.sh >> /tmp/infra-status.log
```

### Continuous Monitor (Watch)
```bash
watch -n 30 ./quick-status.sh
```

### Pre-Deployment Check
```bash
#!/bin/bash
set -e
./scripts/quick-status.sh || exit 1
# Proceed with deployment
```

---

## 📚 Documentation

- **Complete Guide:** `STATUS_CHECK_README.md` in scripts directory
- **Summary:** `../SCRIPTS_SUMMARY.md` in parent directory
- **Index:** `README.md` in scripts directory

---

## 🎯 Decision Tree

**Just started?**
→ Run: `./quick-status.sh`

**Something seems wrong?**
→ Run: `./check-complete-status.sh`

**Need detailed metrics?**
→ Run: `./health-metrics.sh`

**Want all options?**
→ Run: `./run-status-check.sh` (interactive menu)

---

## ✅ Verification Checklist

After running scripts, verify:

- [ ] Kubernetes: 1/1 nodes Ready
- [ ] ArgoCD: IP assigned at 192.168.0.202
- [ ] All ArgoCD apps: Synced & Healthy
- [ ] Prometheus: Running
- [ ] Grafana: Running
- [ ] MetalLB: All pods ready
- [ ] No failed pods
- [ ] Health score > 75%

---

## 🆘 Emergency Commands

```bash
# Check if cluster is responsive
kubectl cluster-info

# Get recent events
kubectl get events --all-namespaces --sort-by='.lastTimestamp' | tail -20

# Force pod restart
kubectl rollout restart deployment/<name> -n <namespace>

# Force ArgoCD IP to 192.168.0.202
./ensure-argocd-202.sh
```

---

## 📞 Quick Help

**Q: Script says "kubectl not found"**
A: Install kubectl on your system

**Q: Scripts need to be run as sudo?**
A: No, they're read-only and safe

**Q: Can I run scripts concurrently?**
A: Yes, they're all read-only

**Q: How often should I check?**
A: Daily for quick-status, weekly for complete

**Q: Where are the credentials?**
A: See output from quick-status.sh for access URLs

---

## 🎓 Learning Path

1. **Day 1:** Run `quick-status.sh` - understand overall health
2. **Day 2:** Run `check-complete-status.sh` - learn each component
3. **Day 3:** Run `health-metrics.sh` - understand metrics
4. **Day 4+:** Set up automation with cron jobs
5. **Ongoing:** Use for monitoring and troubleshooting

---

## 📍 File Locations

```
/root/project_nebula/
├── scripts/
│   ├── quick-status.sh ⚡
│   ├── check-complete-status.sh 📋
│   ├── health-metrics.sh 📊
│   ├── run-status-check.sh 🔄
│   ├── README.md
│   └── STATUS_CHECK_README.md
├── SCRIPTS_SUMMARY.md
└── argocd-password.txt
```

---

## 🎯 Success Indicators

All green ✓ when:
- ✓ Kubernetes cluster Ready
- ✓ ArgoCD has external IP
- ✓ All apps Synced & Healthy
- ✓ Prometheus running
- ✓ Grafana running
- ✓ 25+ pods Running
- ✓ No Failed pods
- ✓ Health score > 80%

---

## 📋 Script Comparison

| Feature | Quick | Complete | Metrics |
|---------|-------|----------|---------|
| Speed | ⚡⚡⚡ | ⚡⚡ | ⚡ |
| Detail | Basic | Comprehensive | Performance |
| Use Case | Daily | Troubleshoot | Analysis |
| Components | 8 | 12 | 11 |
| Output Lines | ~15 | ~150 | ~100 |

---

**🎯 START:** `cd /root/project_nebula/scripts && ./quick-status.sh`

**📖 LEARN:** Read `SCRIPTS_SUMMARY.md` or `STATUS_CHECK_README.md`

**🚀 AUTOMATE:** Set up cron jobs for continuous monitoring

**✅ VERIFY:** Run all scripts and confirm all ✓ indicators present

---

*Last Updated: January 14, 2026*  
*All scripts production-ready and fully tested*
