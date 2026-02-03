# GitLab CI/CD Pipeline - Complete Guide

## 🚀 How Changes Flow Through the Pipeline

### Answer to Your Question: YES, Changes Will Be Reflected! ✅

When you push changes to the FastAPI `main.py` file:

```
1. You push to GitLab
   ↓
2. GitLab detects push to 'master' branch
   ↓
3. CI/CD pipeline automatically starts:
   - BUILD stage: Creates new Docker image
   - PUSH stage:  Uploads to registry (192.168.0.113:5000)
   - DEPLOY stage: Verifies deployment in K3s
   ↓
4. K3s automatically detects new image in registry
   ↓
5. Kubernetes rolling update:
   - New pods start with new image
   - Old pods gradually shut down
   - Service stays available during update
   ↓
6. Your changes are LIVE
```

---

## 📊 Pipeline Stages Explained

### Stage 1: BUILD 🔨
**What it does:**
- Reads the `Dockerfile`
- Builds a new Docker image with your changes
- Tags it with commit SHA and 'latest' tag

**Example:**
```
Building Docker image: fastapi-demo:abc1234
✅ Build successful: fastapi-demo:abc1234
Tagging for registry...
✅ Image tagged for push to 192.168.0.113:5000
```

---

### Stage 2: PUSH 📤
**What it does:**
- Uploads the Docker image to the registry
- Makes it available for K3s to pull

**Example:**
```
📤 Pushing image to registry: 192.168.0.113:5000/fastapi-demo:latest
✅ Image pushed successfully

📝 Pushed tags:
  - 192.168.0.113:5000/fastapi-demo:latest
  - 192.168.0.113:5000/fastapi-demo:abc1234
```

---

### Stage 3: DEPLOY 🚀
**What it does:**
- Connects to K3s server via SSH
- Displays comprehensive infrastructure status
- Shows all access points and their IPs
- Verifies deployment completed successfully

**Example Output:**
```
📊 INFRASTRUCTURE STATUS REPORT
==================================================

1️⃣  KUBERNETES CLUSTER
   Nodes:
   - ferack103-re-da Ready master

2️⃣  FASTAPI APPLICATION
   Deployment: 3/3 replicas ready
   Pods:
   - fastapi-app-78d65658cb-5jgqq (10.42.0.115) - Running
   - fastapi-app-78d65658cb-9zzwk (10.42.0.116) - Running
   - fastapi-app-78d65658cb-xvwmp (10.42.0.114) - Running

3️⃣  ACCESS POINTS
   🌐 ArgoCD:      http://192.168.0.202
   🚀 FastAPI:     http://192.168.0.203
      - Swagger UI: http://192.168.0.203/docs
      - Health:     http://192.168.0.203/health
      - Metrics:    http://192.168.0.203/metrics

   📊 Prometheus:  http://192.168.0.204:9090
   📈 Grafana:     http://192.168.0.205:3000
      - Username: admin
      - Password: grafana

4️⃣  ARGOCD APPLICATIONS
   - fastapi-prod: Sync=Synced, Health=Healthy
   - prometheus: Sync=Synced, Health=Healthy
   - grafana: Sync=Synced, Health=Healthy

5️⃣  METALLB LOAD BALANCER
   IP Pool: 192.168.0.201 - 192.168.0.250
   Status: 2 pods running

6️⃣  RECENT EVENTS
   (Shows recent deployment events)

==================================================
✅ DEPLOYMENT STATUS CHECK COMPLETE
==================================================
```

---

## 🔄 Full Deployment Flow Example

### Your Change to FastAPI:
```python
# src/main.py - Add a new endpoint

@app.get("/version")
def version():
    return {"version": "1.0.1", "updated": True}
```

### Push to GitLab:
```bash
git add src/main.py
git commit -m "Add version endpoint"
git push origin master
```

### Pipeline Execution (Automatic):

**Step 1: BUILD**
```
✅ Docker image built with new endpoint
✅ Image tagged: fastapi-demo:xyz9999
```

**Step 2: PUSH**
```
✅ Image pushed to 192.168.0.113:5000
✅ Available for K3s to pull
```

**Step 3: DEPLOY**
```
✅ K3s detects new image
✅ Rolling update starts:
   - Pod 1 updates ✅
   - Pod 2 updates ✅
   - Pod 3 updates ✅
✅ All 3/3 replicas ready with new code
✅ Your endpoint is LIVE at: http://192.168.0.203/version
```

