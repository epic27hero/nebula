# TODO: Fix GitLab CI/CD Deployment Pipeline - ✅ COMPLETED

## Problem Identified (BEFORE)
- CI updates `manifests/deployment.yaml` but ArgoCD reads from `helm/fastapi-app/`
- Helm chart has hardcoded `tag: latest`
- CI variables not properly passed to Helm values

## Solution Applied: Option A - Dynamic Helm Image Tags ✅

### Files Modified:

1. ✅ **helm/fastapi-app/values.yaml**
   - Changed `tag: "latest"` to `tag: ""`
   - Added comment explaining dynamic tag will be set by CI pipeline

2. ✅ **.gitlab-ci.yml** (deploy stage)
   - Updated sed commands to modify `helm/fastapi-app/values.yaml` instead of `manifests/deployment.yaml`
   - Changed `git add manifests/deployment.yaml` to `git add helm/fastapi-app/values.yaml`
   - Updated commit messages to reflect Helm values instead of manifests
   - Updated GitOps flow messages to reference Helm

## What Was Fixed

### Before:
```yaml
# In values.yaml
tag: "latest"  # Hardcoded - always uses old cached image
```

### After:
```yaml
# In values.yaml
tag: ""  # Empty - will be set dynamically by CI pipeline
```

### Before (CI deploy stage):
```bash
# Updated manifests/deployment.yaml (but ArgoCD uses Helm!)
sed -i "s|image:.*fastapi-demo.*|image: ${CI_REGISTRY}/${CI_PROJECT_PATH}/${IMAGE_NAME}:${CI_COMMIT_SHORT_SHA}|g" manifests/deployment.yaml
git add manifests/deployment.yaml
```

### After (CI deploy stage):
```bash
# Updates helm/fastapi-app/values.yaml (ArgoCD reads from here!)
sed -i "s|image:.*fastapi-demo.*|image: ${CI_REGISTRY}/${CI_PROJECT_PATH}/${IMAGE_NAME}|g" helm/fastapi-app/values.yaml
sed -i "s|tag:.*|tag: ${CI_COMMIT_SHORT_SHA}|g" helm/fastapi-app/values.yaml
git add helm/fastapi-app/values.yaml
```

## How It Works Now

1. Code pushed to master
2. GitLab CI builds new Docker image with tag `${CI_COMMIT_SHORT_SHA}` (e.g., `1f488439`)
3. CI pushes image to GitLab Container Registry
4. CI updates `helm/fastapi-app/values.yaml` with new tag
5. CI commits and pushes the Helm values change to Git
6. ArgoCD detects the change in the Git repository
7. ArgoCD syncs and deploys the new image to Kubernetes
8. Pods restart with the new code

## Next Steps

1. ✅ Files modified
2. ⏳ Push changes to GitLab: `git add . && git commit -m "Fix: Update CI to use Helm values [skip ci]" && git push`
3. ⏳ Trigger a new pipeline by making a small code change to `src/main.py`
4. ⏳ Verify ArgoCD syncs the new image
5. ⏳ Verify pods are running with the new image tag

## Files Modified
- [x] helm/fastapi-app/values.yaml
- [x] .gitlab-ci.yml (deploy stage)
- [x] TODO_FIX_DEPLOYMENT.md

