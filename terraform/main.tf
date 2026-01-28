resource "kubernetes_namespace_v1" "envs" {
  for_each = toset(["development", "staging", "production"])

  metadata {
    name = each.value
  }

  lifecycle {
    ignore_changes = [metadata[0].labels, metadata[0].annotations]
  }
}

module "metallb" {
  count    = var.enable_metallb ? 1 : 0
  source   = "./modules/metallb"
  ip_range = var.metallb_ip_range
}

module "argocd" {
  count  = var.enable_argocd ? 1 : 0
  source = "./modules/argocd"
}

module "gateway" {
  count  = var.enable_gateway_api ? 1 : 0
  source = "./modules/gateway-api"
}
# module "metrics_server" {
#   count  = var.enable_metrics_server ? 1 : 0
#   source = "./modules/metrics-server"
# } 
# module "kubernetes_dashboard" {
#   count  = var.enable_dashboard ? 1 : 0
#   source = "./modules/kubernetes-dashboard"
# }
resource "kubernetes_namespace_v1" "monitoring" {
  metadata {
    name = "monitoring"
    labels = {
      monitoring = "enabled"
    }
  }
}

# Module to manage static LoadBalancer IPs for all services
module "service_ips" {
  source = "./modules/service-ips"

  # Optional: Override default IPs if needed
  argocd_ip     = var.argocd_lb_ip
  prometheus_ip = var.prometheus_lb_ip
  grafana_ip    = var.grafana_lb_ip
  fastapi_ip    = var.fastapi_lb_ip
  envoy_ip      = var.envoy_lb_ip

  # Ensure namespaces exist
  argocd_namespace_exists     = var.enable_argocd ? 1 : null
  monitoring_namespace_exists = kubernetes_namespace_v1.monitoring.id
  production_namespace_exists = kubernetes_namespace_v1.envs["production"].id
  gateway_namespace_exists    = var.enable_gateway_api ? 1 : null
}

# module "prometheus_stack" {
#   count  = var.enable_prometheus_stack ? 1 : 0
#   source = "./modules/prometheus-stack"
#   namespace = kubernetes_namespace_v1.monitoring.metadata[0].name
# }