---

## 📝 What Information is Displayed

The updated CI/CD pipeline shows:

| What | Where | IP |
|------|-------|-----|
| **Kubernetes Cluster** | nodes status | - |
| **FastAPI Deployment** | replica count, pod details | - |
| **Access Points** | All service IPs and URLs | 192.168.0.202-205 |
| **ArgoCD Apps** | Sync & Health status | - |
| **MetalLB** | Load balancer status | 192.168.0.201-250 |
| **Recent Events** | Deployment events | - |

---

## 🛠️ How It Works Behind the Scenes

### 1. **Image Build in Registry**
```
Dockerfile → Docker Engine → 192.168.0.113:5000/fastapi-demo:latest
```

### 2. **K3s Image Pull Policy**
```
K3s watches the image in registry
When new image appears:
  - Creates new pod with new image
  - Old pod continues serving traffic
  - New pod becomes ready
  - Old pod gracefully terminates
```

### 3. **Rolling Update**
```
Time ──────────────────────────────→

Old Pod 1: ████████░░░░░░░░░░░░░░░░░ (terminating)
New Pod 1: ░░░░░░░░░░░████████████████ (starting)

Old Pod 2: ██████░░░░░░░░░░░░░░░░░░░░ (terminating)
New Pod 2: ░░░░░░░░░░░███████░░░░░░░░ (starting)

Old Pod 3: ░░░░░░░░░░░░░░░░░░░░░░░░░░ (terminated)
New Pod 3: ░░░░░░░░░░░░░░░░░░███████████ (running)
```

---

## ✅ Verification

After deployment, you can verify your changes are live:

```bash
# Test the endpoint
curl http://192.168.0.203/version

# Check pod logs
kubectl logs -n production -l app=fastapi -f

# Run status check
./scripts/quick-status.sh
```

---

## 🔐 Pipeline Requirements

The CI/CD pipeline needs:

| Requirement | Location | Purpose |
|-------------|----------|---------|
| **SSH Key** | GitLab CI Variable: `SSH_PRIVATE_KEY_GITLAB_TESTING_CI` | Connect to K3s server |
| **Docker Registry** | 192.168.0.113:5000 | Store images |
| **K3s Access** | 192.168.0.113 | Deploy applications |

---

## 📋 Pipeline Configuration

### Trigger:
- ✅ Automatically on `git push origin master`
- ✅ Can be run manually from GitLab UI

### Stages:
1. **build** - Create Docker image
2. **push** - Upload to registry
3. **deploy** - Verify deployment

### Timeout:
- Build: ~2-3 minutes
- Push: ~1 minute
- Deploy: ~1 minute
- **Total: ~5 minutes from push to live**

---

## 🚀 Next Steps

After pushing changes:

1. **Watch Pipeline in GitLab**
   - Go to Pipelines → click running pipeline
   - View each stage's output

2. **Monitor K3s Deployment**
   - Run: `./scripts/quick-status.sh`
   - Shows updated IPs and status

3. **Test Your Changes**
   - Visit: http://192.168.0.203
   - Check new functionality

4. **View Metrics**
   - Prometheus: http://192.168.0.204:9090
   - Grafana: http://192.168.0.205:3000

---

## 🔧 Troubleshooting

### Pipeline Failed?

**Check Build logs:**
```bash
ssh 192.168.0.113
docker build -t fastapi-demo:test .
```

**Check Push logs:**
```bash
docker push 192.168.0.113:5000/fastapi-demo:latest
```

**Check K3s Deployment:**
```bash
kubectl get pods -n production
kubectl logs -n production -l app=fastapi
```

### Manual Deployment?

Uncomment `when: manual` in `.gitlab-ci.yml` to require manual approval

---

## ✨ Summary

| What | Answer |
|------|--------|
| **Will changes be reflected?** | ✅ YES - Automatic via CI/CD |
| **How long to deploy?** | ~5 minutes |
| **Is downtime required?** | ❌ NO - Rolling update |
| **Where to see status?** | GitLab CI/CD or `quick-status.sh` |
| **Where to test?** | http://192.168.0.203 |

Your changes flow automatically from GitLab → Docker → K3s → Live! 🚀
