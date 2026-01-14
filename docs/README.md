# Project Nebula Documentation

Welcome to the complete documentation for Project Nebula - a production-ready Kubernetes infrastructure with FastAPI, CI/CD, and monitoring.

---

## 📚 Documentation Index

### 1. **[SETUP_GUIDE.md](SETUP_GUIDE.md)** - Complete Installation Guide

**What you'll learn:**
- Prerequisites and hardware requirements
- Step-by-step installation from scratch
- Every component setup with explanations
- K3s Kubernetes cluster installation
- MetalLB load balancer configuration
- Docker registry setup
- ArgoCD GitOps deployment
- Prometheus and Grafana monitoring
- Gateway API and routing
- Troubleshooting common issues

**Best for:** First-time setup, deploying on new infrastructure

**Time to read:** ~30-40 minutes
**Time to implement:** ~1-2 hours

---

### 2. **[ARCHITECTURE_GUIDE.md](ARCHITECTURE_GUIDE.md)** - Comprehensive Architecture Explanation

**What you'll learn:**
- Complete system architecture overview
- How all components work together
- Deep dive into each technology:
  - Pods and containers
  - Kubernetes services and networking
  - Deployments and rolling updates
  - Namespaces and isolation
  - Labels and selectors
- FastAPI application structure
- K3s Kubernetes internals
- ArgoCD continuous delivery flow
- MetalLB load balancing
- Prometheus metrics collection
- Grafana visualization
- Docker and container registry
- Terraform infrastructure as code
- End-to-end data flow examples
- Benefits of this architecture
- Operational workflows
- Complete commands reference
- Troubleshooting guide

**Best for:** Understanding how everything works, architectural decisions

**Time to read:** ~45-60 minutes

---

### 3. **[COMMANDS_REFERENCE.md](COMMANDS_REFERENCE.md)** - Quick Command Reference

**What you'll find:**
- kubectl commands (pods, deployments, services)
- ArgoCD commands
- Kubernetes inspection commands
- Troubleshooting commands
- Monitoring commands (Prometheus, Grafana)
- Git and deployment commands
- Docker and registry commands
- Useful aliases for faster typing
- Common task examples

**Best for:** Quick lookup during daily operations, troubleshooting

**Time to use:** Seconds for each lookup

---

## 🎯 Quick Start by Use Case

