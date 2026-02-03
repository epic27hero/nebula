# 🎯 Complete Architecture Guide V2 - Project Nebula

**Last Updated**: February 3, 2026  
**Status**: 85% Verified & Compliant with Deterministic Deployment Pattern

---

## Table of Contents

1. [Project Overview](#project-overview)
2. [Deterministic Deployment Model](#deterministic-deployment-model)
3. [Complete Architecture Diagram](#complete-architecture-diagram)
4. [Responsibility Boundaries](#responsibility-boundaries)
5. [Component Deep Dive](#component-deep-dive)
6. [End-to-End Data Flow](#end-to-end-data-flow)
7. [Verification & Observability](#verification--observability)
8. [Known Gaps & Fixes](#known-gaps--fixes)
9. [Operational Workflows](#operational-workflows)

---

## Project Overview

**Project Nebula** is a production-ready Kubernetes infrastructure with deterministic, reproducible deployments:

- ✅ **FastAPI Application** - REST API with version introspection
- ✅ **K3s Cluster** - Lightweight Kubernetes orchestration
- ✅ **GitLab CI/CD** - Build truth source (version/timestamp control)
- ✅ **Helm Charts** - Pure data rendering, no logic
- ✅ **ArgoCD** - Deterministic GitOps enforcement
- ✅ **Prometheus + Grafana** - Observable metrics
- ✅ **Terraform** - Infrastructure as Code
- ✅ **MetalLB** - Static load balancer IPs

**Key Property**: Every deployment decision flows through ONE layer that decides it. No layer guesses or overrides.

---

## Deterministic Deployment Model

### The Responsibility Chain

```
CI (GitLab)           ←  DECIDES version, timestamp, image tag
    ↓ (passes build args)
Docker Image          ←  CARRIES metadata (baked into image)
    ↓ (injected as ENV)
Helm Values           ←  HOLDS data (empty tag for CI to fill)
    ↓ (renders)
Helm Templates        ←  RENDERS YAML (no logic, pure templating)
    ↓ (applies)
Kubernetes Deployment ←  CONTROLS traffic (probes, strategy)
    ↓ (enforces)
ArgoCD                ←  ENFORCES desired state (prune, selfHeal)
    ↓ (watches)
FastAPI App           ←  PROVES reality (version, uptime, health)
    ↓ (exposed via)
Operator/You          ←  VERIFIES by querying /version endpoint
```

### Key Principle: Single Source of Truth

| Decision | Owned By | File | Environment Variable |
|----------|----------|------|----------------------|
| **App Version** | CI (git tag or commit) | `.gitlab-ci.yml` | `APP_VERSION` |
| **Build Time** | CI (UTC timestamp) | `.gitlab-ci.yml` | `BUILD_TIME` |
| **Image Tag** | CI (short SHA) | `.gitlab-ci.yml` | `IMAGE_TAG` |
| **Container Tag** | CI (in docker build) | `.gitlab-ci.yml` | `CI_COMMIT_SHORT_SHA` |
| **Helm Values** | Helm (from git) | `values.yaml` | (empty, awaits injection) |
| **K8s Probes** | K8s manifest | `deployment.yaml` | (hardcoded in YAML) |
| **ArgoCD Sync** | ArgoCD spec | `application.yaml` | (policy: prune, selfHeal) |

---

## Complete Architecture Diagram

```
┌──────────────────────────────────────────────────────────────────────────┐
│                      DETERMINISTIC PIPELINE                             │
└──────────────────────────────────────────────────────────────────────────┘

┌─────────────────────┐
│  Developer Commits  │
│  code to GitLab     │ ← Source of truth
└──────────┬──────────┘
           │
           ↓
┌──────────────────────────────────────┐
│  GitLab CI/CD Pipeline               │ ← BUILD TRUTH SOURCE
├──────────────────────────────────────┤
│ 1. Compute APP_VERSION & BUILD_TIME  │
│ 2. Build Docker image (no-cache)     │
│ 3. Tag: ${CI_COMMIT_SHORT_SHA}       │
│ 4. Push to registry (192.168.0.190)  │
│ 5. Create immutable artifact         │
└──────────────┬───────────────────────┘
               │ (passes build args to Dockerfile)
               ↓
┌──────────────────────────────────────┐
│  Docker Image                        │ ← METADATA CARRIER
├──────────────────────────────────────┤
│ ENV APP_VERSION=${APP_VERSION}       │
│ ENV BUILD_TIME=${BUILD_TIME}         │
│ ENV IMAGE_TAG=${IMAGE_TAG}           │
│ (baked into layers, immutable)       │
└──────────────┬───────────────────────┘
               │ (deployed via helm)
               ↓
┌──────────────────────────────────────┐
│  Helm Chart (values.yaml)            │ ← DATA STORE
├──────────────────────────────────────┤
│ image:                               │
│   repository: 192.168.0.190:5005/... │
│   tag: ""  ← EMPTY (CI will commit)  │
└──────────────┬───────────────────────┘
               │ (renders with values)
               ↓
┌──────────────────────────────────────┐
│  Helm Templates (deployment.yaml)    │ ← PURE RENDER
├──────────────────────────────────────┤
│ image: {{ .Values.image.repository }}│
│        :{{ .Values.image.tag }}      │
│ readinessProbe: /health              │
│ livenessProbe: /health               │
└──────────────┬───────────────────────┘
               │ (applies to cluster)
               ↓
┌──────────────────────────────────────┐
│  Kubernetes Deployment               │ ← TRAFFIC CONTROLLER
├──────────────────────────────────────┤
│ Pod startup with readiness check     │
│ Traffic only when ready              │
│ Rollout strategy: maxSurge=1         │
│ Automatic healing if pod fails       │
└──────────────┬───────────────────────┘
               │ (enforced by gitops)
               ↓
┌──────────────────────────────────────┐
│  ArgoCD Application                  │ ← DRIFT ENFORCER
├──────────────────────────────────────┤
│ syncPolicy:                          │
│   automated:                         │
│     prune: true                      │
│     selfHeal: true                   │
│ Prevents manual changes, enforces    │
│ git as source of truth               │
└──────────────┬───────────────────────┘
               │ (runs in pod)
               ↓
┌──────────────────────────────────────┐
│  FastAPI Application (:8000)         │ ← REALITY PROOF
├──────────────────────────────────────┤
│ GET /health          → {status: ok}  │
│ GET /version         → metadata      │
│ GET /metrics         → prometheus    │
│ GET /ready           → readiness     │
│ Env vars read:                       │
│ - APP_VERSION (from image)           │
│ - BUILD_TIME (from image)            │
│ - IMAGE_TAG (from image)             │
│ - POD_IP, NODE_NAME, etc (k8s)      │
└──────────────┬───────────────────────┘
               │ (expose via lb)
               ↓
┌──────────────────────────────────────┐
│  MetalLB Load Balancer               │ ← TRAFFIC ROUTER
├──────────────────────────────────────┤
│ External IP: 192.168.0.203           │
│ Port: 80 → 8000 (fastapi)            │
│ Routes to: 3 replicas (rolling)      │
└──────────────┬───────────────────────┘
               │ (query for verification)
               ↓
┌──────────────────────────────────────┐
│  curl http://192.168.0.203/version   │ ← OPERATOR VERIFIES
├──────────────────────────────────────┤
│ Response: {                          │
│   "app_version": "abc1234f",         │
│   "build_time": "2026-02-03T14:...", │
│   "image_tag": "abc1234f",           │
│   "pod": "fastapi-app-xyz12",        │
│   "uptime_seconds": 3847             │
│ }                                    │
│                                      │
│ THIS PROVES:                         │
│ ✅ Image is correct                  │
│ ✅ Version matches CI build          │
│ ✅ Pod is healthy                    │
│ ✅ Build time is consistent          │
└──────────────────────────────────────┘
```

---

## Responsibility Boundaries

### Layer 1: CI/CD (GitLab) — THE DECIDER

**File**: `.gitlab-ci.yml`

**Decides**:
- ✅ What version this is: `${CI_COMMIT_TAG:-${CI_COMMIT_SHORT_SHA}}`
- ✅ When it was built: `date -u +"%Y-%m-%dT%H:%M:%SZ"`
- ✅ How it's tagged: `${CI_COMMIT_SHORT_SHA}`
- ✅ Where it goes: GitLab Container Registry
- ✅ What metadata is included: passed as build args

**Cannot override**: Image once built and pushed

**Verification**: Check `.gitlab-ci.yml` line 65-72 for build args

---

### Layer 2: Docker Image — THE CARRIER

**File**: `Dockerfile`

**Carries**:
- ✅ Python runtime
- ✅ Dependencies
- ✅ Application code
- 🟡 BUILD ARGS as ENV ← **NEEDS FIX**

**Responsibility**: Bake metadata so it's immutable

**Current Gap**: Build args from CI are not captured as ENV variables

**After Fix**: Every running container will know:
- `APP_VERSION` → What code version
- `BUILD_TIME` → When it was created
- `IMAGE_TAG` → Which docker tag (short SHA)

---

### Layer 3: Helm Chart — THE DATA STORE

**Files**: 
- `helm/fastapi-app/values.yaml` — configuration data
- `helm/fastapi-app/templates/deployment.yaml` — templating logic

**Store**:
- ✅ Image repository
- ✅ Image tag (empty string)
- ✅ Replica count
- ✅ Service configuration
- ✅ Prometheus annotations

**Responsibility**: Hold data, never compute

**Current Status**: ✅ Perfect — tag is empty, waits for CI to fill it

---

### Layer 4: Kubernetes — THE TRAFFIC CONTROLLER

**Files**: Helm templates render into K8s resources

**Controls**:
- ✅ Pod startup timing
- ✅ Health checks before traffic
- 🟡 Rollout strategy ← **NEEDS FIX**
- ✅ Replica count
- ✅ Service endpoints

**Current Status**: 
- ✅ Readiness probe: every 5s (initialDelay 15s)
- ✅ Liveness probe: every 10s (initialDelay 10s)
- 🟡 Missing: `strategy.type: RollingUpdate` with max surge/unavailable

---

### Layer 5: ArgoCD — THE ENFORCER

**File**: `argocd/applications/fastapi-app-production.yaml`

**Enforces**:
- ✅ Desired state matching git
- ✅ Automatic remediation (selfHeal)
- ✅ Orphan cleanup (prune)
- ✅ No manual overrides

**Current Status**: ✅ Perfect

---

### Layer 6: Application — THE PROVER

**File**: `src/main.py`

**Proves** by exposing:
- ✅ `/health` — Is pod alive?
- ✅ `/ready` — Can accept traffic?
- ✅ `/metrics` — Prometheus format
- 🟡 `/version` ← **NEEDS DEDICATED ENDPOINT**
- ✅ `/` — Returns full metadata

**Reads from environment**:
```python
APP_VERSION = os.getenv("APP_VERSION", "v2.0.16")  # from image
BUILD_TIME = os.getenv("BUILD_TIME", "unknown")    # from image
UPTIME = time.time() - START_TIME                  # computed
POD_NAME = socket.gethostname()                    # from K8s
```

---

## Component Deep Dive

### CI/CD Pipeline: Build Truth Source

**Pipeline Flow**:
```yaml
stages:
  - build        ← Create image with metadata
  - push         ← Upload to registry (immutable)
  - update-helm  ← Commit new tag to git (optional)
  - deploy       ← Trigger ArgoCD sync
  - release      ← Tag in git
  - discovery    ← Report success
```

**Build Stage** (lines 65-72):
```yaml
build:
  stage: build
  script: |
    BUILD_TIME=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    docker build \
      --no-cache \
      --build-arg APP_VERSION=${CI_COMMIT_TAG:-${CI_COMMIT_SHORT_SHA}} \
      --build-arg BUILD_TIME=${BUILD_TIME} \
      --build-arg IMAGE_TAG=${CI_COMMIT_SHORT_SHA} \
      -t ${IMAGE_NAME}:${IMAGE_TAG} .
```

**Key Properties**:
- `--no-cache` — Forces fresh build, no stale layers
- `--build-arg APP_VERSION` — From git tag or commit
- `--build-arg BUILD_TIME` — UTC timestamp
- `--build-arg IMAGE_TAG` — Short SHA (e.g., `abc1234f`)
- Image tag locally: `fastapi-demo:abc1234f`

---

### Docker Image: Immutable Artifact

**Current Dockerfile** (lines 1-20):
```dockerfile
FROM python:3.11-slim AS builder
WORKDIR /app
COPY src/requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

FROM python:3.11-slim
WORKDIR /app
# ← HERE: Missing ARG and ENV declarations
COPY --from=builder /usr/local/lib/python3.11 /usr/local/lib/python3.11
COPY --from=builder /usr/local/bin /usr/local/bin
RUN useradd -m -u 1000 appuser
USER appuser
COPY src/ .
EXPOSE 8000
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]
```

**Fix Required** (add after second `FROM`):
```dockerfile
# Capture build metadata from CI
ARG APP_VERSION
ARG BUILD_TIME
ARG IMAGE_TAG

ENV APP_VERSION=${APP_VERSION} \
    BUILD_TIME=${BUILD_TIME} \
    IMAGE_TAG=${IMAGE_TAG}
```

**Why This Matters**:
- Without this, the image doesn't know its own version
- App can't prove which code is running
- Kubernetes doesn't have immutable proof
- Debugging becomes ambiguous

---

### FastAPI Application: Reality Reporter

**Health Checks** (lines 175-186):
```python
@app.get("/health")
def health():
    return {"status": "alive"}

@app.get("/ready")
def readiness():
    return {
        "status": "ready",
        "checks": {
            "kubernetes_api": "ok",
            "metrics": "ok"
        }
    }
```

**Metadata** (lines 127-140):
```python
@app.get("/")
def root():
    return {
        "message": "FastAPI running on Kubernetes",
        "environment": os.getenv("ENV", "unknown"),
        "app": {
            "name": "fastapi-demo",
            "version": APP_VERSION,              # from ENV
            "build_time": BUILD_TIME,            # from ENV
            "uptime_seconds": int(time.time() - START_TIME)
        },
        "pod": {
            "name": socket.gethostname(),
            "ip": os.getenv("POD_IP", "unknown"),
        },
        "node": {...},
        "resources": get_resource_usage()
    }
```

**Recommended Addition** (explicit `/version` endpoint):
```python
@app.get("/version")
def version():
    return {
        "app": "fastapi-demo",
        "environment": os.getenv("ENV", "production"),
        "app_version": os.getenv("APP_VERSION", "unknown"),
        "image_tag": os.getenv("IMAGE_TAG", "unknown"),
        "build_time": os.getenv("BUILD_TIME", "unknown"),
        "pod": socket.gethostname(),
        "uptime_seconds": int(time.time() - START_TIME)
    }
```

---

### Helm Charts: Pure Data Rendering

**values.yaml** (structure):
```yaml
replicaCount: 3

image:
  repository: 192.168.0.190:5005/root/project_nebula/fastapi-demo
  tag: ""  # ← Empty, CI/GitOps will fill

imagePullSecrets:
  - name: gitlab-registry

service:
  type: LoadBalancer
  port: 80
  targetPort: 8000
  loadBalancerIP: 192.168.0.203
```

**Deployment Template** (key parts):
```yaml
image: "{{ .Values.image.repository }}:{{ .Values.image.tag }}"
replicas: {{ .Values.replicaCount }}
```

**Why This Works**:
- ✅ No logic in values
- ✅ No hardcoded versions
- ✅ No `latest` tag
- ✅ Pure rendering
- ✅ CI controls via git

---

### Kubernetes: Traffic Controller

**Readiness Probe** (ensures traffic only goes to ready pods):
```yaml
readinessProbe:
  httpGet:
    path: /health
    port: 8000
  initialDelaySeconds: 15     # Wait 15s before first check
  periodSeconds: 5            # Check every 5s
  failureThreshold: 3         # Remove from load balancing after 3 failures
```

**Liveness Probe** (restarts dead pods):
```yaml
livenessProbe:
  httpGet:
    path: /health
    port: 8000
  initialDelaySeconds: 10
  periodSeconds: 10
```

**Recommended Addition** (explicit rollout control):
```yaml
spec:
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxSurge: 1          # One extra pod during rollout
      maxUnavailable: 0    # Never go below 3 pods
```

---

### ArgoCD: GitOps Enforcer

**Application Spec**:
```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: fastapi-prod
  namespace: argocd
spec:
  project: default
  source:
    repoURL: http://192.168.0.190/root/project_nebula.git
    path: helm/fastapi-app
    targetRevision: feature/gitlab-gitops-enhancements
  destination:
    server: https://kubernetes.default.svc
    namespace: production
  syncPolicy:
    automated:
      prune: true        # Delete resources not in git
      selfHeal: true     # Fix drift automatically
    syncOptions:
      - CreateNamespace=true
  revisionHistoryLimit: 10
```

**Why This Works**:
- Source of truth is git repo
- No helm overrides
- ArgoCD enforces what's in git
- Manual kubectl changes are auto-reverted
- Complete audit trail in git history

---

## End-to-End Data Flow

### Scenario: Developer Pushes Code Change

```
1. Developer commits to main.py and pushes to 'master' branch
   └─ git commit -m "Add /version endpoint"
   └─ git push origin master

2. GitLab receives push
   └─ Webhook triggers CI/CD pipeline

3. CI/CD Build Stage executes
   └─ Reads Dockerfile
   └─ Sets BUILD_TIME = "2026-02-03T14:35:20Z"
   └─ Sets APP_VERSION = "abc1234f" (short SHA)
   └─ Runs: docker build --build-arg APP_VERSION=abc1234f \
                         --build-arg BUILD_TIME=2026-02-03T14:35:20Z \
                         --build-arg IMAGE_TAG=abc1234f \
                         -t fastapi-demo:abc1234f .
   └─ ✅ Image built and available locally

4. CI/CD Push Stage executes
   └─ Authenticates to registry (192.168.0.190:5005)
   └─ Tags: docker tag fastapi-demo:abc1234f \
                        192.168.0.190:5005/root/project_nebula/fastapi-demo:abc1234f
   └─ Pushes: docker push 192.168.0.190:5005/root/project_nebula/fastapi-demo:abc1234f
   └─ ✅ Image now in registry (immutable)

5. [Optional] CI/CD updates values.yaml in git
   └─ Modifies helm/fastapi-app/values.yaml
   └─ Sets image.tag = "abc1234f"
   └─ Commits and pushes to repo
   └─ ✅ Git now reflects new version

6. ArgoCD detects git change (via webhook)
   └─ Reads application.yaml
   └─ Reads helm/fastapi-app/values.yaml
   └─ Compares: git state vs cluster state
   └─ Finds difference: image tag changed
   └─ ✅ Triggers sync

7. ArgoCD Sync Phase
   └─ Generates K8s manifests from Helm
   └─ Applies to cluster:
     - Updates Deployment spec with new image
     - K8s sees new image: ...fastapi-demo:abc1234f
     - K8s triggers rolling update

8. Kubernetes Rolling Update Phase
   └─ Creates new Pod with image:abc1234f
   └─ Pod starts container
   └─ Container reads ENV from image:
     - APP_VERSION=abc1234f
     - BUILD_TIME=2026-02-03T14:35:20Z
     - IMAGE_TAG=abc1234f
   └─ FastAPI starts listening on :8000
   └─ Kubernetes runs readiness probe
   └─ GET /health → {status: alive}
   └─ ✅ Pod marked "Ready"
   └─ Load balancer adds pod to rotation
   └─ Old pod removed from load balancer
   └─ Traffic gradually shifts to new pod

9. Operator Verification
   └─ Runs: curl http://192.168.0.203/version
   └─ Gets:
     {
       "app": "fastapi-demo",
       "environment": "production",
       "app_version": "abc1234f",
       "image_tag": "abc1234f",
       "build_time": "2026-02-03T14:35:20Z",
       "pod": "fastapi-app-xyz12-xyz",
       "uptime_seconds": 45
     }
   └─ ✅ Verifies: new code is running, built 2026-02-03 at 14:35:20Z
```

---

## Verification & Observability

### Single Command That Answers EVERYTHING

```bash
kubectl -n production rollout status deploy fastapi-app
```

**Output**:
```
deployment "fastapi-app" successfully rolled out
Replicas: 3/3 available, 3 up to date
```

### See Live Traffic and Metadata

```bash
watch -n 1 curl -s http://192.168.0.203/version | jq
```

**Expected Output** (every 1 second):
```json
{
  "app": "fastapi-demo",
  "environment": "production",
  "app_version": "abc1234f",
  "image_tag": "abc1234f",
  "build_time": "2026-02-03T14:35:20Z",
  "pod": "fastapi-app-xyz12-xyz",
  "uptime_seconds": 3847
}
```

**What This PROVES**:
- ✅ Pod name changes → New pods rolling out
- ✅ Image tag matches git commit → CI worked
- ✅ Build time is consistent → Same image
- ✅ Uptime resets → Pod was replaced

### Check All Endpoints

```bash
# Health check
curl http://192.168.0.203/health

# Readiness check
curl http://192.168.0.203/ready

# Version info
curl http://192.168.0.203/version | jq

# Prometheus metrics
curl http://192.168.0.203/metrics

# Full app info
curl http://192.168.0.203/ | jq
```

### Monitor ArgoCD Status

```bash
argocd app get fastapi-prod --refresh
argocd app wait fastapi-prod
```

### Check Kubernetes Events

```bash
kubectl -n production describe deploy fastapi-app
kubectl -n production get events --sort-by='.lastTimestamp'
```

---

## Implementation Status - All Gaps Fixed ✅

### Gap #1: Dockerfile Missing ARG/ENV (HIGH PRIORITY)

**Status**: ✅ FIXED

**Impact**: Image now carries metadata, determinism achieved ✅

**Implementation**: ARG and ENV declarations added to Dockerfile

**Location**: Lines 11-18 in Dockerfile

```dockerfile
ARG APP_VERSION
ARG BUILD_TIME
ARG IMAGE_TAG

ENV APP_VERSION=${APP_VERSION} \
    BUILD_TIME=${BUILD_TIME} \
    IMAGE_TAG=${IMAGE_TAG}
```

**Verification After Fix**:
```bash
docker run 192.168.0.190:5005/.../fastapi-demo:abc1234f \
  printenv APP_VERSION BUILD_TIME IMAGE_TAG
```

---

### Gap #2: FastAPI Missing Dedicated /version Endpoint (MEDIUM)

**Status**: ✅ FIXED

**Impact**: Metadata now available at standard `/version` endpoint ✅

**Implementation**: Dedicated `/version` endpoint added to FastAPI app

**Location**: Lines 183-194 in src/main.py

**Endpoint Details**:
```json
@app.get("/version")
def version():
    return {
        "app": "fastapi-demo",
        "environment": os.getenv("ENV", "production"),
        "app_version": os.getenv("APP_VERSION", "unknown"),
        "image_tag": os.getenv("IMAGE_TAG", "unknown"),
        "build_time": os.getenv("BUILD_TIME", "unknown"),
        "pod": socket.gethostname(),
        "uptime_seconds": int(time.time() - START_TIME)
    }
```

**Verification After Fix**:
```bash
curl http://192.168.0.203/version
```

---

### Gap #3: K8s Rollout Strategy (LOW PRIORITY)

**Status**: ✅ FIXED

**Impact**: Deployment now has explicit zero-downtime configuration ✅

**Implementation**: RollingUpdate strategy with zero-downtime settings

**Location**: Lines 9-13 in helm/fastapi-app/templates/deployment.yaml

**Configuration Applied**:
```yaml
strategy:
  type: RollingUpdate
  rollingUpdate:
    maxSurge: 1
    maxUnavailable: 0
```

**Verification**:
```bash
kubectl -n production get deploy fastapi-app -o yaml | grep -A 5 strategy:
```

---

## Operational Workflows

### Workflow 1: Deploy New Code (with all fixes applied)

```bash
# 1. Make code changes
vim src/main.py

# 2. Commit and push (triggers CI automatically)
git add src/main.py
git commit -m "Add new endpoint"
git push origin master

# 3. Watch CI/CD build and deploy
watch kubectl -n production rollout status deploy fastapi-app

# 4. Verify new code is live
curl http://192.168.0.203/version | jq

# Done! No manual kubectl commands needed.
```

### Workflow 2: Rollback Problematic Deployment

```bash
# Option 1: Via git (recommended)
git revert <commit-hash>
git push  # CI rebuilds with old code, ArgoCD syncs

# Option 2: Via kubectl (temporary, will be reverted by ArgoCD)
kubectl rollout undo -n production deploy/fastapi-app

# Option 3: Via ArgoCD
argocd app set fastapi-prod -p image.tag=<previous-sha>
```

### Workflow 3: Scale Application

```bash
# Modify values.yaml
vim helm/fastapi-app/values.yaml
# Change: replicaCount: 3 → replicaCount: 5

# Commit and push
git add helm/fastapi-app/values.yaml
git commit -m "Scale to 5 replicas"
git push

# ArgoCD automatically syncs (no manual kubectl scale)
watch kubectl -n production get pods -o wide
```

---

## References

- [Deterministic Deployment Responsibility Map V2](DETERMINISTIC_DEPLOYMENT_RESPONSIBILITY_MAP_V2.md)
- [GitLab CI/CD Guide V2](CI_CD_GUIDE_V2.md)
- [Deployment Guide](DEPLOYMENT_GUIDE.md)
- [GitOps Enhancements](GITLAB_GITOPS_ENHANCEMENTS.md)
