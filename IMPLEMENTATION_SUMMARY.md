# Service Endpoints Configuration - Implementation Summary

**Date:** January 27, 2026

## What Was Changed

### Problem
Hardcoding IP addresses in `.gitlab-ci.yml` is inflexible and problematic:
- IPs can change when services restart
- Different environments need different IPs
- Requires editing CI/CD configuration to change IPs
- No easy way to track IP changes

### Solution: Option B Implementation
Created a **centralized, version-controlled configuration system** for service IPs.

## Files Created

### 1. **`scripts/service-endpoints.conf`**
- Central configuration file with all service IPs and URLs
- Contains hardcoded defaults for reference
- Auto-sourced by `.gitlab-ci.yml` in `before_script`
- Easy to version control in Git

**Contents:**
```bash
FASTAPI_URL="http://192.168.0.203"
PROMETHEUS_URL="http://192.168.0.204:9090"
GRAFANA_URL="http://192.168.0.205:3000"
ARGOCD_URL="http://192.168.0.202"
KUBE_API_SERVER="https://10.43.0.1:443/metrics"
# ... plus individual IP and port variables
```

### 2. **`scripts/detect-service-ips.sh`** (executable)
Auto-detects service IPs from the running Kubernetes cluster.

**Usage:**
```bash
# View detected IPs (no changes)
./scripts/detect-service-ips.sh

# Auto-detect and update config file
./scripts/detect-service-ips.sh --update
```

**What it detects:**
- FastAPI LoadBalancer IP (from `production` namespace)
- ArgoCD server IP (from `argocd` namespace)
- Prometheus server IP (from `monitoring` namespace)
- Grafana IP (from `monitoring` namespace)

**Benefits:**
- ✅ No manual entry needed
- ✅ Works with any cluster configuration
- ✅ Validates connectivity before updating
- ✅ Creates automatic backups

### 3. **`scripts/update-service-ips.sh`** (executable)
Manual IP update tool with multiple modes.

**Usage:**
```bash
# Interactive mode (prompted for each IP)
./scripts/update-service-ips.sh

# Auto-detect from cluster
./scripts/update-service-ips.sh --auto-detect

# Reset to default values
./scripts/update-service-ips.sh --reset
```

**Modes:**
- **Interactive**: Manually enter each IP with existing value as default
- **Auto-detect**: Calls `detect-service-ips.sh --update`
- **Reset**: Restore to original hardcoded defaults

### 4. **`scripts/SERVICE_ENDPOINTS_README.md`**
Comprehensive documentation including:
- Overview of the system
- Configuration file format
- How to use each script
- Common workflows
- Integration with GitLab CI
- Troubleshooting guide
- Best practices

## Changes to `.gitlab-ci.yml`

### Before (Hardcoded)
```yaml
FASTAPI_URL: "http://192.168.0.203"
PROMETHEUS_URL: "http://192.168.0.204:9090"
GRAFANA_URL: "http://192.168.0.205:3000"
ARGOCD_URL: "http://192.168.0.202"
KUBE_API_SERVER: "https://10.43.0.1:443/metrics"
```

### After (Config File)
```yaml
SERVICE_CONFIG_FILE: "scripts/service-endpoints.conf"
```

### Before Script Enhancement
Now sources the config file at the start of every job:
```bash
before_script: |
  if [ -f "scripts/service-endpoints.conf" ]; then
    echo "📋 Loading service endpoints from config..."
    source scripts/service-endpoints.conf
  fi
  # ... rest of setup
```

### Pipeline Output Updates
Deploy and Release stages now use variables instead of hardcoded IPs:
```bash
echo "   • ArgoCD: ${ARGOCD_URL}"
echo "   • FastAPI: ${FASTAPI_URL}"
echo "   • Prometheus: ${PROMETHEUS_URL}"
echo "   • Grafana: ${GRAFANA_URL}"
```

## How It Works

### 1. Initial Setup
```bash
# Cluster is running with services assigned IPs
./scripts/detect-service-ips.sh --update
# → Updates scripts/service-endpoints.conf with detected IPs
```

