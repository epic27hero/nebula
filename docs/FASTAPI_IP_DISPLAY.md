# FastAPI IP Information Display - Implementation Guide

## Overview

The FastAPI application now displays **all 3 network IPs** when you access the root endpoint (`/`):
- **Pod IP** (10.x.x.x) - Internal cluster network
- **Node IP** (192.168.0.113) - Physical server 
- **Node Name** - Kubernetes node hostname

---

## API Response Example

```json
{
  "message": "FastAPI running on Kubernetes",
  "env": "production",
  "pod_name": "fastapi-app-78d65658cb-9zzwk",
  "pod_ip": "10.42.0.114",
  "node_name": "ferack103-re-da",
  "node_ip": "192.168.0.113",
  "server_ip": "192.168.0.113"
}
```

---

## Implementation Details

### 1. FastAPI Code (src/main.py)

**Environment variables used:**
```python
pod_ip = os.getenv("POD_IP", "unknown")
node_ip = os.getenv("NODE_IP", "unknown")
node_name = os.getenv("NODE_NAME", "unknown")
```

**Complete endpoint:**
```python
@app.get("/")
def root():
    # Get hostname
    hostname = socket.gethostname()
    
    # Pod and Node details from Kubernetes environment variables
    pod_ip = os.getenv("POD_IP", "unknown")
    node_ip = os.getenv("NODE_IP", "unknown")
    node_name = os.getenv("NODE_NAME", "unknown")
    
    return {
        "message": "FastAPI running on Kubernetes",
        "env": os.getenv("ENV", "unknown"),
        
        # Pod details
        "pod_name": hostname,
        "pod_ip": pod_ip,
        
        # Node / Server details
        "node_name": node_name,
        "node_ip": node_ip,
        "server_ip": node_ip,
    }
```

### 2. Kubernetes Deployment (manifests/deployment.yaml)

**Environment variables defined:**

```yaml
env:
- name: ENV
  value: "production"
- name: LOG_LEVEL
  value: "info"

# Kubernetes pod and node information
- name: POD_IP
  valueFrom:
    fieldRef:
      fieldPath: status.podIP

- name: NODE_IP
  valueFrom:
    fieldRef:
      fieldPath: status.hostIP

- name: NODE_NAME
  valueFrom:
    fieldRef:
      fieldPath: spec.nodeName
```

---

## Understanding the IPs

### Pod IP (10.42.0.114)
- **What it is:** Virtual IP assigned to the pod within the Kubernetes cluster network
- **Range:** 10.x.x.x (cluster network)
- **Unique per:** Each pod gets a unique IP
- **Accessible from:** Only within the cluster
- **Use case:** Pod-to-pod communication, internal service discovery
- **Ephemeral:** Changes when pod is recreated

**Example:** `10.42.0.114`

### Node IP (192.168.0.113)
- **What it is:** Physical server/node IP address
- **Range:** Your network (192.168.x.x in this case)
- **Shared by:** All pods running on that node
- **Accessible from:** Outside the cluster (your network)
- **Use case:** Direct node access, troubleshooting
- **Stable:** Same as long as node exists

**Example:** `192.168.0.113`

### Server IP (Same as Node IP)
- **Alias for:** Node IP
- **Represents:** The physical server running the pods
- **Identical to:** Node IP in this implementation

**Example:** `192.168.0.113`

---

## Why This Approach is Better

### ✅ Advantages of fieldRef Method

| Aspect | fieldRef (Current) | Shell Command (Old) |
|--------|-------------------|-------------------|
| Kubernetes Native | ✅ Yes | ❌ No |
| Reliability | ✅ High | ⚠️ Medium |
| Security | ✅ Safe | ⚠️ Shell injection risk |
| Restricted Containers | ✅ Works | ❌ May fail |
| Performance | ✅ Better | ⚠️ Subprocess overhead |
| Multi-node | ✅ Works perfectly | ✅ Works |
| Production Ready | ✅ Yes | ⚠️ Limited |

