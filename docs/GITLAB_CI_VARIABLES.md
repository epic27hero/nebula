# GitLab CI/CD Dynamic Variables Configuration

## Overview

The `.gitlab-ci.yml` file now uses dynamic variables instead of hardcoded URLs and IPs. This allows the pipeline to work seamlessly across different environments without code changes.

## Default Values

All variables have sensible defaults, but can be customized for your environment:

| Variable | Default | Description |
|----------|---------|-------------|
| `GITLAB_HOST` | `192.168.0.190` | GitLab server hostname or IP |
| `GITLAB_PORT` | `80` | GitLab server port |
| `GITLAB_PROTOCOL` | `http` | GitLab protocol (http or https) |
| `ARGOCD_IP` | `192.168.0.205` | ArgoCD service LoadBalancer IP |
| `ARGOCD_PORT` | `80` | ArgoCD service port |
| `ARGOCD_PROTOCOL` | `http` | ArgoCD protocol (http or https) |
| `FASTAPI_LB_IP` | `192.168.0.206` | FastAPI LoadBalancer IP |
| `FASTAPI_LB_PORT` | `80` | FastAPI LoadBalancer port |
| `FASTAPI_PROTOCOL` | `http` | FastAPI protocol (http or https) |
| `PROMETHEUS_IP` | `10.43.24.90` | Prometheus ClusterIP |
| `PROMETHEUS_PORT` | `80` | Prometheus port |
| `PROMETHEUS_PROTOCOL` | `http` | Prometheus protocol |
| `GRAFANA_IP` | `10.43.215.176` | Grafana ClusterIP |
| `GRAFANA_PORT` | `80` | Grafana port |
| `GRAFANA_PROTOCOL` | `http` | Grafana protocol |
| `DEPLOY_SERVER` | `192.168.0.113` | Kubernetes server IP |
| `DEPLOY_USER` | `root` | SSH user for deployment |

## How to Override Variables

### Option 1: GitLab UI (Recommended for secrets)

1. Go to **Project** → **Settings** → **CI/CD** → **Variables**
2. Click **"Add variable"**
3. Enter the variable name (e.g., `ARGOCD_IP`)
4. Enter the new value (e.g., `192.168.1.100`)
5. Mark as **Protected** if it contains sensitive data
6. Click **"Add variable"**

**Example:**
```
Variable name: ARGOCD_IP
Value: 192.168.1.100
Protected: ✓
```

### Option 2: Create a `.gitlab-ci.environment.yml` file (Git-tracked)

Create `.gitlab-ci.environment.yml` in the repository root:

```yaml
# .gitlab-ci.environment.yml
variables:
  GITLAB_HOST: custom.gitlab.example.com
  GITLAB_PORT: 443
  GITLAB_PROTOCOL: https
  ARGOCD_IP: 192.168.1.100
  ARGOCD_PORT: 8080
  FASTAPI_LB_IP: 192.168.1.101
```

Then include it in `.gitlab-ci.yml`:

```yaml
include:
  - local: '.gitlab-ci.environment.yml'
```

### Option 3: Environment-specific CI/CD files

Create separate files for different environments:

- `.gitlab-ci.staging.yml`
- `.gitlab-ci.production.yml`

## Finding Your Service IPs

Run the status check script to find all service IPs:

```bash
cd /root/project_nebula
./scripts/check-complete-status.sh | grep -A15 "SERVICES SUMMARY"
```

Or use kubectl directly:

```bash
# Get all LoadBalancer IPs
kubectl get services -A -o wide | grep LoadBalancer

# Get specific service IP
kubectl get svc argocd-server -n argocd -o jsonpath='{.status.loadBalancer.ingress[0].ip}'
```

## Variables Used in Pipeline

### Dynamic URL Construction

The pipeline builds URLs dynamically:

```bash
# ArgoCD URL
${ARGOCD_PROTOCOL}://${ARGOCD_IP}:${ARGOCD_PORT}
# Result: http://192.168.0.205:80

# FastAPI URL
${FASTAPI_PROTOCOL}://${FASTAPI_LB_IP}:${FASTAPI_LB_PORT}
# Result: http://192.168.0.206:80

# GitLab push URL
${GITLAB_PROTOCOL}://oauth2:${PROJECT_NEBULA_ACCESS_TOKEN}@${GITLAB_HOST}:${GITLAB_PORT}/${CI_PROJECT_PATH}.git
# Result: http://oauth2:***@192.168.0.190:80/root/project_nebula.git
```

## Multi-Environment Setup

### Development Environment

```
Settings → CI/CD → Variables

ARGOCD_IP: 10.0.0.50
FASTAPI_LB_IP: 10.0.0.51
GITLAB_HOST: gitlab-dev.internal
```

### Staging Environment

```
Settings → CI/CD → Variables

ARGOCD_IP: 10.1.0.50
FASTAPI_LB_IP: 10.1.0.51
GITLAB_HOST: gitlab-staging.internal
```

### Production Environment

```
Settings → CI/CD → Variables

ARGOCD_IP: 10.2.0.50
FASTAPI_LB_IP: 10.2.0.51
GITLAB_HOST: gitlab.company.com
GITLAB_PROTOCOL: https
GITLAB_PORT: 443
ARGOCD_PROTOCOL: https
ARGOCD_PORT: 443
```

## Verification

To verify variables are set correctly, check the pipeline output:

1. Go to **CI/CD** → **Pipelines**
2. Click the pipeline
3. Click any job (e.g., "deploy")
4. Look for output lines like:
   ```
   📊 Monitor at:
      • ArgoCD UI: http://192.168.0.205:80
      • FastAPI: http://192.168.0.206:80
   ```

## Troubleshooting

### URLs showing as ${VARIABLE}

This means the variable is not set. Either:
- Add it to GitLab UI variables
- Check variable name spelling
- Verify variable is not restricted to specific branches

### Git push fails with wrong host

Check `GITLAB_HOST` variable:
```bash
# In pipeline logs, look for:
git push "http://oauth2:***@${GITLAB_HOST}:${GITLAB_PORT}/...
```

If it shows the literal string `${GITLAB_HOST}`, the variable isn't set.

### Can't reach service at URL

Run the status check to verify actual IPs:
```bash
./scripts/check-complete-status.sh
```

Then update variables to match current IPs.

## Best Practices

1. **Don't hardcode secrets** - Use GitLab Protected Variables for tokens
2. **Document defaults** - Keep this file updated with new variables
3. **Use environment-specific files** - Separate config for dev/staging/prod
4. **Test variable expansion** - Add debug output in pipeline jobs
5. **Review in MR** - Check URL variables in pipeline UI before merging

## Related Documentation

- [GitLab CI/CD Variables](https://docs.gitlab.com/ee/ci/variables/)
- [Project Nebula Architecture](./ARCHITECTURE_GUIDE.md)
- [Deployment Guide](./DEPLOYMENT_GUIDE.md)
- [CI/CD Guide](./CI_CD_GUIDE.md)
