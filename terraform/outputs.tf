# output "service_ips" {
#   description = "Static LoadBalancer IPs for all services"
#   value = {
#     # argocd     = module.service_ips.argocd_ip
#     prometheus = module.service_ips.prometheus_ip
#     grafana    = module.service_ips.grafana_ip
#     fastapi    = module.service_ips.fastapi_ip
#     envoy      = module.service_ips.envoy_ip
#   }
# }

# output "service_urls" {
#   description = "Access URLs for all services"
#   value       = module.service_ips.service_urls
# }
output "service_ips" {
  value = module.service_ips.service_ips
}

output "service_urls" {
  value = module.service_ips.service_urls
}