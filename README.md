# FastAPI Kubernetes Platform

A production-ready Kubernetes platform for deploying FastAPI applications using:

* GitLab CI/CD
* Terraform (Infrastructure as Code)
* Helm (Application packaging)
* ArgoCD (GitOps continuous delivery)
* Gateway API (Modern ingress & traffic management)
* MetalLB (LoadBalancer for bare-metal clusters)
* Prometheus & Grafana (Monitoring & observability)

---

## 🏗️ Architecture Overview

```
Developer
   ↓ git push
GitLab CI/CD
   ↓ build & push image
Docker Registry
   ↓
Git (Helm values updated)
   ↓
ArgoCD
   ↓
Helm
   ↓
Kubernetes
   ↓
Gateway API → MetalLB → External Traffic

Monitoring:
FastAPI → Prometheus → Grafana
```

---

## 📂 Repository Structure

```
fastapi-k8s-platform/
├── src/                      # FastAPI application code
├── Dockerfile                # Container build
├── .gitlab-ci.yml            # CI/CD pipeline
│
├── terraform/                # Infrastructure as Code
│   ├── modules/
│   │   ├── metallb/
│   │   ├── argocd/
│   │   └── gateway-api/
│
├── helm/
│   └── fastapi-app/          # Application Helm chart
│
├── argocd/
│   ├── projects/
│   ├── applications/
│   └── app-of-apps.yaml
│
├── monitoring/
│   ├── prometheus/
│   │   └── values.yaml
│   └── grafana/
│       └── values.yaml
│
├── scripts/                  # Bootstrap & install scripts
└── README.md
```

---

## ⚙️ Prerequisites

You must already have:

* Kubernetes cluster (K3s / K8s)
* Docker installed
* kubectl configured
* GitLab repository + CI/CD runners
* Private Docker registry (or GitLab registry)

---

## 🚀 Installation Flow (IMPORTANT)

### Correct order (do NOT change)

1. Install dependencies (Terraform, Helm, ArgoCD CLI)
2. Provision platform infrastructure using Terraform
3. Bootstrap ArgoCD
4. Deploy applications via ArgoCD
5. Observe metrics via Grafana

---

## 🛠️ Step-by-Step Installation

### 1️⃣ Clone repository

```bash
git clone https://gitlab.com/your-org/fastapi-k8s-platform.git
cd fastapi-k8s-platform
```

---

### 2️⃣ Install dependencies

```bash
chmod +x scripts/*.sh
./scripts/install-dependencies.sh
```

Installs:

* Terraform
* Helm
* kubectl (if missing)
* ArgoCD CLI
* Gateway API CRDs

---

### 3️⃣ Configure Terraform

```bash
cd terraform
cp terraform.tfvars.example terraform.tfvars
nano terraform.tfvars
```

---

### 4️⃣ Provision infrastructure

```bash
cd ..
./scripts/setup-terraform.sh
```

This creates:

* Namespaces (dev / staging / prod / monitoring)
* MetalLB
* ArgoCD
* Gateway API controller
* Docker registry secrets

---

### 5️⃣ Access ArgoCD

```bash
kubectl get svc argocd-server -n argocd
```

Login:

* Username: `admin`
* Password: from Terraform output

---

### 6️⃣ Deploy applications (GitOps way)

```bash
kubectl apply -f argocd/projects/fastapi-project.yaml
kubectl apply -f argocd/app-of-apps.yaml
```

ArgoCD now controls everything.

---

## 🔄 CI/CD Flow (GitLab)

| Action                 | Result                  |
| ---------------------- | ----------------------- |
| Push to feature branch | Build + test only       |
| Push to develop        | Deploy to dev & staging |
| Push to main           | Deploy to production    |

GitLab **does NOT run kubectl apply**.
ArgoCD handles deployments.

---

## 🌐 Traffic Flow (Gateway API)

* Gateway API replaces Ingress
* One Gateway per cluster
* Apps attach using HTTPRoute
* MetalLB assigns external IP

```bash
kubectl get gateway -A
kubectl get httproute -A
```

---

## 📊 Monitoring & Observability

### Prometheus

* Scrapes FastAPI `/metrics`
* Collects cluster metrics

### Grafana

* Preloaded Kubernetes dashboards
* FastAPI metrics available
* Exposed via LoadBalancer

Access Grafana:

```bash
kubectl get svc grafana -n monitoring
```

Login:

* admin / admin123

---

## 📈 FastAPI Metrics

Metrics endpoint:

```
GET /metrics
```

Defined in:

```
src/main.py
```

Prometheus scrapes metrics **directly from pods**.
Gateway API is **not involved**.

---

## 🧪 Verification

```bash
kubectl get pods -n production
kubectl get svc -n production
kubectl get gateway -A
kubectl get httproute -A
```

Test API:

```bash
curl -H "Host: api.production.factentry.com" http://<GATEWAY-IP>/
```

---

## 🧹 Cleanup

```bash
cd terraform
terraform destroy
```

---

## ✅ What This Platform Gives You

✔ GitOps-based deployments
✔ Zero-downtime rolling updates
✔ Multi-environment support
✔ Production-grade ingress (Gateway API)
✔ Monitoring with Prometheus & Grafana
✔ Scalable & secure architecture

---

## 👤 Author

**Souvik Das**
Technical Manager – FactEntry

---

## 🏁 Final Note

This repository is a **platform**, not just an application.

Once bootstrapped:

* Developers only push code
* Platform runs itself
* Operations become predictable
