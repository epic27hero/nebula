# 🚀 GitLab CI/CD Pipeline - Complete Guide V2

**Last Updated**: February 3, 2026  
**Verification Status**: ✅ BUILD & PUSH stages correct, ⚠️ Image handling needs fix

---

## Quick Answer: YES, Changes Will Be Reflected! ✅

When you push changes to FastAPI `main.py`:

```
You push code to GitLab
    ↓
CI/CD detects push (webhook)
    ↓
BUILD: Creates new Docker image with your changes
    ↓
PUSH: Uploads to registry with commit SHA tag
    ↓
K8s: Detects new image tag in registry
    ↓
Rolling Update: Replaces old pods with new ones
    ↓
Your changes are LIVE in production (5-30 seconds)
```

---

## Pipeline Overview

### What GitLab CI Does (At a Glance)

```yaml
Pipeline Stages:
├─ BUILD       → Creates Docker image with new code
├─ PUSH        → Uploads image to registry (immutable)
├─ UPDATE-HELM → Optional: commits new tag to git
├─ DEPLOY      → Tells ArgoCD to sync
├─ RELEASE     → Creates git tag (for releases)
└─ DISCOVERY   → Reports success
```

**Key Property**: Each stage is idempotent. Running pipeline 2x produces same result.

---

## Stage 1: BUILD — Creates Immutable Image

**File**: `.gitlab-ci.yml` lines 65-72

### What BUILD Does

```yaml
build:
  stage: build
  script: |
    echo "🚧 BUILD STAGE"
    BUILD_TIME=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    docker build \
      --no-cache \
      --build-arg APP_VERSION=${CI_COMMIT_TAG:-${CI_COMMIT_SHORT_SHA}} \
      --build-arg BUILD_TIME=${BUILD_TIME} \
      --build-arg IMAGE_TAG=${CI_COMMIT_SHORT_SHA} \
      -t ${IMAGE_NAME}:${IMAGE_TAG} .
    echo "✅ Image built: ${IMAGE_NAME}:${IMAGE_TAG}"
```

### Breaking Down the Build Args

| Arg | Value | Example | Why It Matters |
|-----|-------|---------|----------------|
| `APP_VERSION` | Git tag OR short SHA | `v2.0.16` or `abc1234f` | **Version identification** |
| `BUILD_TIME` | UTC timestamp | `2026-02-03T14:35:20Z` | **Proof of when built** |
| `IMAGE_TAG` | Commit short SHA | `abc1234f` | **Unique image identifier** |

### Breaking Down the Docker Build

```bash
docker build \
  --no-cache \                # Don't use cached layers (fresh build)
  --build-arg APP_VERSION=... \  # Pass version to Dockerfile
  --build-arg BUILD_TIME=... \   # Pass timestamp to Dockerfile
  --build-arg IMAGE_TAG=... \    # Pass image tag to Dockerfile
  -t fastapi-demo:abc1234f .     # Tag image locally
```

### What Happens During BUILD

```
1. Docker reads Dockerfile
2. Sets ARG values from CI/CD
3. Executes each RUN command
   - Installs dependencies
   - Copies application code
   - Creates non-root user
4. Creates image layers
5. Tags with commit SHA: fastapi-demo:abc1234f
6. Image exists locally on CI runner
```

### ✅ BUILD Stage Status: CORRECT

