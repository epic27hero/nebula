output "argocd_ip" {
  description = "ArgoCD LoadBalancer IP"
  value       = kubernetes_service_v1.argocd.spec[0].load_balancer_ip
}

output "prometheus_ip" {
  description = "Prometheus LoadBalancer IP"
  value       = kubernetes_service_v1.prometheus.spec[0].load_balancer_ip
}

output "grafana_ip" {
  description = "Grafana LoadBalancer IP"
  value       = kubernetes_service_v1.grafana.spec[0].load_balancer_ip
}

output "fastapi_ip" {
  description = "FastAPI LoadBalancer IP"
  value       = kubernetes_service_v1.fastapi.spec[0].load_balancer_ip
}

output "envoy_ip" {
  description = "Envoy Gateway LoadBalancer IP"
  value       = kubernetes_service_v1.envoy.spec[0].load_balancer_ip
}

output "service_urls" {
  description = "All service URLs"
  value = {
    argocd    = "http://${kubernetes_service_v1.argocd.spec[0].load_balancer_ip}"
    prometheus = "http://${kubernetes_service_v1.prometheus.spec[0].load_balancer_ip}:9090"
    grafana   = "http://${kubernetes_service_v1.grafana.spec[0].load_balancer_ip}:3000"
    fastapi   = "http://${kubernetes_service_v1.fastapi.spec[0].load_balancer_ip}"
    envoy     = "http://${kubernetes_service_v1.envoy.spec[0].load_balancer_ip}"
  }
}
