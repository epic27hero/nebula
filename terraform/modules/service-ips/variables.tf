# =========================
# Static MetalLB IPs
# =========================

variable "argocd_ip" {
  description = "Static LoadBalancer IP for ArgoCD"
  type        = string
  default     = "192.168.0.202"
}

variable "fastapi_ip" {
  description = "Static LoadBalancer IP for FastAPI App"
  type        = string
  default     = "192.168.0.203"
}

variable "prometheus_ip" {
  description = "Static LoadBalancer IP for Prometheus"
  type        = string
  default     = "192.168.0.204"
}

variable "grafana_ip" {
  description = "Static LoadBalancer IP for Grafana"
  type        = string
  default     = "192.168.0.205"
}

variable "envoy_ip" {
  description = "Static LoadBalancer IP for Envoy Gateway"
  type        = string
  default     = "192.168.0.210"
}

# =========================
# Namespace dependencies
# (used only for ordering)
# =========================

variable "argocd_namespace_exists" {
  description = "Dependency on argocd namespace"
  type        = any
  default     = null
}

variable "monitoring_namespace_exists" {
  description = "Dependency on monitoring namespace"
  type        = any
  default     = null
}

variable "production_namespace_exists" {
  description = "Dependency on production namespace"
  type        = any
  default     = null
}

variable "gateway_namespace_exists" {
  description = "Dependency on gateway-system namespace"
  type        = any
  default     = null
}