### Key Benefits
1. **100% Kubernetes-native** - Uses built-in fieldRef API
2. **No shell commands** - No `hostname -I` subprocess calls
3. **Production-proven** - Used in enterprise deployments
4. **Secure** - No shell injection vulnerabilities
5. **Reliable** - Direct access to pod metadata
6. **Portable** - Works on any Kubernetes cluster (K3s, EKS, GKE, etc.)

---

## Accessing the Information

### From Browser
```
http://192.168.0.203/
```

### From Command Line
```bash
# Simple curl
curl http://192.168.0.203/

# Pretty JSON output
curl http://192.168.0.203/ | jq

# With headers
curl -v http://192.168.0.203/

# Get only pod_ip
curl http://192.168.0.203/ | jq '.pod_ip'
```

### From Inside Another Pod
```bash
# DNS resolution
curl http://fastapi-app.production.svc.cluster.local/

# With port
curl http://fastapi-app.production.svc.cluster.local:80/
```

### From Kubernetes
```bash
# Using kubectl port-forward
kubectl port-forward -n production svc/fastapi-app-lb 8000:80
curl localhost:8000/

# Execute in pod
kubectl exec -it <pod-name> -n production -- curl http://localhost:8000/
```

---

## Verifying Load Balancing

Make multiple requests and observe the rotating pod names:

```bash
# Request 1
curl http://192.168.0.203/ | jq '.pod_name, .pod_ip'
# Output: "fastapi-app-78d65658cb-9zzwk", "10.42.0.114"

# Request 2
curl http://192.168.0.203/ | jq '.pod_name, .pod_ip'
# Output: "fastapi-app-78d65658cb-a1234", "10.42.0.115"

# Request 3
curl http://192.168.0.203/ | jq '.pod_name, .pod_ip'
# Output: "fastapi-app-78d65658cb-b5678", "10.42.0.116"

# Request 4 (cycles back)
curl http://192.168.0.203/ | jq '.pod_name, .pod_ip'
# Output: "fastapi-app-78d65658cb-9zzwk", "10.42.0.114"
```

**✅ If you see different pod IPs rotating, load balancing is working!**

---

## Deployment Process

### Option 1: Automatic (via ArgoCD)
```bash
git push origin master
# Changes automatically sync in 3-5 minutes
```

### Option 2: Manual Kubectl
```bash
kubectl apply -f manifests/deployment.yaml -n production
kubectl rollout restart deployment/fastapi-app -n production
```

### Option 3: Docker Image Rebuild
```bash
cd /root/project_nebula
docker build -t 192.168.0.113:5000/fastapi-demo:latest .
docker push 192.168.0.113:5000/fastapi-demo:latest
# ArgoCD auto-deploys new image
```

---

## Monitoring the Deployment

```bash
# Watch pods as they restart
kubectl get pods -n production --watch

# Check deployment status
kubectl rollout status deployment/fastapi-app -n production

# View recent events
kubectl get events -n production --sort-by='.lastTimestamp'

# Check pod logs
kubectl logs -n production -l app=fastapi-demo -f

# View pod details
kubectl describe pod <pod-name> -n production
```

---

## Kubernetes Metadata Available via fieldRef

The following metadata is available to all pods:

```yaml
# Pod metadata
- fieldPath: metadata.name              # Pod name
- fieldPath: metadata.namespace         # Namespace name
- fieldPath: metadata.uid               # Pod UID
- fieldPath: metadata.labels['key']     # Label value
- fieldPath: metadata.annotations['key']# Annotation value

# Pod status
- fieldPath: status.podIP               # Pod IP (our use case)
- fieldPath: status.hostIP              # Node IP (our use case)
- fieldPath: status.phase               # Pod phase (Pending, Running, etc)

# Spec details
- fieldPath: spec.nodeName              # Node name (our use case)
- fieldPath: spec.serviceAccountName    # Service account

# Resource info
- fieldPath: metadata.resourceVersion   # Resource version
```

