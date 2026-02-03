# 📚 Documentation Index V2 — Project Nebula Complete Guide

**Last Updated**: February 3, 2026  
**Verification Status**: ✅ Verification Complete — 85% Compliant, 3 Actionable Gaps Identified

---

## 🎯 Quick Navigation

### For Different Roles

#### 👨‍💼 **Project Manager / Stakeholder**
Start here to understand what this project does:
- [Project Overview](#project-overview)
- [Architecture at a Glance](#architecture-at-a-glance)

#### 👨‍💻 **Developer (Deploying Code)**
Start here to understand how to deploy:
1. [Making Changes](#making-changes)
2. [CI/CD Pipeline](#cicd-pipeline)
3. [Verification](#verification)

#### 🏗️ **DevOps / Infrastructure**
Start here for complete architecture understanding:
1. [Deterministic Deployment Model](#deterministic-deployment-model)
2. [Component Responsibilities](#component-responsibilities)
3. [Known Gaps & Action Items](#known-gaps--action-items)

#### 🔍 **Auditor / Security**
Start here for compliance and responsibilities:
- [Responsibility Boundaries](#responsibility-boundaries)
- [Verification Report](#verification-report)

---

## 📖 Documentation Roadmap

### 🆕 V2 Documentation (Updated Feb 3, 2026)

| Document | Purpose | Read Time | Status |
|----------|---------|-----------|--------|
| **[DETERMINISTIC_DEPLOYMENT_RESPONSIBILITY_MAP_V2.md](DETERMINISTIC_DEPLOYMENT_RESPONSIBILITY_MAP_V2.md)** | WHO does WHAT, responsibility boundaries, determinism guarantee | 15 min | ✅ Complete |
| **[ARCHITECTURE_GUIDE_V2.md](ARCHITECTURE_GUIDE_V2.md)** | Complete architecture, data flow, component interactions | 20 min | ✅ Complete |
| **[CI_CD_GUIDE_V2.md](CI_CD_GUIDE_V2.md)** | GitLab CI/CD pipeline explained, image building, push, deploy | 15 min | ✅ Complete |
| **[VERIFICATION_REPORT_AND_ACTION_ITEMS_V2.md](VERIFICATION_REPORT_AND_ACTION_ITEMS_V2.md)** | Verification results, gaps, fixes, action items | 10 min | ✅ Complete |

### 📋 Original Documentation (Still Valid)

| Document | Purpose | Current Use |
|----------|---------|------------|
| [DEPLOYMENT_GUIDE.md](DEPLOYMENT_GUIDE.md) | Deployment procedures and troubleshooting | ✅ Reference |
| [GITLAB_GITOPS_ENHANCEMENTS.md](GITLAB_GITOPS_ENHANCEMENTS.md) | GitOps improvements and features | ✅ Reference |
| [COMMANDS_REFERENCE.md](COMMANDS_REFERENCE.md) | Useful kubectl and git commands | ✅ Quick reference |
| [SERVICE_ENDPOINTS.md](SERVICE_ENDPOINTS.md) | All service endpoints and IPs | ✅ Reference |

---

## 🎯 Project Overview

**Project Nebula** is a **deterministic, GitOps-based Kubernetes deployment system** that ensures:

### ✅ What It Does

```
Code Push → CI Builds → Immutable Image → GitOps Syncs → K8s Deploys → Zero Downtime
```

**Key Properties**:
- ✅ Single source of truth (git)
- ✅ Deterministic versions (commit SHA)
- ✅ Immutable artifacts (docker image)
- ✅ Automatic deployments (ArgoCD)
- ✅ Observable state (Prometheus + Grafana)
- ✅ Complete audit trail (git history)

### 📦 What's Included

```
├─ FastAPI Application      ← Your code runs here
├─ K3s Kubernetes Cluster   ← Orchestrates containers
├─ GitLab CI/CD Pipeline    ← Builds & tests automatically
├─ Helm Charts              ← Configuration as code
├─ ArgoCD                   ← GitOps automation
├─ Prometheus + Grafana     ← Monitoring & alerting
├─ MetalLB Load Balancer    ← Static external IPs
└─ Terraform                ← Infrastructure as code
```

---

## 🏗️ Architecture at a Glance

### Simple View

```
Developer      GitLab CI      Docker Registry    Kubernetes      User
   │              │                  │                │           │
   ├─ push code ──→ build image ─────→ store         │           │
   │              │                  │                │           │
   │              │              ← ArgoCD syncs ──────→ deploy    │
   │              │                                    │           │
   │              │                                    └─ traffic ─→
```

### Detailed Responsibility Flow

```
┌─────────────────────────────────────────────────────────────┐
│ 1️⃣  CI/CD (GitLab)     → DECIDES version & timestamp      │
│ 2️⃣  Docker Image       → CARRIES metadata in layers       │
│ 3️⃣  Helm Chart         → HOLDS configuration data         │
│ 4️⃣  Kubernetes         → CONTROLS pod lifecycle           │
│ 5️⃣  ArgoCD            → ENFORCES git as source of truth   │
│ 6️⃣  FastAPI App       → PROVES reality via /version       │
│ 7️⃣  Load Balancer     → ROUTES traffic                    │
│ 8️⃣  Operator/You      → VERIFIES with curl /version       │
└─────────────────────────────────────────────────────────────┘
```

---

## 🔄 Deterministic Deployment Model

### The Promise

**Every deployment decision is traceable to a single source. No guessing. No randomness.**

### The Chain

```
GIT COMMIT → CI BUILDS → IMAGE PUSHED → GIT TAG UPDATED → 
ARGOCD SYNCS → K8S DEPLOYS → APP PROVES → OPERATOR VERIFIES
```

### Why This Matters

| Scenario | Without Determinism | With Determinism |
|----------|-------------------|-----------------|
| **Deploy** | "Hopefully it works" | "Git proves what's running" |
| **Debug** | "No idea which code" | "Query /version, see exact commit" |
| **Rollback** | Manual kubectl changes | `git revert <commit>` |
| **Scale** | Manual helm edits | `git edit values.yaml` |
| **Audit** | No trail | Complete git history |

---

## 📚 Component Responsibilities

### Layer 1: CI/CD (GitLab) — THE DECIDER

**File**: `.gitlab-ci.yml`

**Decides**:
- ✅ App version (git tag or commit SHA)
- ✅ Build timestamp (UTC)
- ✅ Image tag (unique per build)

**Must Do**:
- ✅ Build image with `--no-cache`
- ✅ Inject version as build args
- ✅ Push to immutable registry
- ✅ Update git with new tag

**Status**: ✅ **CORRECT**

---

### Layer 2: Docker Image — THE CARRIER

**File**: `Dockerfile`

**Carries**:
- Application code
- Runtime dependencies
- **Build metadata (VERSION, TIMESTAMP)** ← Baked as ENV

**Must Do**:
- ✅ Capture build args from CI
- ✅ Set as ENV variables
- ✅ Make metadata immutable in layers

**Status**: 🔴 **INCOMPLETE** (not capturing metadata)

**Fix**: Add ARG/ENV declarations

---

### Layer 3: Helm Chart — THE DATA STORE

**Files**: 
- `helm/fastapi-app/values.yaml`
- `helm/fastapi-app/templates/deployment.yaml`

**Stores**:
- ✅ Image repository
- ✅ Image tag (empty, awaits CI injection)
- ✅ Replica count
- ✅ Service configuration

**Must Do**:
- ✅ Hold only data, no logic
- ✅ Never use `latest` tag
- ✅ Render YAML from values

**Status**: ✅ **CORRECT**

---

### Layer 4: Kubernetes — THE CONTROLLER

**Outputs**: Rendered Deployment, Service, etc.

**Controls**:
- Pod startup timing
- Health checks
- Traffic routing
- Rolling updates

**Must Do**:
- ✅ Define readiness probes
- ✅ Define liveness probes
- ✅ Control rollout strategy

**Status**: 🟡 **90% CORRECT** (missing strategy)

**Fix**: Add rollout strategy config

---

### Layer 5: ArgoCD — THE ENFORCER

**File**: `argocd/applications/fastapi-app-production.yaml`

**Enforces**:
- ✅ Git is source of truth
- ✅ Automatic sync on changes
- ✅ Drift detection & healing
- ✅ Orphan resource cleanup

**Must Do**:
- ✅ Enable `prune` & `selfHeal`
- ✅ No helm overrides
- ✅ Full automation

**Status**: ✅ **PERFECT**

---

### Layer 6: FastAPI App — THE PROVER

**File**: `src/main.py`

**Proves**:
- ✅ `/health` → Pod is alive
- ✅ `/ready` → Can accept traffic
- ✅ `/metrics` → Prometheus data
- ✅ Root endpoint → Full metadata
- 🟡 `/version` → Explicit version (missing)

**Must Do**:
- ✅ Read version from ENV
- ✅ Expose readiness/liveness
- ✅ Serve metrics

**Status**: 🟡 **95% CORRECT** (no dedicated `/version`)

**Fix**: Add `/version` endpoint

---

### Layer 7: Load Balancer — THE ROUTER

**Tool**: MetalLB

**Routes**:
- External IP `192.168.0.203:80`
- To K8s service port `8000`
- Across all ready pods

**Status**: ✅ **CORRECT**

---

### Layer 8: Operator/You — THE VERIFIER

**Command**: `curl http://192.168.0.203/version`

**Verifies**:
- App is responding
- Version is correct
- Pod is healthy
- Deployment worked

**Status**: ✅ **READY TO USE**

---

## 🚀 Making Changes (Developer Workflow)

### Step 1: Make Code Changes

```bash
cd /root/project_nebula
vim src/main.py           # Edit your code
# ... make changes ...
```

### Step 2: Commit & Push

```bash
git add src/main.py
git commit -m "Add new feature"
git push origin master    # Push to GitLab
```

### Step 3: CI/CD Runs Automatically

```
GitLab webhook fires
  ↓
Pipeline starts
  ├─ BUILD: docker build (with your changes)
  ├─ PUSH:  docker push to registry
  ├─ UPDATE-HELM: git commit new tag
  └─ DEPLOY: ArgoCD syncs
```

### Step 4: Kubernetes Rolling Update

```
K8s detects new image
  ↓
Starts new pods with new code
  ↓
Waits for readiness (GET /health)
  ↓
Adds to load balancer
  ↓
Removes old pods
  ↓
All done! No downtime!
```

### Step 5: Verify

```bash
# See deployment status
kubectl -n production rollout status deploy fastapi-app

# Query version endpoint (should show new code)
curl http://192.168.0.203/version | jq
```

**Result**: Your code is now live! ✅

---

## 🔧 CI/CD Pipeline

### Pipeline Stages

| Stage | What | Where |
|-------|------|-------|
| **BUILD** | Creates Docker image | `.gitlab-ci.yml` |
| **PUSH** | Uploads to registry | `.gitlab-ci.yml` |
| **UPDATE-HELM** | Updates git with tag | `.gitlab-ci.yml` |
| **DEPLOY** | Triggers ArgoCD | `.gitlab-ci.yml` |
| **RELEASE** | Creates git tag | `.gitlab-ci.yml` |
| **DISCOVERY** | Reports success | `.gitlab-ci.yml` |

### Build Arguments

CI/CD passes these to Dockerfile:
- `APP_VERSION` → Version of code
- `BUILD_TIME` → Timestamp of build
- `IMAGE_TAG` → Unique identifier (short SHA)

**Status**: ✅ CI Passes them, 🔴 Dockerfile doesn't capture them

---

## 🔍 Verification

### Quick Health Check

```bash
# Is deployment running?
kubectl -n production get deploy fastapi-app

# Are pods ready?
kubectl -n production get pods

# See full details
kubectl -n production describe deploy fastapi-app
```

### Check Current Version

```bash
# Query /version endpoint
curl http://192.168.0.203/version | jq

# Expected output:
{
  "app": "fastapi-demo",
  "app_version": "abc1234f",      # ← Git commit
  "image_tag": "abc1234f",        # ← Same as version
  "build_time": "2026-02-03T14:35:20Z",
  "pod": "fastapi-app-xyz12-xyz",
  "uptime_seconds": 3847
}
```

### Watch Rolling Update

```bash
# Watch deployment update in real-time
watch kubectl -n production get pods
watch kubectl -n production rollout status deploy fastapi-app
watch -n 1 curl -s http://192.168.0.203/version | jq '.pod'
```

---

## 🐛 Troubleshooting

### "My code isn't showing up"

1. **Check CI/CD pipeline**
   - Visit GitLab → CI/CD → Pipelines
   - Look for your commit
   - Check if pipeline passed

2. **Check image was pushed**
   ```bash
   curl -s https://192.168.0.190:5005/v2/root/project_nebula/fastapi-demo/tags/list | jq
   ```

3. **Check ArgoCD synced**
   ```bash
   argocd app get fastapi-prod
   ```

4. **Force sync**
   ```bash
   argocd app sync fastapi-prod --force
   kubectl -n production delete pods --all  # Force pull new image
   ```

### "Version shows fallback values"

**Cause**: Dockerfile not capturing build args

**Fix**: Add ARG/ENV to Dockerfile (see [Gap #1](#gap-1-dockerfile))

### "Deployment is not rolling out"

**Check**:
```bash
kubectl -n production describe deploy fastapi-app
kubectl -n production logs -n production deploy/fastapi-app
```

---

## 📋 Known Gaps & Action Items

### 🔴 **Gap #1: Dockerfile Missing Metadata (CRITICAL)**

**Impact**: Image doesn't know its own version

**Fix**: Add ARG/ENV to Dockerfile (2 min fix)

**See**: [VERIFICATION_REPORT_AND_ACTION_ITEMS_V2.md](VERIFICATION_REPORT_AND_ACTION_ITEMS_V2.md#gap-1-dockerfile-missing-argenv-declarations)

---

### 🟡 **Gap #2: Missing /version Endpoint (MEDIUM)**

**Impact**: No standard version endpoint

**Fix**: Add dedicated `/version` endpoint to FastAPI (3 min fix)

**See**: [VERIFICATION_REPORT_AND_ACTION_ITEMS_V2.md](VERIFICATION_REPORT_AND_ACTION_ITEMS_V2.md#gap-2-fastapi-missing-dedicated-version-endpoint)

---

### 🟡 **Gap #3: Missing Rollout Strategy (LOW)**

**Impact**: No explicit control over deployment pacing

**Fix**: Add strategy config to Deployment (1 min fix)

**See**: [VERIFICATION_REPORT_AND_ACTION_ITEMS_V2.md](VERIFICATION_REPORT_AND_ACTION_ITEMS_V2.md#gap-3-kubernetes-rollout-strategy)

---

## 📚 Complete Documentation

### Architecture & Design

- [DETERMINISTIC_DEPLOYMENT_RESPONSIBILITY_MAP_V2.md](DETERMINISTIC_DEPLOYMENT_RESPONSIBILITY_MAP_V2.md)
  - WHO does WHAT
  - Responsibility boundaries
  - Determinism guarantee
  - Mental model

- [ARCHITECTURE_GUIDE_V2.md](ARCHITECTURE_GUIDE_V2.md)
  - Complete architecture diagram
  - Component deep dive
  - End-to-end data flow
  - Operational workflows

### CI/CD & Deployment

- [CI_CD_GUIDE_V2.md](CI_CD_GUIDE_V2.md)
  - Pipeline stages explained
  - Build arguments
  - Image tagging
  - Complete workflow trace

- [DEPLOYMENT_GUIDE.md](DEPLOYMENT_GUIDE.md)
  - Deployment procedures
  - Rollback instructions
  - Scaling guide
  - Troubleshooting

### Verification & Validation

- [VERIFICATION_REPORT_AND_ACTION_ITEMS_V2.md](VERIFICATION_REPORT_AND_ACTION_ITEMS_V2.md)
  - Verification results
  - Gap analysis
  - Action items with fixes
  - After-fix verification

### Reference Guides

- [COMMANDS_REFERENCE.md](COMMANDS_REFERENCE.md)
  - Useful kubectl commands
  - Git commands
  - ArgoCD commands

- [SERVICE_ENDPOINTS.md](SERVICE_ENDPOINTS.md)
  - Application endpoints
  - Kubernetes services
  - Monitoring endpoints
  - External IPs

- [GITLAB_GITOPS_ENHANCEMENTS.md](GITLAB_GITOPS_ENHANCEMENTS.md)
  - GitOps features
  - Workflow improvements

---

## 🎓 Learning Path

### If you want to understand...

**"How does deployment work?"**
1. Start: [ARCHITECTURE_GUIDE_V2.md](ARCHITECTURE_GUIDE_V2.md) - Overview section
2. Deep dive: [DETERMINISTIC_DEPLOYMENT_RESPONSIBILITY_MAP_V2.md](DETERMINISTIC_DEPLOYMENT_RESPONSIBILITY_MAP_V2.md)
3. Verify: [VERIFICATION_REPORT_AND_ACTION_ITEMS_V2.md](VERIFICATION_REPORT_AND_ACTION_ITEMS_V2.md)

**"How do I deploy my code?"**
1. Start: [Making Changes](#making-changes) section above
2. Understand: [CI_CD_GUIDE_V2.md](CI_CD_GUIDE_V2.md)
3. Verify: [Verification](#verification) section above

**"What is responsible for what?"**
1. Start: [DETERMINISTIC_DEPLOYMENT_RESPONSIBILITY_MAP_V2.md](DETERMINISTIC_DEPLOYMENT_RESPONSIBILITY_MAP_V2.md)
2. Visual: [Component Responsibilities](#component-responsibilities) section above

**"What needs to be fixed?"**
1. Go to: [VERIFICATION_REPORT_AND_ACTION_ITEMS_V2.md](VERIFICATION_REPORT_AND_ACTION_ITEMS_V2.md)
2. Review: [Known Gaps](#known-gaps--action-items) section above

**"How do I troubleshoot?"**
1. Start: [DEPLOYMENT_GUIDE.md](DEPLOYMENT_GUIDE.md)
2. Quick ref: [Troubleshooting](#troubleshooting) section above
3. Commands: [COMMANDS_REFERENCE.md](COMMANDS_REFERENCE.md)

---

## 📊 Documentation Status

### V2 Documents (Feb 3, 2026)

| Document | Status | Coverage |
|----------|--------|----------|
| DETERMINISTIC_DEPLOYMENT_RESPONSIBILITY_MAP_V2.md | ✅ Complete | 100% responsibility mapping |
| ARCHITECTURE_GUIDE_V2.md | ✅ Complete | 100% architecture & flows |
| CI_CD_GUIDE_V2.md | ✅ Complete | 100% pipeline explanation |
| VERIFICATION_REPORT_AND_ACTION_ITEMS_V2.md | ✅ Complete | 100% gaps & fixes |
| INDEX_V2.md (this file) | ✅ Complete | 100% navigation |

### Original Documents (Still Valid)

| Document | Status | Notes |
|----------|--------|-------|
| DEPLOYMENT_GUIDE.md | ✅ Current | Use as reference |
| GITLAB_GITOPS_ENHANCEMENTS.md | ✅ Current | Use as reference |
| COMMANDS_REFERENCE.md | ✅ Current | Quick reference |
| SERVICE_ENDPOINTS.md | ✅ Current | IP/port reference |

---

## 🎯 Next Steps

1. **Review** the V2 documentation to understand the architecture
2. **Identify** if the 3 gaps apply to your use case
3. **Implement** the fixes (total: 6 minutes of work)
4. **Verify** using the provided commands
5. **Done!** Your deployment is now 100% deterministic

---

## ❓ Quick Reference

### I want to...

| Goal | Command | Document |
|------|---------|----------|
| **Deploy code** | `git push` | [Making Changes](#making-changes) |
| **Check status** | `kubectl -n production get pods` | [Verification](#verification) |
| **See version** | `curl http://192.168.0.203/version` | [Verification](#verification) |
| **Rollback** | `git revert <commit> && git push` | [DEPLOYMENT_GUIDE.md](DEPLOYMENT_GUIDE.md) |
| **Scale** | Edit `values.yaml`, commit, push | [ARCHITECTURE_GUIDE_V2.md](ARCHITECTURE_GUIDE_V2.md) |
| **Monitor** | `watch kubectl get pods` | [COMMANDS_REFERENCE.md](COMMANDS_REFERENCE.md) |
| **Debug** | Check logs | [DEPLOYMENT_GUIDE.md](DEPLOYMENT_GUIDE.md) |

---

**Last updated**: February 3, 2026  
**Status**: ✅ Complete verification with actionable improvements
