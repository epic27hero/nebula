/* # =========================
# Individual Service IPs
# =========================

# output "argocd_ip" {
#   description = "ArgoCD LoadBalancer IP"
#   value       = kubernetes_service_v1.argocd[0].spec[0].load_balancer_ip
# }

output "fastapi_ip" {
  description = "FastAPI LoadBalancer IP"
  value       = kubernetes_service_v1.fastapi.spec[0].load_balancer_ip
}

output "prometheus_ip" {
  description = "Prometheus LoadBalancer IP"
  value       = kubernetes_service_v1.prometheus.spec[0].load_balancer_ip
}

output "grafana_ip" {
  description = "Grafana LoadBalancer IP"
  value       = kubernetes_service_v1.grafana.spec[0].load_balancer_ip
}

output "envoy_ip" {
  description = "Envoy Gateway LoadBalancer IP"
  value       = kubernetes_service_v1.envoy.spec[0].load_balancer_ip
}

# =========================
# Human-friendly URLs
# =========================

output "service_urls" {
  description = "Access URLs for all services"
  value = {
    # argocd     = "https://${kubernetes_service_v1.argocd[0].spec[0].load_balancer_ip}"
    fastapi    = "http://${kubernetes_service_v1.fastapi.spec[0].load_balancer_ip}"
    prometheus = "http://${kubernetes_service_v1.prometheus.spec[0].load_balancer_ip}:9090"
    grafana    = "http://${kubernetes_service_v1.grafana.spec[0].load_balancer_ip}:3000"
    envoy      = "http://${kubernetes_service_v1.envoy.spec[0].load_balancer_ip}"
  }
}
 */

 # =========================
# Read existing services
# =========================
/* 
data "kubernetes_service" "argocd" {
  metadata {
    name      = "argocd-server"
    namespace = "argocd"
  }
}

data "kubernetes_service" "fastapi" {
  metadata {
    name      = "fastapi-app-lb"
    namespace = "production"
  }
}

data "kubernetes_service" "prometheus" {
  metadata {
    name      = "prometheus-lb-static"
    namespace = "monitoring"
  }
}

data "kubernetes_service" "grafana" {
  metadata {
    name      = "grafana-lb-static"
    namespace = "monitoring"
  }
}

data "kubernetes_service" "envoy" {
  metadata {
    name      = "envoy-gateway"
    namespace = "envoy-gateway-system"
  }
}

# =========================
# Outputs
# =========================

output "argocd_ip" {
  value = data.kubernetes_service.argocd.status[0].load_balancer[0].ingress[0].ip
}

output "fastapi_ip" {
  value = data.kubernetes_service.fastapi.status[0].load_balancer[0].ingress[0].ip
}

output "prometheus_ip" {
  value = data.kubernetes_service.prometheus.status[0].load_balancer[0].ingress[0].ip
}

output "grafana_ip" {
  value = data.kubernetes_service.grafana.status[0].load_balancer[0].ingress[0].ip
}

output "envoy_ip" {
  value = data.kubernetes_service.envoy.status[0].load_balancer[0].ingress[0].ip
}

output "service_urls" {
  value = {
    argocd     = "https://${data.kubernetes_service.argocd.status[0].load_balancer[0].ingress[0].ip}"
    fastapi    = "http://${data.kubernetes_service.fastapi.status[0].load_balancer[0].ingress[0].ip}"
    prometheus = "http://${data.kubernetes_service.prometheus.status[0].load_balancer[0].ingress[0].ip}:9090"
    grafana    = "http://${data.kubernetes_service.grafana.status[0].load_balancer[0].ingress[0].ip}:3000"
    envoy      = "http://${data.kubernetes_service.envoy.status[0].load_balancer[0].ingress[0].ip}"
  }
}
 */

 #############################
# Outputs
#############################
output "service_ips" {
  value = {
    argocd = try(
      data.kubernetes_service.argocd.status[0].load_balancer[0].ingress[0].ip,
      null
    )

    fastapi = try(
      data.kubernetes_service.fastapi.status[0].load_balancer[0].ingress[0].ip,
      null
    )

    # grafana = try(
    #   data.kubernetes_service.grafana.status[0].load_balancer[0].ingress[0].ip,
    #   null
    # )

    # prometheus = try(
    #   data.kubernetes_service.prometheus.status[0].load_balancer[0].ingress[0].ip,
    #   null
    # )

    envoy = try(
      data.kubernetes_service.envoy.status[0].load_balancer[0].ingress[0].ip,
      null
    )
  }
}

output "service_urls" {
  value = {
    argocd = try(
      "https://${data.kubernetes_service.argocd.status[0].load_balancer[0].ingress[0].ip}",
      null
    )

    fastapi = try(
      "http://${data.kubernetes_service.fastapi.status[0].load_balancer[0].ingress[0].ip}",
      null
    )

    grafana = try(
      "http://${data.kubernetes_service.grafana.status[0].load_balancer[0].ingress[0].ip}:3000",
      null
    )

    prometheus = try(
      "http://${data.kubernetes_service.prometheus.status[0].load_balancer[0].ingress[0].ip}:9090",
      null
    )

    envoy = try(
      "http://${data.kubernetes_service.envoy.status[0].load_balancer[0].ingress[0].ip}",
      null
    )
  }
}
