resource "kubernetes_namespace" "envs" {
  for_each = toset(["development","staging","production"])
  metadata { name = each.value }
}

module "metallb" {
  count  = var.enable_metallb ? 1 : 0
  source = "./modules/metallb"
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
module "metrics_server" {
  count  = var.enable_metrics_server ? 1 : 0
  source = "./modules/metrics-server"
} 
module "kubernetes_dashboard" {
  count  = var.enable_dashboard ? 1 : 0
  source = "./modules/kubernetes-dashboard"
}
resource "kubernetes_namespace" "monitoring" {
  metadata {
    name = "monitoring"
    labels = {
      monitoring = "enabled"
    }
  }
}




