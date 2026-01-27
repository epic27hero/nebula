# variable "kubeconfig_path" { default = "~/.kube/config" }
variable "kubeconfig_path" {
  default = "/etc/rancher/k3s/k3s.yaml"
}
variable "metallb_ip_range" { default = "192.168.0.200-192.168.0.250" }
variable "enable_metallb" { default = true }
variable "enable_argocd" { default = true }
variable "enable_gateway_api" { default = true }
variable "enable_metrics_server" { default = true }
variable "enable_dashboard" { default = true }

# Static LoadBalancer IP assignments
variable "argocd_lb_ip" {
  description = "Static LoadBalancer IP for ArgoCD"
  type        = string
  default     = "192.168.0.205"
}

variable "prometheus_lb_ip" {
  description = "Static LoadBalancer IP for Prometheus"
  type        = string
  default     = "192.168.0.202"
}

variable "grafana_lb_ip" {
  description = "Static LoadBalancer IP for Grafana"
  type        = string
  default     = "192.168.0.203"
}

variable "fastapi_lb_ip" {
  description = "Static LoadBalancer IP for FastAPI App"
  type        = string
  default     = "192.168.0.206"
}

variable "envoy_lb_ip" {
  description = "Static LoadBalancer IP for Envoy Gateway"
  type        = string
  default     = "192.168.0.204"
}

# variable "dashboard_admin_user" { default = "admin" }
# variable "dashboard_admin_password" { default = "adminpassword" }
# variable "argocd_admin_password" { default = "argopassword" }