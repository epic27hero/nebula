# Static LoadBalancer IP Configuration

## Problem
When services are recreated or pods are rescheduled, MetalLB automatically assigns the next available IP from its address pool. This causes service IPs to change unpredictably:
- ArgoCD was `192.168.0.202` → now `192.168.0.205`
- This breaks hardcoded URLs in CI/CD pipelines, monitoring, and documentation

## Root Cause
MetalLB's default behavior uses auto-assignment with `AUTO ASSIGN: true`:
```
IPAddressPool: pool
ADDRESSES: 192.168.0.201-192.168.0.250
AUTO ASSIGN: true
```

When services request LoadBalancer IPs, MetalLB picks the next available one.

## Solution
We've implemented **static LoadBalancer IP assignment** using Terraform to lock services to fixed IPs.

### Implementation

#### 1. New Terraform Module: `terraform/modules/service-ips/`
Creates Kubernetes services with fixed `loadBalancerIP` specifications:

```hcl
resource "kubernetes_service_v1" "argocd" {
  metadata {
    name      = "argocd-server-lb"
    namespace = "argocd"
  }
  spec {
    type            = "LoadBalancer"
    load_balancer_ip = var.argocd_ip  # Fixed IP
    selector = {
      app = "argocd"
    }
    port {
      port        = 80
      target_port = 8080
    }
  }
}
```

#### 2. Configurable Variables
Edit `terraform/terraform.tfvars` to customize IPs:

```hcl
argocd_lb_ip     = "192.168.0.205"
prometheus_lb_ip = "192.168.0.202"
grafana_lb_ip    = "192.168.0.203"
fastapi_lb_ip    = "192.168.0.206"
envoy_lb_ip      = "192.168.0.204"
```

### Current Static IP Assignments

| Service | IP | URL |
|---------|----|----|
| **ArgoCD** | 192.168.0.205 | http://192.168.0.205 |
| **Prometheus** | 192.168.0.202 | http://192.168.0.202:9090 |
| **Grafana** | 192.168.0.203 | http://192.168.0.203:3000 |
| **FastAPI** | 192.168.0.206 | http://192.168.0.206 |
| **Envoy Gateway** | 192.168.0.204 | http://192.168.0.204 |
| **Traefik** | 192.168.0.201 | http://192.168.0.201 |

### How to Apply

#### Step 1: Update Terraform Configuration
```bash
cd /root/project_nebula/terraform
terraform plan
terraform apply
```

#### Step 2: Verify Static IPs
```bash
# Check that services now have the static IPs
kubectl get svc -A -o wide | grep LoadBalancer

# Should show:
# argocd/argocd-server-lb          192.168.0.205
# monitoring/prometheus-lb-static  192.168.0.202
# monitoring/grafana-lb-static     192.168.0.203
# production/fastapi-app-lb-static 192.168.0.206
# gateway-system/envoy-gateway-lb  192.168.0.204
```

#### Step 3: Update GitLab CI/CD Variables
Set these in your GitLab project Settings > CI/CD > Variables:

```
ARGOCD_SERVER=192.168.0.205
PROMETHEUS_URL=192.168.0.202:9090
GRAFANA_URL=192.168.0.203:3000
FASTAPI_URL=192.168.0.206
GITLAB_RUNNER_URL=192.168.0.113
```

### Why This Approach?

✅ **Pros:**
- IPs never change after assignment
- Works with existing MetalLB setup
- No need for DNS or domain names
- Terraform-managed for infrastructure-as-code
- Easy to modify IP assignments centrally

⚠️ **Considerations:**
- Static IPs must be within the MetalLB address pool
- If IP is already in use, deployment will fail
- Need to reserve IPs in your IP management system

### Alternative: DNS Solution (Optional)

For production deployments, consider using DNS instead:

```bash
# Create DNS A records pointing to MetalLB IPs
argocd.internal     → 192.168.0.205
prometheus.internal → 192.168.0.202
grafana.internal    → 192.168.0.203
fastapi.internal    → 192.168.0.206
```

Then update CI/CD variables to use hostnames instead of IPs.

### Troubleshooting

**Issue: Service IP remains `<pending>`**
```bash
# Check MetalLB logs
kubectl logs -n metallb-system -l app=metallb
```

**Issue: IP is already allocated**
```bash
# Check current allocations
kubectl get ipaddresspools -n metallb-system -o yaml

# Increase pool range if needed
kubectl patch ipaddresspool pool -n metallb-system --type=json -p='[{"op":"replace","path":"/spec/addresses/0","value":"192.168.0.201-192.168.0.255"}]'
```

**Issue: Services still getting auto-assigned IPs**
```bash
# Verify the service has loadBalancerIP set
kubectl get svc argocd-server-lb -n argocd -o yaml | grep loadBalancerIP

# Should show:
# loadBalancerIP: 192.168.0.205
```

### Files Modified

- `terraform/main.tf` - Added service-ips module
- `terraform/variables.tf` - Added IP configuration variables
- `terraform/outputs.tf` - Added service IP outputs
- `terraform/modules/service-ips/main.tf` - New module with service definitions
- `terraform/modules/service-ips/variables.tf` - Service IP variables
- `terraform/modules/service-ips/outputs.tf` - Service IP outputs