### "I'm deploying this for the first time"
1. Read [SETUP_GUIDE.md](SETUP_GUIDE.md)
2. Follow each step carefully
3. Run status check after each major step
4. Reference [TROUBLESHOOTING](#troubleshooting) if issues arise

### "I want to understand how everything works"
1. Start with [ARCHITECTURE_GUIDE.md](ARCHITECTURE_GUIDE.md)
2. Read each component section
3. Look at the data flow diagrams
4. Understand the benefits section

### "I need to do something quickly"
1. Go to [COMMANDS_REFERENCE.md](COMMANDS_REFERENCE.md)
2. Search for your task
3. Copy and adapt the command
4. Done!

### "Something is broken, help!"
1. Check [ARCHITECTURE_GUIDE.md - Troubleshooting & Monitoring](ARCHITECTURE_GUIDE.md#troubleshooting--monitoring)
2. Use [COMMANDS_REFERENCE.md - Troubleshooting Commands](COMMANDS_REFERENCE.md#troubleshooting-commands)
3. Run: `./scripts/check-all-status.sh`
4. Post error logs to Slack/support

---

## 🏗️ Architecture Overview

```
┌─────────────────────────────────────────┐
│      Git Repository (Source Code)       │
│       ↓                                 │
│  GitLab CI/CD Pipeline                  │
│  (BUILD → PUSH → DEPLOY)                │
│       ↓                                 │
│  Docker Registry (Image Storage)        │
│       ↓                                 │
│  K3s Kubernetes Cluster                 │
│  ├─ FastAPI App (3 replicas)            │
│  ├─ Prometheus (Metrics)                │
│  ├─ Grafana (Dashboards)                │
│  ├─ ArgoCD (GitOps Sync)                │
│  └─ MetalLB (Load Balancer)             │
│       ↓                                 │
│  External Load Balancer IPs             │
│  ├─ 192.168.0.202 → ArgoCD UI           │
│  ├─ 192.168.0.203 → FastAPI             │
│  ├─ 192.168.0.204 → Prometheus          │
│  └─ 192.168.0.205 → Grafana             │
└─────────────────────────────────────────┘
```

---

## 🔑 Key Components

| Component | Purpose | Access | Status |
|-----------|---------|--------|--------|
| **K3s** | Kubernetes cluster | `kubectl` | ✅ Running |
| **FastAPI** | REST API application | `http://192.168.0.203` | ✅ 3/3 replicas |
| **ArgoCD** | GitOps deployment | `http://192.168.0.202` | ✅ Synced |
| **Prometheus** | Metrics collection | `http://192.168.0.204:9090` | ✅ Running |
| **Grafana** | Dashboards | `http://192.168.0.205:3000` | ✅ Running |
| **MetalLB** | Load balancer | Internal | ✅ Running |
| **Docker Registry** | Image storage | `192.168.0.113:5000` | ✅ Running |

---

## 📊 Service Access Points

### Internal (From pods within cluster)
```
FastAPI:    http://fastapi-app.production.svc.cluster.local
Prometheus: http://prometheus-server.monitoring.svc.cluster.local
Grafana:    http://grafana.monitoring.svc.cluster.local
```

### External (From outside cluster)
```
ArgoCD:     http://192.168.0.202
FastAPI:    http://192.168.0.203
Prometheus: http://192.168.0.204:9090
Grafana:    http://192.168.0.205:3000 (admin/grafana)
```

### Internal Kubernetes DNS
```
fastapi-app.production.svc.cluster.local
prometheus-server.monitoring.svc.cluster.local
grafana.monitoring.svc.cluster.local
argocd-server.argocd.svc.cluster.local
```

---

## 🚀 Common Tasks

### View Application Status
```bash
./scripts/quick-status.sh
```

### View Comprehensive Status
```bash
./scripts/check-all-status.sh
```

### View Performance Metrics
```bash
./scripts/health-metrics.sh
```

### Get Pod Logs
```bash
kubectl logs -n production -l app=fastapi -f
```

### Scale Application
```bash
kubectl scale deployment fastapi-app --replicas=5 -n production
```

### Deploy New Version
```bash
# Update src/main.py, then:
git add src/main.py
git commit -m "Update FastAPI app"
git push origin master
# ArgoCD auto-deploys in ~5 minutes!
```

### Check Metrics
```
Open: http://192.168.0.205:3000
Username: admin
Password: grafana
```

---

## 📝 Deployment Flow

```
Developer writes code
        ↓
git commit && git push
        ↓
GitLab webhook triggered
        ↓
BUILD: Docker image created
        ↓
PUSH: Image pushed to registry
        ↓
DEPLOY: Application notified
        ↓
ArgoCD: Watches for changes
        ↓
K3s: Pulls new image
        ↓
Rolling update: Old pods → New pods
        ↓
Service: Routes traffic (ZERO DOWNTIME)
        ↓
Changes LIVE!

Total time: ~5-7 minutes
```

---

## 🔍 Troubleshooting

### Common Issues

**Q: Pod is stuck in "Pending"**
```bash
kubectl describe pod <pod-name> -n production
# Check events section for error messages
```

**Q: Service has no endpoints**
```bash
kubectl get service <service-name> -n production -o yaml
# Check selector labels match pod labels
```

**Q: Can't access external service IP**
```bash
kubectl get svc -o wide
# Check MetalLB assigned IP (EXTERNAL-IP column)
```

**Q: ArgoCD application is "Out of Sync"**
```bash
argocd app sync fastapi-prod
# Or use --force flag
```

**Q: Image pull error**
```bash
kubectl logs <pod-name> -n production
# Check image path is correct
# Verify registry is running
```

For more troubleshooting, see:
- [SETUP_GUIDE - Troubleshooting](SETUP_GUIDE.md#troubleshooting)
- [ARCHITECTURE_GUIDE - Troubleshooting](ARCHITECTURE_GUIDE.md#troubleshooting--monitoring)
- [COMMANDS_REFERENCE - Troubleshooting](COMMANDS_REFERENCE.md#troubleshooting-commands)

---

## 📖 Learning Path

### Beginner (New to Kubernetes)
1. Read: [ARCHITECTURE_GUIDE.md - Core Concepts Explained](ARCHITECTURE_GUIDE.md#core-concepts-explained)
2. Understand: Pods, Services, Deployments, Namespaces
3. Practice: `kubectl get pods`, `kubectl logs`, `kubectl describe`
4. Try: Deploy a simple application

### Intermediate (Know Kubernetes basics)
1. Read: [ARCHITECTURE_GUIDE.md - Component Deep Dive](ARCHITECTURE_GUIDE.md#component-deep-dive)
2. Understand: ArgoCD, MetalLB, CI/CD pipeline
3. Practice: Deploy updates, scale applications, check logs
4. Try: Modify manifests and push to Git

### Advanced (Kubernetes expert)
1. Read: [ARCHITECTURE_GUIDE.md - End-to-End Data Flow](ARCHITECTURE_GUIDE.md#end-to-end-data-flow)
2. Understand: etcd, state management, reconciliation
3. Practice: Debug issues, optimize resources, monitor metrics
4. Try: Add custom Prometheus metrics, create Grafana dashboards

---

## 💡 Key Concepts

### GitOps
- Git is source of truth
- Declarative (YAML files describe desired state)
- Automatic sync (ArgoCD keeps cluster in sync)
- Auditable (all changes tracked in Git)

### Rolling Updates
- New pods created with new version
- Old pods gradually terminated
- Service routes to healthy pods
- **Zero downtime!**

### Self-Healing
- Failed pods automatically restarted
- Desired replicas always maintained
- Dead nodes replaced (multi-node clusters)
- Continuous reconciliation

### Observability
- Prometheus collects metrics
- Grafana visualizes data
- Alerts can be configured
- Historical data retained (30 days)

### Load Balancing
- MetalLB assigns external IPs
- kube-proxy routes traffic
- Service distributes across pods
- Round-robin or session affinity

---

## 🎯 Benefits of This Architecture

✅ **Production-Ready** - Used by thousands of companies
✅ **Highly Available** - 3 replicas, auto-restart
✅ **Scalable** - Add replicas or nodes easily
✅ **Automated** - CI/CD pipeline fully automated
✅ **Observable** - Prometheus + Grafana for visibility
✅ **Self-Healing** - Automatic recovery from failures
✅ **Zero-Downtime** - Rolling updates, no service interruption
✅ **Infrastructure as Code** - Reproducible, version-controlled
✅ **Secure** - Namespace isolation, RBAC, non-root containers
✅ **Cost-Efficient** - Run on minimal infrastructure

---

## 📞 Support & Help

### Quick Reference
- **Setup:** [SETUP_GUIDE.md](SETUP_GUIDE.md)
- **Architecture:** [ARCHITECTURE_GUIDE.md](ARCHITECTURE_GUIDE.md)
- **Commands:** [COMMANDS_REFERENCE.md](COMMANDS_REFERENCE.md)
- **Status:** `./scripts/quick-status.sh`

### Getting Help
1. Check the appropriate documentation file
2. Search for your task in COMMANDS_REFERENCE
3. Run status check scripts to verify health
4. Check pod logs: `kubectl logs -n production -l app=fastapi -f`
5. Check Kubernetes events: `kubectl get events -n production`

---

## 📅 Regular Maintenance

### Daily
- ✅ Monitor application (access UI)
- ✅ Check Grafana dashboards
- ✅ Monitor deployment logs

### Weekly
- ✅ Review Prometheus metrics
- ✅ Check pod resource usage
- ✅ Verify backups are working

### Monthly
- ✅ Update dependencies
- ✅ Review and optimize queries
- ✅ Capacity planning
- ✅ Security audit

---

## 🔐 Security Best Practices

- ✅ Store secrets in Kubernetes secrets (not in Git)
- ✅ Use RBAC for access control
- ✅ Network policies to restrict traffic
- ✅ Regular updates for security patches
- ✅ Scan container images for vulnerabilities
- ✅ Non-root containers
- ✅ Resource limits to prevent DoS
- ✅ Backup and disaster recovery plan

---

## 🎓 Next Steps

1. **Read Setup Guide** - Understand installation
2. **Read Architecture Guide** - Learn how it works
3. **Deploy Application** - Push your code
4. **Monitor Metrics** - Use Grafana dashboards
5. **Scale Application** - Increase replicas
6. **Implement CI/CD** - GitLab pipeline
7. **Add Alerts** - Create Prometheus alerts
8. **Custom Dashboards** - Build Grafana dashboards

---

## 📚 External Resources

- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [K3s Documentation](https://docs.k3s.io/)
- [ArgoCD Documentation](https://argo-cd.readthedocs.io/)
- [Prometheus Documentation](https://prometheus.io/docs/)
- [Grafana Documentation](https://grafana.com/docs/grafana/)
- [MetalLB Documentation](https://metallb.universe.tf/)
- [Docker Documentation](https://docs.docker.com/)

---

## 📝 Document Version

- Version: 1.0
- Last Updated: January 14, 2026
- Status: Complete and Production-Ready

---

**Questions?** Check the appropriate documentation file or run status check scripts!

