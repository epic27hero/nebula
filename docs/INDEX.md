# 📚 Documentation Quick Index

**Fast reference to find exactly what you're looking for**

---

## 🎯 By Task

### "I need to set up the infrastructure from scratch"
→ **[SETUP_GUIDE.md](SETUP_GUIDE.md)** - Start at Step 1: Infrastructure Setup

### "I want to understand how everything works"
→ **[ARCHITECTURE_GUIDE.md](ARCHITECTURE_GUIDE.md)** - Start at Core Concepts Explained

### "I need to deploy a new version of my app"
→ **[SETUP_GUIDE.md#Step 5](SETUP_GUIDE.md)** OR [COMMANDS_REFERENCE.md#Deploy New Version](COMMANDS_REFERENCE.md#common-tasks)

### "My pod is stuck in Pending state"
→ **[COMMANDS_REFERENCE.md#Troubleshooting](COMMANDS_REFERENCE.md#troubleshooting-commands)** → Pod Issues

### "I need a specific kubectl command"
→ **[COMMANDS_REFERENCE.md](COMMANDS_REFERENCE.md)** - Search Ctrl+F for the command

### "I want to check the status of everything"
→ **[README.md#Common Tasks](README.md#-common-tasks)** → View Application Status

### "I need to scale my application"
→ **[COMMANDS_REFERENCE.md#Scale Application](COMMANDS_REFERENCE.md#scale-application)**

### "I want to understand Kubernetes concepts"
→ **[ARCHITECTURE_GUIDE.md#Core Concepts](ARCHITECTURE_GUIDE.md#core-concepts-explained)**

### "I need to troubleshoot an issue"
→ **[ARCHITECTURE_GUIDE.md#Troubleshooting](ARCHITECTURE_GUIDE.md#troubleshooting--monitoring)**

### "I want to access the monitoring dashboard"
→ **[README.md#Service Access Points](README.md#-service-access-points)** for IPs and credentials

---

## 📖 By Component

### Kubernetes (K3s)
- **Install:** [SETUP_GUIDE.md#Step 2](SETUP_GUIDE.md#step-2-kubernetes-cluster-setup)
- **Learn:** [ARCHITECTURE_GUIDE.md#Kubernetes](ARCHITECTURE_GUIDE.md#2-kubernetes-k3s)
- **Commands:** [COMMANDS_REFERENCE.md#kubectl Commands](COMMANDS_REFERENCE.md#kubectl-commands)

### FastAPI Application
- **Deploy:** [SETUP_GUIDE.md#Step 5](SETUP_GUIDE.md#step-5-application-deployment)
- **Learn:** [ARCHITECTURE_GUIDE.md#FastAPI](ARCHITECTURE_GUIDE.md#1-fastapi-application)
- **Update:** [ARCHITECTURE_GUIDE.md#Workflow 1](ARCHITECTURE_GUIDE.md#workflow-1-deploy-new-feature)

### ArgoCD (GitOps)
- **Install:** [SETUP_GUIDE.md#Step 6](SETUP_GUIDE.md#step-6-argocd-installation)
- **Learn:** [ARCHITECTURE_GUIDE.md#ArgoCD](ARCHITECTURE_GUIDE.md#3-argocd-continuous-delivery)
- **Commands:** [COMMANDS_REFERENCE.md#ArgoCD Commands](COMMANDS_REFERENCE.md#argocd-commands)

### MetalLB (Load Balancer)
- **Install:** [SETUP_GUIDE.md#Step 3](SETUP_GUIDE.md#step-3-network--load-balancing)
- **Learn:** [ARCHITECTURE_GUIDE.md#MetalLB](ARCHITECTURE_GUIDE.md#4-metallb-load-balancer)
- **Troubleshoot:** [ARCHITECTURE_GUIDE.md#MetalLB Issue](ARCHITECTURE_GUIDE.md#issue-metallb-ip-not-assigned)

### Docker & Registry
- **Setup:** [SETUP_GUIDE.md#Step 4](SETUP_GUIDE.md#step-4-container-registry)
- **Learn:** [ARCHITECTURE_GUIDE.md#Docker](ARCHITECTURE_GUIDE.md#7-docker--container-registry)
- **Commands:** [COMMANDS_REFERENCE.md#Docker](COMMANDS_REFERENCE.md#docker--registry)

### Prometheus (Metrics)
- **Install:** [SETUP_GUIDE.md#Step 7](SETUP_GUIDE.md#step-7-monitoring-stack)
- **Learn:** [ARCHITECTURE_GUIDE.md#Prometheus](ARCHITECTURE_GUIDE.md#5-prometheus-metrics-collection)
- **Commands:** [COMMANDS_REFERENCE.md#Prometheus](COMMANDS_REFERENCE.md#prometheus)

### Grafana (Dashboards)
- **Install:** [SETUP_GUIDE.md#Step 7](SETUP_GUIDE.md#step-7-monitoring-stack)
- **Learn:** [ARCHITECTURE_GUIDE.md#Grafana](ARCHITECTURE_GUIDE.md#6-grafana-metrics-visualization)
- **Commands:** [COMMANDS_REFERENCE.md#Grafana](COMMANDS_REFERENCE.md#grafana)

### Gateway API (Routing)
- **Setup:** [SETUP_GUIDE.md#Step 8](SETUP_GUIDE.md#step-8-gateway-api--routing)
- **Learn:** [ARCHITECTURE_GUIDE.md](ARCHITECTURE_GUIDE.md) (see Gateway API section)

### Terraform (IaC)
- **Learn:** [ARCHITECTURE_GUIDE.md#Terraform](ARCHITECTURE_GUIDE.md#8-terraform-infrastructure-as-code)
- **Files:** Check `/terraform` folder in repository

### GitLab CI/CD
- **Setup:** [SETUP_GUIDE.md#Step 10](SETUP_GUIDE.md#step-10-gitlab-cicd-setup-optional)
- **Understand:** [CI_CD_GUIDE.md](../CI_CD_GUIDE.md) in root docs

---

## 🔍 By Concept

### Understanding Containers
- [ARCHITECTURE_GUIDE.md#Docker](ARCHITECTURE_GUIDE.md#7-docker--container-registry)
- [SETUP_GUIDE.md#Step 5](SETUP_GUIDE.md#52-build--push-fastapi-application)

### Understanding Services & Load Balancing
- [ARCHITECTURE_GUIDE.md#Services](ARCHITECTURE_GUIDE.md#2-kubernetes-services-networking--discovery)
- [ARCHITECTURE_GUIDE.md#MetalLB](ARCHITECTURE_GUIDE.md#4-metallb-load-balancer)

### Understanding Deployments & Rolling Updates
- [ARCHITECTURE_GUIDE.md#Deployments](ARCHITECTURE_GUIDE.md#3-deployments-managing-pod-replicas)
- [ARCHITECTURE_GUIDE.md#Deployment Flow](ARCHITECTURE_GUIDE.md#scenario-developer-pushes-fastapi-code-change)

### Understanding GitOps
- [ARCHITECTURE_GUIDE.md#ArgoCD](ARCHITECTURE_GUIDE.md#3-argocd-continuous-delivery)
- [ARCHITECTURE_GUIDE.md#Benefits](ARCHITECTURE_GUIDE.md#6-gitops-deployment)

### Understanding Monitoring
- [ARCHITECTURE_GUIDE.md#Prometheus](ARCHITECTURE_GUIDE.md#5-prometheus-metrics-collection)
- [ARCHITECTURE_GUIDE.md#Grafana](ARCHITECTURE_GUIDE.md#6-grafana-metrics-visualization)

### Understanding High Availability
- [ARCHITECTURE_GUIDE.md#Benefits](ARCHITECTURE_GUIDE.md#1-high-availability)

### Understanding Security
- [README.md#Security](README.md#-security-best-practices)
- [SETUP_GUIDE.md#Troubleshooting](SETUP_GUIDE.md#troubleshooting)

---

## 📚 By Skill Level

### Beginner (New to Kubernetes)
1. [README.md](README.md) - Overview
2. [ARCHITECTURE_GUIDE.md#Core Concepts](ARCHITECTURE_GUIDE.md#core-concepts-explained)
3. [SETUP_GUIDE.md#Step 2](SETUP_GUIDE.md#step-2-kubernetes-cluster-setup)
4. [COMMANDS_REFERENCE.md#Basic Operations](COMMANDS_REFERENCE.md#basic-operations)

### Intermediate (Know Kubernetes)
1. [ARCHITECTURE_GUIDE.md#Component Deep Dive](ARCHITECTURE_GUIDE.md#component-deep-dive)
2. [SETUP_GUIDE.md](SETUP_GUIDE.md) - Specific steps
3. [COMMANDS_REFERENCE.md](COMMANDS_REFERENCE.md) - Full reference
4. [ARCHITECTURE_GUIDE.md#Workflows](ARCHITECTURE_GUIDE.md#operational-workflows)

### Advanced (Kubernetes Expert)
1. [ARCHITECTURE_GUIDE.md#End-to-End Flow](ARCHITECTURE_GUIDE.md#end-to-end-data-flow)
2. [ARCHITECTURE_GUIDE.md#Troubleshooting](ARCHITECTURE_GUIDE.md#troubleshooting--monitoring)
3. [COMMANDS_REFERENCE.md#Debugging](COMMANDS_REFERENCE.md#debugging)
4. Implement custom solutions based on knowledge

---

## 🚀 By Workflow

### Deployment Workflow
1. [README.md#Deployment Flow](README.md#-deployment-flow)
2. [ARCHITECTURE_GUIDE.md#Data Flow](ARCHITECTURE_GUIDE.md#end-to-end-data-flow)
3. [COMMANDS_REFERENCE.md#Deploy New Version](COMMANDS_REFERENCE.md#deploy-new-version)

### Troubleshooting Workflow
1. [README.md#Troubleshooting](README.md#troubleshooting)
2. [ARCHITECTURE_GUIDE.md#Troubleshooting](ARCHITECTURE_GUIDE.md#troubleshooting--monitoring)
3. [COMMANDS_REFERENCE.md#Troubleshooting](COMMANDS_REFERENCE.md#troubleshooting-commands)

### Monitoring Workflow
1. [SETUP_GUIDE.md#Step 7](SETUP_GUIDE.md#step-7-monitoring-stack)
2. [ARCHITECTURE_GUIDE.md#Monitoring](ARCHITECTURE_GUIDE.md#observability-stack)
3. [COMMANDS_REFERENCE.md#Monitoring](COMMANDS_REFERENCE.md#monitoring-commands)

### Scaling Workflow
1. [ARCHITECTURE_GUIDE.md#Scaling](ARCHITECTURE_GUIDE.md#8-scalability)
2. [COMMANDS_REFERENCE.md#Scale Application](COMMANDS_REFERENCE.md#scale-application)

---

## 🔗 Navigation

- **Back to README:** [README.md](README.md)
- **Setup Guide:** [SETUP_GUIDE.md](SETUP_GUIDE.md)
- **Architecture Guide:** [ARCHITECTURE_GUIDE.md](ARCHITECTURE_GUIDE.md)
- **Commands Reference:** [COMMANDS_REFERENCE.md](COMMANDS_REFERENCE.md)

---

## ⚡ Quick Links

- **ArgoCD UI:** http://192.168.0.202
- **FastAPI:** http://192.168.0.203
- **Prometheus:** http://192.168.0.204:9090
- **Grafana:** http://192.168.0.206:3000 (admin/grafana)

- **Status Script:** `./scripts/quick-status.sh`
- **Full Status:** `./scripts/check-all-status.sh`
- **Metrics:** `./scripts/health-metrics.sh`

---

## 📝 Search Tips

1. **In VS Code:** Ctrl+F to search within a file
2. **Table of Contents:** Each file has a table of contents at the top
3. **Sections:** Click on section links in markdown to jump around
4. **Commands:** Search for command names (e.g., "kubectl get pods")
5. **Topics:** Search for technology names (e.g., "ArgoCD", "Prometheus")

---

**Last Updated:** January 14, 2026  
**Status:** Complete and Production-Ready

