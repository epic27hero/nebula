# Service Endpoints Configuration

This document explains how to manage fixed service IP addresses for Project Nebula services.

## Fixed Service IPs

All services are configured with **fixed, static IP addresses** that should not change:

```
# FastAPI Application
curl http://192.168.0.203          # API endpoint
curl http://192.168.0.203/docs     # Swagger documentation
curl http://192.168.0.203/health   # Health check
curl http://192.168.0.203/metrics  # Prometheus metrics

# Monitoring
curl http://192.168.0.204:9090     # Prometheus
curl http://192.168.0.205:3000     # Grafana (admin/grafana)

# Management
curl http://192.168.0.202          # ArgoCD UI (see argocd-password.txt)

# Kubernetes API
https://10.43.0.1:443/metrics      # Kubernetes API server metrics
```

## Configuration File

The service endpoints are defined in `config/service-endpoints.conf`:

```bash
source config/service-endpoints.conf
echo $FASTAPI_URL      # http://192.168.0.203
echo $ARGOCD_URL       # http://192.168.0.202
echo $PROMETHEUS_URL   # http://192.168.0.204:9090
echo $GRAFANA_URL      # http://192.168.0.205:3000
```

## Managing IPs

### 1. View Configuration

```bash
./scripts/detect-service-ips.sh
```

This validates that all service IPs are properly configured and tests connectivity.

### 2. Update Configuration

#### Option A: Interactive Mode (Recommended)

```bash
./scripts/update-service-ips.sh
```

You'll be prompted to enter each service IP. Press Enter to keep the default fixed IP.

#### Option B: Use Defaults (Fixed IPs)

```bash
./scripts/update-service-ips.sh --no-prompt
```

Sets all IPs to the fixed defaults without prompting.

### 3. Detect from Cluster (Optional)

To see what IPs the K3s cluster actually has:

```bash
./scripts/detect-service-ips.sh --raw
```

This shows the LoadBalancer IPs that Kubernetes assigned. You can use this to verify the fixed IPs match.

## GitLab CI/CD Integration

The GitLab CI/CD pipeline automatically loads service endpoints from the config file:

```yaml
before_script: |
  # Load service endpoint configuration
  if [ -f "config/service-endpoints.conf" ]; then
    source config/service-endpoints.conf
  fi
```

All jobs can then use variables like:
- `$FASTAPI_URL`
- `$ARGOCD_URL`
- `$PROMETHEUS_URL`
- `$GRAFANA_URL`
- `$KUBE_API_SERVER`

## Environment Setup

When first setting up or deploying to a new environment:

```bash
# 1. Create the config with fixed IPs
./scripts/update-service-ips.sh --no-prompt

# 2. Validate the configuration
./scripts/detect-service-ips.sh

# 3. Verify variables are loaded in shell
source config/service-endpoints.conf
env | grep FASTAPI_URL
```

## Troubleshooting

### Config File Not Found in Pipeline

If you get warnings about `config/service-endpoints.conf` not being found:

1. Commit the file to Git:
   ```bash
   git add config/service-endpoints.conf
   git commit -m "chore: add service endpoints configuration"
   git push
   ```

2. Or run the update script in CI/CD before-script

### Services Not Responding

If services show as "Not responding" when running `detect-service-ips.sh`:

1. Services may still be starting up
2. Check MetalLB is working: `kubectl get svc -A -o wide`
3. Verify network connectivity to the IPs
4. Check service status: `kubectl get pods -A`

### Updating IPs for New Environment

If you're deploying to a different environment with different IPs:

```bash
./scripts/update-service-ips.sh
```

Then enter the new IP addresses when prompted.

## File Structure

```
project_nebula/
├── config/
│   └── service-endpoints.conf      # Service IP configuration
├── scripts/
│   ├── detect-service-ips.sh       # Validate/detect service IPs
│   ├── update-service-ips.sh       # Update configuration
│   └── ...
└── .gitlab-ci.yml                  # Sources config/service-endpoints.conf
```

## Quick Reference

| Service | IP | Port | URL |
|---------|-----|------|-----|
| FastAPI | 192.168.0.203 | 80 | http://192.168.0.203 |
| ArgoCD | 192.168.0.202 | 80 | http://192.168.0.202 |
| Prometheus | 192.168.0.204 | 9090 | http://192.168.0.204:9090 |
| Grafana | 192.168.0.205 | 3000 | http://192.168.0.205:3000 |
| Kubernetes API | 10.43.0.1 | 443 | https://10.43.0.1:443 |

## Default Values

These are the fixed default IPs used when running `./scripts/update-service-ips.sh --no-prompt`:

```bash
FASTAPI_IP=192.168.0.203
FASTAPI_PORT=80

ARGOCD_IP=192.168.0.202
ARGOCD_PORT=80

PROMETHEUS_IP=192.168.0.204
PROMETHEUS_PORT=9090

GRAFANA_IP=192.168.0.205
GRAFANA_PORT=3000

KUBE_API_SERVER=https://10.43.0.1:443/metrics
```