The build stage is working correctly. However, there's a **CRITICAL GAP**: the Dockerfile doesn't capture these build args as ENV variables. See [Gap Analysis](#gap-analysis-dockerfile) below.

---

## Stage 2: PUSH — Makes Image Immutable

**File**: `.gitlab-ci.yml` lines 81-98

### What PUSH Does

```yaml
push:
  stage: push
  script: |
    echo "📤 PUSH STAGE"
    echo "🔑 Login to GitLab Registry"
    echo "${CI_REGISTRY_PASSWORD}" | docker login \
      -u ${CI_REGISTRY_USER} \
      --password-stdin ${CI_REGISTRY}

    FULL_IMAGE="${CI_REGISTRY}/${CI_PROJECT_PATH}/${IMAGE_NAME}:${IMAGE_TAG}"
    echo "🏷 Tagging image"
    docker tag ${IMAGE_NAME}:${IMAGE_TAG} ${FULL_IMAGE}

    echo "📤 Pushing image"
    docker push ${FULL_IMAGE}

    echo "🔍 Verifying image exists"
```

### Breaking Down PUSH

1. **Authenticate** to GitLab Container Registry
   ```bash
   echo "${CI_REGISTRY_PASSWORD}" | docker login \
     -u ${CI_REGISTRY_USER} \
     --password-stdin ${CI_REGISTRY}
   ```
   - Uses GitLab CI/CD variables (secrets)
   - Credentials never appear in logs
   - Authenticates to `registry.gitlab.com` (or private GitLab)

2. **Tag image** for registry
   ```bash
   FULL_IMAGE="192.168.0.190:5005/root/project_nebula/fastapi-demo:abc1234f"
   docker tag fastapi-demo:abc1234f ${FULL_IMAGE}
   ```
   - Local tag: `fastapi-demo:abc1234f`
   - Registry tag: `192.168.0.190:5005/root/project_nebula/fastapi-demo:abc1234f`

3. **Push image** to registry
   ```bash
   docker push 192.168.0.190:5005/root/project_nebula/fastapi-demo:abc1234f
   ```
   - Uploads all layers
   - Registry stores image digest (SHA256)
   - Image is now immutable

### Why PUSH is Critical

Once an image is pushed:
- ✅ Image is immutable (cannot be modified)
- ✅ Image has permanent digest
- ✅ Any Kubernetes cluster can pull it
- ✅ Deployment is reproducible
- ✅ Version is locked to commit SHA

### ✅ PUSH Stage Status: CORRECT

---

## Stage 3: UPDATE-HELM — Updates values.yaml

**File**: `.gitlab-ci.yml` lines 100-124

### What UPDATE-HELM Does

```yaml
update-helm:
  stage: update-helm
  script: |
    echo "📝 Updating Helm values with new image tag"
    sed -i "s|tag: .*|tag: ${CI_COMMIT_SHORT_SHA}|" \
      helm/fastapi-app/values.yaml
    
    git add helm/fastapi-app/values.yaml
    git commit -m "ci: update image tag to ${CI_COMMIT_SHORT_SHA}"
    git push origin ${CI_COMMIT_BRANCH}
```

### Why This Step Exists

**Goal**: Make GitOps source of truth (git) reflect reality (built image)

**Without this**:
- Git has old tag: `tag: ""`
- Registry has new image: `fastapi-demo:abc1234f`
- ArgoCD doesn't know new version exists

**With this**:
- CI updates git: `tag: abc1234f`
- Git webhook triggers ArgoCD
- ArgoCD reads new tag and syncs
- Automatic GitOps cycle completes

### ✅ UPDATE-HELM Stage Status: CORRECT

---

## Stage 4: DEPLOY — Triggers ArgoCD

**File**: `.gitlab-ci.yml` lines 126-145

### What DEPLOY Does

```yaml
deploy:
  stage: deploy
  script: |
    echo "🚀 DEPLOY STAGE"
    # Optional: Call ArgoCD API to force sync
    # argocd app sync fastapi-prod --force
```

### How Deployment Actually Happens

**Automatic** (recommended):
1. CI updates `values.yaml` in git
2. Git webhook notifies ArgoCD
3. ArgoCD detects git change
4. ArgoCD syncs new image tag
5. Kubernetes updates Deployment
6. Rolling update starts automatically

**Manual** (if needed):
```bash
argocd app sync fastapi-prod --force
```

### ✅ DEPLOY Stage Status: CORRECT

---

## Pipeline Variables

**File**: `.gitlab-ci.yml` lines 11-19

### Global Variables

```yaml
variables:
  IMAGE_NAME: fastapi-demo              # Local image name
  IMAGE_TAG: $CI_COMMIT_SHORT_SHA       # Tag = git short SHA
  HELM_VALUES_FILE: helm/fastapi-app/values.yaml
  GIT_STRATEGY: clone                   # Clone repo fresh
  GIT_DEPTH: 0                          # Full history
  REMOTE_SERVER_IP: "192.168.0.113"     # Build server IP
```

### GitLab CI/CD Variables (From Settings)

| Variable | Purpose | Example |
|----------|---------|---------|
| `CI_COMMIT_SHORT_SHA` | 8-char git commit hash | `abc1234f` |
| `CI_COMMIT_BRANCH` | Current branch | `master` or `feature/xyz` |
| `CI_COMMIT_TAG` | Git tag if on a tag | `v2.0.16` |
| `CI_REGISTRY` | GitLab registry URL | `registry.gitlab.com` |
| `CI_REGISTRY_USER` | Registry username | `gitlab-ci-token` |
| `CI_REGISTRY_PASSWORD` | Registry password | (secret) |
| `CI_PROJECT_PATH` | Repo path | `root/project_nebula` |

---

## Workflow Rules

**File**: `.gitlab-ci.yml` lines 26-31

### Rules Control When Pipeline Runs

```yaml
workflow:
  rules:
    - if: $CI_COMMIT_MESSAGE =~ /\[skip ci\]/
      when: never                     # Skip if message has [skip ci]
    - if: $CI_COMMIT_AUTHOR == "GitLab CI/CD"
      when: never                     # Skip if CI itself committed
    - if: $CI_COMMIT_BRANCH
      when: always                    # Run on any branch with commits
```

### What This Means

| Situation | Pipeline Runs? |
|-----------|----------------|
| Manual push to any branch | ✅ Yes |
| Push with commit message `[skip ci]` | ❌ No |
| Automatic CI commit (values update) | ❌ No (prevents loops!) |
| Git tag push | ✅ Yes |

**Why Skip CI on CI Commits?**

Prevents infinite loops:
```
Commit 1: Developer pushes code
  ↓ CI runs, builds image
Commit 2: CI updates values.yaml
  ↓ Should NOT trigger new pipeline!
  ↓ (because it would update values again, causing Commit 3, etc.)
```

---

## Complete Pipeline Trace: Code Change to Production

### Step 1: Developer Pushes Code

```bash
cd /root/project_nebula
echo "new feature" >> src/main.py
git add src/main.py
git commit -m "Add new endpoint"
git push origin master
```

### Step 2: GitLab Receives Push

- Webhook fires
- Pipeline is created
- Checks workflow rules (✅ branch push, ✅ not CI commit, ✅ no skip ci)
- Pipeline starts

### Step 3: BUILD Stage Runs

```yaml
BUILD STAGE:
  ├─ Compute BUILD_TIME = "2026-02-03T14:35:20Z"
  ├─ Read APP_VERSION = git tag or "abc1234f" (short SHA)
  ├─ Execute:
  │  └─ docker build --no-cache \
  │       --build-arg APP_VERSION=abc1234f \
  │       --build-arg BUILD_TIME=2026-02-03T14:35:20Z \
  │       --build-arg IMAGE_TAG=abc1234f \
  │       -t fastapi-demo:abc1234f .
  └─ ✅ Result: Image layer locally with your changes
```

### Step 4: PUSH Stage Runs

```yaml
PUSH STAGE:
  ├─ Login to 192.168.0.190:5005 (GitLab registry)
  ├─ Tag: docker tag fastapi-demo:abc1234f \
           192.168.0.190:5005/root/project_nebula/fastapi-demo:abc1234f
  ├─ Push: docker push 192.168.0.190:5005/...fastapi-demo:abc1234f
  └─ ✅ Result: Image immutably stored in registry
```

### Step 5: UPDATE-HELM Stage Runs

```yaml
UPDATE-HELM STAGE:
  ├─ Edit helm/fastapi-app/values.yaml
  ├─ Change: tag: "" → tag: "abc1234f"
  ├─ git add helm/fastapi-app/values.yaml
  ├─ git commit -m "ci: update image tag to abc1234f"
  ├─ git push origin master
  └─ ✅ Result: Git now shows new image tag
```

**Git webhook fires** → ArgoCD is notified

### Step 6: DEPLOY Stage Runs

```yaml
DEPLOY STAGE:
  └─ [Optional] Call argocd app sync fastapi-prod
     (Usually ArgoCD auto-syncs via webhook)
```

### Step 7: ArgoCD Sync Happens

```
ArgoCD reconciliation loop:
  ├─ Read git: helm/fastapi-app/values.yaml
  ├─ See: image.tag = "abc1234f"
  ├─ Generate K8s manifests from Helm
  ├─ Compare with cluster state
  ├─ Cluster still has tag: "abc1233e" (old)
  ├─ DIFFERENCE DETECTED
  ├─ Apply new Deployment
  └─ ✅ Kubernetes gets new image tag
```

### Step 8: Kubernetes Rolling Update

```
K8s Deployment Controller:
  ├─ Detects spec.template.spec.containers[0].image changed
  ├─ Spec says: image.tag = "abc1234f"
  ├─ Cluster has: 3 pods running tag "abc1233e"
  ├─ Start rolling update:
  │  ├─ Create new Pod with tag "abc1234f"
  │  ├─ Wait for readiness probe: GET /health → 200
  │  ├─ Add to load balancer
  │  ├─ Remove old pod from load balancer
  │  ├─ Terminate old pod
  │  ├─ Repeat for remaining old pods
  └─ ✅ All 3 pods now running tag "abc1234f"
```

### Step 9: Operator Verifies

```bash
curl http://192.168.0.203/version | jq

{
  "app": "fastapi-demo",
  "app_version": "abc1234f",
  "image_tag": "abc1234f",
  "build_time": "2026-02-03T14:35:20Z",
  "pod": "fastapi-app-5b8c7d9f-xyz12",
  "uptime_seconds": 32
}
```

**What This Proves**:
- ✅ Your new code is running
- ✅ Built on 2026-02-03 at 14:35:20Z
- ✅ All 3 pods have same version (consistency)
- ✅ Pod restarted recently (uptime 32s)
- ✅ Build time is consistent across replicas

---

## How Image Tags Work

### Local vs Registry Tags

```
BUILD Stage:
  └─ Image name: fastapi-demo
  └─ Local tag:  fastapi-demo:abc1234f

PUSH Stage:
  └─ Registry image: 192.168.0.190:5005/root/project_nebula/fastapi-demo
  └─ Registry tag:   192.168.0.190:5005/root/project_nebula/fastapi-demo:abc1234f

Helm values.yaml:
  └─ repository: 192.168.0.190:5005/root/project_nebula/fastapi-demo
  └─ tag: abc1234f
  └─ Combined: 192.168.0.190:5005/root/project_nebula/fastapi-demo:abc1234f
```

### Why Use Commit SHA as Tag?

✅ **Advantages**:
- Unique per commit (collision-free)
- Short (8 chars) but globally unique
- Matches git history
- Reproducible
- No manual tagging needed

❌ **Why NOT use `latest`**:
- Mutable (changes every build)
- Breaks reproducibility
- Hard to track which version
- Causes undefined behavior
- Rollback becomes unclear

---

## Gap Analysis: Dockerfile Not Capturing Build Args

### The Problem

```yaml
CI passes build args:
├─ APP_VERSION=abc1234f
├─ BUILD_TIME=2026-02-03T14:35:20Z
└─ IMAGE_TAG=abc1234f

↓ Dockerfile should capture these as ENV

Current Dockerfile (WRONG):
└─ Does NOT declare ARG
└─ Does NOT set ENV
└─ App cannot read these values!

Image result:
└─ APP_VERSION = undefined (app uses fallback "v2.0.16")
└─ BUILD_TIME = undefined (app shows "unknown")
└─ IMAGE_TAG = undefined (app shows "unknown")
└─ ❌ BROKEN DETERMINISM
```

### The Fix

**In Dockerfile**, after `FROM python:3.11-slim` (second stage):

```dockerfile
# Capture build metadata from CI
ARG APP_VERSION
ARG BUILD_TIME
ARG IMAGE_TAG

ENV APP_VERSION=${APP_VERSION} \
    BUILD_TIME=${BUILD_TIME} \
    IMAGE_TAG=${IMAGE_TAG}
```

### After Fix

```yaml
CI passes build args → Dockerfile captures as ENV
↓
Image layers now contain:
  ENV APP_VERSION=abc1234f
  ENV BUILD_TIME=2026-02-03T14:35:20Z
  ENV IMAGE_TAG=abc1234f

↓
Running container:
  os.getenv("APP_VERSION") = "abc1234f" ✅
  os.getenv("BUILD_TIME") = "2026-02-03T14:35:20Z" ✅
  os.getenv("IMAGE_TAG") = "abc1234f" ✅

↓
GET /version endpoint returns REAL values
```

---

## Observability: Watch Pipeline Execute

### Check Pipeline Status

```bash
# From repo root
cd /root/project_nebula

# See running jobs
git log --oneline -5
# Shows: abc1234f Add new endpoint

# Check GitLab CI status (in UI)
# https://gitlab.com/root/project_nebula/-/pipelines
```

### Monitor Pipeline Logs

**In GitLab UI**:
1. Go to repository
2. Click "CI/CD" → "Pipelines"
3. Click pipeline ID
4. Click stage name (BUILD, PUSH, etc.)
5. See real-time logs

**Via CLI** (if GitLab CLI installed):
```bash
gitlab project pipeline list root/project_nebula --status success
gitlab project pipeline list root/project_nebula --status failed
```

### Verify Image in Registry

```bash
# List images in registry
curl -H "Private-Token: <token>" \
  https://192.168.0.190:5005/v2/root/project_nebula/fastapi-demo/tags/list | jq

# Shows: {"name": "root/project_nebula/fastapi-demo", "tags": ["abc1234f", "abc1233e", ...]}
```

### Verify ArgoCD Sync

```bash
# Get ArgoCD app status
argocd app get fastapi-prod

# Shows:
#   Sync Status: Synced
#   Revision: abc1234f
#   Last Sync Result: Success
```

---

## Troubleshooting

### Pipeline Fails at BUILD

**Symptoms**: Docker build fails

**Common Causes**:
- ❌ Python dependency not in `src/requirements.txt`
- ❌ `Dockerfile` syntax error
- ❌ Docker daemon not running on CI runner
- ❌ Network issue accessing PyPI

**Fix**:
1. Check logs in GitLab UI
2. Review `src/requirements.txt`
3. Run locally: `docker build -t test .`

### Pipeline Fails at PUSH

**Symptoms**: Registry authentication fails

**Common Causes**:
- ❌ `CI_REGISTRY_PASSWORD` variable not set
- ❌ Registry credentials expired
- ❌ Network unreachable to registry

**Fix**:
```bash
# Verify credentials in GitLab Settings
Settings → CI/CD → Variables
# Should have:
# - CI_REGISTRY_PASSWORD
# - CI_REGISTRY_USER
```

### Image Not Updating in Cluster

**Symptoms**: `curl /version` shows old tag

**Common Causes**:
- ❌ ArgoCD not syncing (webhook failed)
- ❌ `imagePullPolicy: IfNotPresent` using cached image
- ❌ Wrong image tag in values.yaml

**Fix**:
```bash
# Manual ArgoCD sync
argocd app sync fastapi-prod --force

# Check current values.yaml in git
git show HEAD:helm/fastapi-app/values.yaml | grep tag:

# Force image pull
kubectl rollout restart -n production deploy/fastapi-app
```

---

## References

- [Deterministic Deployment Responsibility Map V2](DETERMINISTIC_DEPLOYMENT_RESPONSIBILITY_MAP_V2.md)
- [Architecture Guide V2](ARCHITECTURE_GUIDE_V2.md)
- [GitOps Enhancements](GITLAB_GITOPS_ENHANCEMENTS.md)
- [Deployment Guide](DEPLOYMENT_GUIDE.md)