### 2. During CI/CD Pipeline
```yaml
before_script: |
  source scripts/service-endpoints.conf
  # All variables now available: $FASTAPI_URL, $ARGOCD_URL, etc.

script: |
  echo "Deploying to: ${FASTAPI_URL}"
  curl "${FASTAPI_URL}/health"
```

### 3. When IPs Change
```bash
./scripts/detect-service-ips.sh --update
# → Config file is updated
# → Next pipeline run uses new IPs
# → No code changes needed!
```

## Key Advantages

✅ **Flexibility**: Update IPs without editing code  
✅ **Version Control**: Track IP changes in Git history  
✅ **Auto-Detection**: Automatically detect from cluster  
✅ **Multiple Environments**: Easy to use for dev/staging/prod  
✅ **Backward Compatible**: Works with existing `.gitlab-ci.yml`  
✅ **Backup Safety**: Auto-creates backups before changes  
✅ **Easy Rollback**: Restore from backup or reset to defaults  
✅ **Documentation**: Comprehensive README and examples  

## Usage Examples

### Example 1: Deploy new cluster and update IPs
```bash
# 1. Cluster is bootstrapped
./scripts/bootstrap-cluster.sh

# 2. Wait for IPs to be assigned
watch kubectl get svc -A

# 3. Update config
./scripts/detect-service-ips.sh --update

# 4. IPs are now in config, ready for GitLab CI
git add scripts/service-endpoints.conf
git commit -m "Update service IPs after cluster bootstrap"
git push
```

### Example 2: Change a single IP manually
```bash
# 1. View current config
cat scripts/service-endpoints.conf | grep FASTAPI

# 2. Manual update
./scripts/update-service-ips.sh
# Follow prompts, only change FastAPI IP

# 3. Commit change
git add scripts/service-endpoints.conf
git commit -m "Update FastAPI LoadBalancer IP"
```

### Example 3: Emergency recovery
```bash
# If wrong IP was saved:
cp scripts/service-endpoints.conf.backup.20260127-184500 scripts/service-endpoints.conf
git checkout scripts/service-endpoints.conf  # Or reset to last known good
```

## Files Modified

1. **`.gitlab-ci.yml`**
   - Changed VARIABLES section to reference config file
   - Updated `before_script` to source the config
   - Updated deploy/release stages to use sourced variables

## Files Created

1. **`scripts/service-endpoints.conf`** - Configuration file
2. **`scripts/detect-service-ips.sh`** - Auto-detection script
3. **`scripts/update-service-ips.sh`** - Manual update script
4. **`scripts/SERVICE_ENDPOINTS_README.md`** - Full documentation

## Next Steps

1. **Review the implementation:**
   ```bash
   cat scripts/service-endpoints.conf
   cat scripts/SERVICE_ENDPOINTS_README.md
   ```

2. **Test auto-detection (if cluster is running):**
   ```bash
   ./scripts/detect-service-ips.sh
   ```

3. **Commit to Git:**
   ```bash
   git add scripts/
   git add .gitlab-ci.yml
   git commit -m "Implement flexible service endpoints configuration"
   git push
   ```

4. **Run a test pipeline** to verify IPs are loaded correctly

## Benefits Over Hardcoding

| Aspect | Hardcoded | Config File |
|--------|-----------|-------------|
| Update IPs | Edit `.gitlab-ci.yml` | Run `./scripts/detect-service-ips.sh --update` |
| Track Changes | Git history unclear | Clear Git history for IP changes |
| Different Envs | Need separate branches | Single script handles all environments |
| Recovery | Manual rollback | Auto-backup + easy reset |
| Documentation | Scattered in comments | Centralized in CONFIG file |
| Automation | Manual entry | Auto-detect from cluster |

## Support Commands

**Check current IPs:**
```bash
cat scripts/service-endpoints.conf
```

**View what's in cluster:**
```bash
kubectl get svc -A -o wide
```

**Auto-update from cluster:**
```bash
./scripts/detect-service-ips.sh --update
```

**Manual update:**
```bash
./scripts/update-service-ips.sh
```

**Reset to defaults:**
```bash
./scripts/update-service-ips.sh --reset
```

**View backup:**
```bash
ls -la scripts/service-endpoints.conf.backup.*
```

---

**Configuration is now flexible, maintainable, and version-controlled!** 🎉