---

## Troubleshooting

### Environment variables showing "unknown"

**Problem:** Values show `"pod_ip": "unknown"`

**Cause:** Environment variables not injected into pod

**Solution:**
```bash
# Check pod has env vars
kubectl exec -it <pod-name> -n production -- env | grep -E "POD_IP|NODE_IP|NODE_NAME"

# Verify deployment has env vars
kubectl get deployment fastapi-app -n production -o yaml | grep -A 10 "env:"

# Restart pods to pick up new env vars
kubectl rollout restart deployment/fastapi-app -n production

# Wait for rollout
kubectl rollout status deployment/fastapi-app -n production
```

### Node IP is 0.0.0.0

**Problem:** `"node_ip": "0.0.0.0"`

**Cause:** Pod networking not fully initialized

**Solution:**
```bash
# Usually resolves itself
kubectl get pod <pod-name> -n production -o yaml | grep hostIP

# If persistent, check node status
kubectl get nodes -o wide
kubectl describe node <node-name>
```

### Pod IP is empty

**Problem:** `"pod_ip": ""`

**Cause:** Pod still initializing

**Solution:**
```bash
# Check pod status
kubectl get pod <pod-name> -n production

# Wait for Running state
kubectl get pods -n production --watch
```

---

## API Response Fields Reference

| Field | Type | Example | Notes |
|-------|------|---------|-------|
| message | string | "FastAPI running on Kubernetes" | Status message |
| env | string | "production" | Environment value |
| pod_name | string | "fastapi-app-78d65658cb-9zzwk" | Kubernetes pod hostname |
| pod_ip | string | "10.42.0.114" | Internal cluster IP |
| node_name | string | "ferack103-re-da" | Kubernetes node name |
| node_ip | string | "192.168.0.113" | Physical server IP |
| server_ip | string | "192.168.0.113" | Same as node_ip |

---

## Testing Endpoints

### Root Endpoint
```bash
curl http://192.168.0.203/
```
**Returns:** All IP and pod information

### Health Endpoint
```bash
curl http://192.168.0.203/health
```
**Returns:** `{"status": "ok"}`

### Metrics Endpoint
```bash
curl http://192.168.0.203/metrics
```
**Returns:** Prometheus metrics

### Swagger UI
```
http://192.168.0.203/docs
```
**View:** Interactive API documentation

---

## Common Use Cases

### 1. Verify Load Balancing
```bash
for i in {1..10}; do
  curl http://192.168.0.203/ | jq '.pod_ip'
done
```

### 2. Check Which Pod Handled Request
```bash
curl http://192.168.0.203/ | jq '.pod_name'
```

### 3. Get Node Information
```bash
curl http://192.168.0.203/ | jq '.node_name, .node_ip'
```

### 4. Monitor Pod Replacement During Updates
```bash
watch -n 1 'curl -s http://192.168.0.203/ | jq ".pod_name"'
```

### 5. Health Monitoring Script
```bash
#!/bin/bash
while true; do
  response=$(curl -s http://192.168.0.203/)
  pod=$(echo $response | jq -r '.pod_name')
  pod_ip=$(echo $response | jq -r '.pod_ip')
  echo "[$pod] IP: $pod_ip"
  sleep 2
done
```

---

## Git Information

**Commit Hash:** 413f713  
**Message:** "Add pod IP, node IP, and node name display to FastAPI endpoint"  
**Date:** January 14, 2026  
**Files Modified:**
- `src/main.py` (+33 -8)
- `manifests/deployment.yaml` (+18 -0)

---

## Summary

This implementation provides **complete network visibility** into your Kubernetes pods:

✅ **Pod IP** - See internal cluster networking  
✅ **Node IP** - See physical server information  
✅ **Node Name** - Identify which node runs the pod  
✅ **Pod Name** - Verify load balancing  
✅ **Environment** - Confirm deployment environment  

All using **100% Kubernetes-native, production-ready methods**!

