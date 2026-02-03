# ✅ Implementation Checklist - Deterministic Architecture Fixes

**Date**: February 3, 2026  
**Priority**: HIGH (Gap #1), MEDIUM (Gap #2), LOW (Gap #3)  
**Estimated Time**: 30 minutes for all 3 fixes

---

## 🎯 Overview

Your architecture is **deterministic in design** but has **3 gaps in implementation**. This checklist provides exact line-by-line fixes.

**After completing this checklist, your system will have:**
- ✅ Images that know their own metadata
- ✅ Apps that prove what version is running
- ✅ Zero-downtime deployments
- ✅ Complete Git-to-metrics traceability

---

## 🔴 Gap #1: Dockerfile Missing Build Arguments (HIGH PRIORITY)

### Current State
```dockerfile
# File: /root/project_nebula/Dockerfile
# Lines 1-20

FROM python:3.11-slim AS builder
WORKDIR /app
COPY src/requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

FROM python:3.11-slim
WORKDIR /app

COPY --from=builder /usr/local/lib/python3.11 /usr/local/lib/python3.11
COPY --from=builder /usr/local/bin /usr/local/bin

RUN useradd -m -u 1000 appuser
USER appuser

COPY src/ .
EXPOSE 8000

CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]
```

### ❌ What's Wrong
- NO `ARG` declarations for build arguments
- NO `ENV` statements to make them available at runtime
- Image doesn't know its version, build time, or tag

### ✅ What You Need to Add

**Insert AFTER line 7 (after `FROM python:3.11-slim`), BEFORE `WORKDIR /app`:**

```dockerfile
# Build arguments (injected from CI pipeline)
ARG APP_VERSION
ARG BUILD_TIME
ARG IMAGE_TAG

# Make available at runtime
ENV APP_VERSION=${APP_VERSION}
ENV BUILD_TIME=${BUILD_TIME}
ENV IMAGE_TAG=${IMAGE_TAG}
```

### Complete Fixed Version

```dockerfile
# Build stage
FROM python:3.11-slim AS builder
WORKDIR /app
COPY src/requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Final image
FROM python:3.11-slim

# Build arguments (injected from CI pipeline)
ARG APP_VERSION
ARG BUILD_TIME
ARG IMAGE_TAG

# Make available at runtime
ENV APP_VERSION=${APP_VERSION}
ENV BUILD_TIME=${BUILD_TIME}
ENV IMAGE_TAG=${IMAGE_TAG}

WORKDIR /app

# Copy python libs AND executables
COPY --from=builder /usr/local/lib/python3.11 /usr/local/lib/python3.11
COPY --from=builder /usr/local/bin /usr/local/bin

RUN useradd -m -u 1000 appuser
USER appuser

COPY src/ .
EXPOSE 8000

CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]
```

### ✔️ How to Test

```bash
# Build with arguments
docker build \
  --no-cache \
  --build-arg APP_VERSION=v2.0.16 \
  --build-arg BUILD_TIME=$(date -u +"%Y-%m-%dT%H:%M:%SZ") \
  --build-arg IMAGE_TAG=abc1234 \
  -t fastapi-demo:abc1234 .

# Verify environment variables exist
docker run --rm fastapi-demo:abc1234 \
  sh -c 'echo "APP_VERSION=$APP_VERSION"'
# Expected output: APP_VERSION=v2.0.16

docker run --rm fastapi-demo:abc1234 \
  sh -c 'echo "IMAGE_TAG=$IMAGE_TAG"'
# Expected output: IMAGE_TAG=abc1234

docker run --rm fastapi-demo:abc1234 \
  sh -c 'echo "BUILD_TIME=$BUILD_TIME"'
# Expected output: BUILD_TIME=2026-02-03T...
```

### 📝 CI Pipeline Update (Already Correct)

Your `.gitlab-ci.yml` already has this:
```yaml
docker build \
  --no-cache \
  --build-arg APP_VERSION=${CI_COMMIT_TAG:-${CI_COMMIT_SHORT_SHA}} \
  --build-arg BUILD_TIME=${BUILD_TIME} \
  --build-arg IMAGE_TAG=${CI_COMMIT_SHORT_SHA} \
  -t ${IMAGE_NAME}:${IMAGE_TAG} .
```

✅ This is correct and stays as-is.

---

## 🟡 Gap #2: Missing `/version` Endpoint (MEDIUM PRIORITY)

### Current State

```python
# File: /root/project_nebula/src/main.py
# Lines 1-180

# ... imports and setup ...

@app.get("/")
def root():
    hostname = socket.gethostname()
    return {
        "message": "FastAPI running on Kubernetes",
        "environment": os.getenv("ENV", "unknown"),
        "app": {
            "name": APP_NAME,
            "version": APP_VERSION,
            "build_time": BUILD_TIME,
            "uptime_seconds": int(time.time() - START_TIME)
        },
        "pod": {
            "name": hostname,
            "ip": os.getenv("POD_IP", "unknown"),
            # ... other fields ...
        },
    }

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

@app.get("/metrics")
def metrics():
    return Response(generate_latest(), media_type="text/plain")
```

### ❌ What's Wrong
- No dedicated `/version` endpoint
- Version metadata is in `/` (root) endpoint
- Best practice is to have explicit `/version` for observability

### ✅ What You Need to Add

**Insert AFTER the `/ready` endpoint, BEFORE the `/metrics` endpoint:**

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

### Complete Updated Section

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


@app.get("/metrics")
def metrics():
    return Response(
        generate_latest(),
        media_type="text/plain"
    )
```

### ✔️ How to Test

```bash
# After deploying with updated image:
curl http://192.168.0.203/version

# Expected output:
{
  "app": "fastapi-demo",
  "environment": "production",
  "app_version": "abc1234",
  "image_tag": "abc1234",
  "build_time": "2026-02-03T14:30:00Z",
  "pod": "fastapi-app-7d5f9c2b9-xxxxx",
  "uptime_seconds": 45
}
```

### Prometheus Scrape Integration

Add to your pod annotations in `helm/fastapi-app/values.yaml`:
```yaml
podAnnotations:
  prometheus.io/scrape: "true"
  prometheus.io/port: "8000"
  prometheus.io/path: "/metrics"
```

✅ This is already in your values.yaml (line 33-35).

---

## 🟢 Gap #3: Missing Rolling Update Strategy (LOW PRIORITY)

### Current State

```yaml
# File: /root/project_nebula/helm/fastapi-app/templates/deployment.yaml
# Lines 1-30

apiVersion: apps/v1
kind: Deployment
metadata:
  name: fastapi-app
  labels:
    app.kubernetes.io/name: fastapi-app
spec:
  replicas: {{ .Values.replicaCount }}
  selector:
    matchLabels:
      app: fastapi
      app.kubernetes.io/name: fastapi-app
  template:
    metadata:
      labels:
        app: fastapi
        app.kubernetes.io/name: fastapi-app
      {{- with .Values.podAnnotations }}
      annotations:
        {{- toYaml . | nindent 8 }}
      {{- end }}
    spec:
      # ... rest of deployment ...
```

### ❌ What's Wrong
- No `strategy` section
- Kubernetes uses defaults (acceptable, but not explicit)
- No explicit control over surge/unavailable pods during updates

### ✅ What You Need to Add

**Insert AFTER `spec:` (after line ~27), BEFORE `imagePullSecrets:`:**

```yaml
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxSurge: 1
      maxUnavailable: 0
```

### Complete Updated Section

```yaml
spec:
  replicas: {{ .Values.replicaCount }}
  selector:
    matchLabels:
      app: fastapi
      app.kubernetes.io/name: fastapi-app
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxSurge: 1
      maxUnavailable: 0
  template:
    metadata:
      labels:
        app: fastapi
        app.kubernetes.io/name: fastapi-app
      {{- with .Values.podAnnotations }}
      annotations:
        {{- toYaml . | nindent 8 }}
      {{- end }}
    spec:
      # ... rest of deployment ...
```

### ✔️ How to Test

```bash
# Check deployment strategy
kubectl get deployment fastapi-app -n production -o yaml | grep -A 5 "strategy:"

# Expected output:
# strategy:
#   rollingUpdate:
#     maxSurge: 1
#     maxUnavailable: 0
#   type: RollingUpdate

# Verify during deployment
watch kubectl get pods -n production

# Should see:
# • 2/3 ready (1 new pod starting)
# • Then 3/3 ready (new pod ready)
# • Then 2/3 ready (old pod terminating)
# • Finally 3/3 ready (rollout complete)
# NO downtime at any point
```

---

## 📋 Implementation Steps (All 3 Gaps)

### Phase 1: Prepare (5 minutes)

- [ ] Clone/pull latest `master` branch
- [ ] Create a new branch: `git checkout -b fix/deterministic-gaps`

### Phase 2: Fix Gap #1 - Dockerfile (5 minutes)

- [ ] Open `/root/project_nebula/Dockerfile`
- [ ] Add ARG declarations after `FROM python:3.11-slim` (final stage)
- [ ] Add ENV declarations mapping ARGs
- [ ] Save file
- [ ] Verify syntax: `docker build --dry-run .` (if available)

### Phase 3: Fix Gap #2 - /version Endpoint (10 minutes)

- [ ] Open `/root/project_nebula/src/main.py`
- [ ] Add `/version` endpoint after `@app.get("/ready")`
- [ ] Verify imports at top: `os`, `socket`, `time` (already there)
- [ ] Save file
- [ ] Test locally: `python -c "from src.main import app; import json; print(json.dumps(app.routes, indent=2))"`

### Phase 4: Fix Gap #3 - Rollout Strategy (5 minutes)

- [ ] Open `/root/project_nebula/helm/fastapi-app/templates/deployment.yaml`
- [ ] Add `strategy` section after `selector`
- [ ] Verify YAML indentation (2 spaces)
- [ ] Save file
- [ ] Validate: `helm lint helm/fastapi-app/`

### Phase 5: Commit & Push (5 minutes)

```bash
# Stage all changes
git add Dockerfile src/main.py helm/fastapi-app/templates/deployment.yaml

# Commit
git commit -m "fix: implement deterministic architecture gaps

- Add build args to Dockerfile (ARG APP_VERSION, BUILD_TIME, IMAGE_TAG)
- Add /version endpoint to FastAPI app
- Add explicit rolling update strategy to deployment

Implements fixes for:
- Gap #1 (HIGH): Dockerfile missing build argument declarations
- Gap #2 (MEDIUM): Missing /version endpoint for observability
- Gap #3 (LOW): Explicit rollout strategy configuration"

# Push
git push -u origin fix/deterministic-gaps

# Wait for CI pipeline to complete
```

### Phase 6: Verify (10 minutes)

```bash
# Option A: After CI/CD completes
curl http://192.168.0.203/version

# Option B: Test locally
docker build \
  --build-arg APP_VERSION=v2.0.16 \
  --build-arg BUILD_TIME=$(date -u +"%Y-%m-%dT%H:%M:%SZ") \
  --build-arg IMAGE_TAG=test-version \
  -t fastapi-demo:test-version .

docker run -d --rm \
  -e ENV=test \
  --name test-app \
  fastapi-demo:test-version

sleep 3
curl http://localhost:8000/version
docker kill test-app
```

---

## 🔍 Quick Checklist

### Dockerfile Changes
- [ ] File: `/root/project_nebula/Dockerfile`
- [ ] Location: After `FROM python:3.11-slim` (second stage)
- [ ] Add: 8 lines (ARG x3, ENV x3, blank lines)
- [ ] Verify: `docker build ... --build-arg ...` works

### src/main.py Changes
- [ ] File: `/root/project_nebula/src/main.py`
- [ ] Location: After `@app.get("/ready")` endpoint
- [ ] Add: `@app.get("/version")` endpoint (14 lines)
- [ ] Verify: `curl http://localhost:8000/version` returns metadata

### Deployment Template Changes
- [ ] File: `/root/project_nebula/helm/fastapi-app/templates/deployment.yaml`
- [ ] Location: After `selector:` in `spec:`
- [ ] Add: `strategy:` section (5 lines)
- [ ] Verify: `helm lint` passes

### Testing Verification
- [ ] [ ] Build Docker image with build args
- [ ] [ ] Run container and verify ENV vars exist
- [ ] [ ] Deploy to Kubernetes
- [ ] [ ] Test `/version` endpoint
- [ ] [ ] Verify rollout strategy with `kubectl get deployment -o yaml`
- [ ] [ ] Check ArgoCD shows "Synced"

---

## 📊 Impact Summary

| Gap | File | Lines Changed | Effort | Impact |
|-----|------|---|--------|--------|
| #1 | Dockerfile | 8 | 5 min | HIGH - Enables metadata |
| #2 | src/main.py | 14 | 10 min | MEDIUM - Better observability |
| #3 | deployment.yaml | 5 | 5 min | LOW - Best practice |
| **Total** | **3 files** | **27 lines** | **20 min** | **Complete determinism** |

---

## 💡 Important Notes

1. **Dockerfile ARGs**: Must be declared AFTER each `FROM` statement if you need them in that stage
2. **ENV Variables**: Will be available to all processes in running containers
3. **Helm YAML**: Indentation must be exact (use 2 spaces)
4. **Git Commit**: Will trigger CI/CD pipeline automatically
5. **No Breaking Changes**: All fixes are additive (only add, no removal)

---

## ✅ Definition of "Done"

All 3 gaps are fixed when:

- [x] Dockerfile has ARG and ENV declarations
- [x] src/main.py has `/version` endpoint
- [x] deployment.yaml has explicit rolling update strategy
- [x] All files committed and pushed
- [x] CI/CD pipeline completes successfully
- [x] New pods have correct image tag (NOT "latest")
- [x] `curl /version` returns metadata with image_tag and build_time
- [x] `kubectl get deployment -o yaml` shows strategy section
- [x] ArgoCD shows application as "Synced"
- [x] All 3 gaps resolved ✅

---

**Total Time to Complete**: ~30 minutes  
**Difficulty**: Easy  
**Risk Level**: Very Low (additive changes only)  
**Rollback**: Simply revert the 3 files if needed

**Start Now**: Begin with Gap #1 (Dockerfile)
