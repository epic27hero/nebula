# ============================================================================
# Static LoadBalancer IP Visibility Module for Project Nebula
# ============================================================================
#
# PURPOSE:
#   Monitor and document static LoadBalancer IP assignments across all services.
#   This module exists ONLY for visibility, validation, and CI guardrails.
#
# IMPORTANT:
#   This module MUST NEVER create, modify, or delete Kubernetes Services.
#   Any such change would violate GitOps ownership boundaries.
#
# ARCHITECTURE:
#   ✅ Terraform does NOT create LoadBalancer services
#   ✅ Helm charts own all application services (single-writer principle)
#   ✅ Terraform only reads (data sources) for visibility & outputs
#   ✅ All loadBalancerIP values defined in Helm values.yaml files
#
# IP SOURCES (REFERENCE ONLY — NOT WRITERS):
#   - Root: terraform/variables.tf
#       ▸ Used for documentation or IP reservation reference
#       ▸ NEVER applied directly to Kubernetes
#   - Module: terraform/modules/service-ips/variables.tf
#       ▸ Optional reference variables (no enforcement)
#   - Config: config/service-endpoints.conf
#       ▸ Shell / ops reference for humans
#
#   ✅ ACTUAL IPs (SOURCE OF TRUTH):
#       Helm chart values.yaml files
#
# WHY THIS APPROACH:
#   1. Single source of truth
#      ▸ Helm is the ONLY writer of Services
#   2. No ownership conflicts
#      ▸ Terraform & ArgoCD never fight over Services
#   3. Selector reliability
#      ▸ Helm templates control labels & selectors
#   4. Upgrade safety
#      ▸ Helm chart upgrades never conflict with Terraform
#   5. Clear visibility
#      ▸ Terraform outputs expose real cluster state
#
# MIGRATED FROM:
#   Previous approach created duplicate LoadBalancer services
#
#   ❌ Problem:
#      Terraform and Helm both created Services
#   ❌ Risk:
#      - Selector drift
#      - IP competition
#      - ArgoCD sync confusion
#   ✅ Solution:
#      Terraform reads; Helm writes (strict separation of concerns)
#
# ============================================================================

# ============================================================================
# ARCHIVED APPROACHES (For Reference & Historical Context)
# ============================================================================
#
# ⚠️ DO NOT RE-ENABLE ANY CODE IN THIS SECTION
#     It is intentionally archived for documentation only
#

# /* 
#   OLD APPROACH 1 (Jan 2026): Terraform-created LoadBalancer services
#   
#   Problem:
#     - Duplicate services alongside Helm-managed ones
#     - MetalLB could not deterministically allocate IPs
#     - Helm upgrades changed selectors unexpectedly
#     - Two "authoritative" Service definitions existed
#     - Violated the single-writer principle
#
#   Example of what was removed:
#   
#   resource "kubernetes_service_v1" "argocd" {
#     metadata {
#       name      = "argocd-server-lb-static"
#       namespace = "argocd"
#     }
#     spec {
#       type = "LoadBalancer"
#       load_balancer_ip = var.argocd_ip
#       selector = {
#         "app.kubernetes.io/name"     = "argocd-server"
#         "app.kubernetes.io/instance" = "argocd"
#       }
#       port {
#         name        = "http"
#         port        = 80
#         target_port = 8080
#       }
#     }
#   }
#
#   LESSON:
#     ❌ Never create Services in Terraform when Helm already does
#     ❌ This is a known Kubernetes + GitOps anti-pattern
# */

# ============================================================================
# ACTIVE IMPLEMENTATION: Data Sources for Visibility
# ============================================================================
#
# PATTERN:
#   Read Helm-created Services to validate cluster state.
#
# FLOW:
#   1. Helm charts deploy Services with loadBalancerIP values
#   2. MetalLB assigns the requested static IPs
#   3. Terraform data sources READ Service status
#   4. Terraform outputs expose IP information
#   5. CI/CD validates that exposure is complete
#
# HELM CHART CONFIGURATION (SOURCE OF TRUTH):
#   - helm/fastapi-app/values.yaml
#       service.loadBalancerIP: 192.168.0.203
#
#   - argocd/applications/prometheus.yaml
#       helm.values.server.service.loadBalancerIP: 192.168.0.204
#
#   - argocd/applications/grafana.yaml
#       helm.values.service.loadBalancerIP: 192.168.0.205
#
#   - terraform/modules/argocd/main.tf
#       yamlencode(server.service.loadBalancerIP = 192.168.0.202)
#
# ============================================================================

# ============================================================================
# ArgoCD Server Service (Helm-managed)
# ============================================================================
# IP: 192.168.0.202
# Source: terraform/modules/argocd/main.tf
#
# Description:
#   - UI access at http://192.168.0.202
#   - Service created by Helm (argo-cd chart)
#   - Terraform only reads the existing Service
#   - Selector fully owned by Helm
# ============================================================================

data "kubernetes_service_v1" "argocd" {
  metadata {
    name      = "argocd-server"
    namespace = "argocd"
  }
}

# ============================================================================
# FastAPI Application Service (Helm-managed)
# ============================================================================
# IP: 192.168.0.203
# Source: helm/fastapi-app/values.yaml
#
# Description:
#   - API endpoint at http://192.168.0.203
#   - Service defined in custom Helm chart
#   - ArgoCD applies Helm chart
#   - Terraform only observes Service state
# ============================================================================

data "kubernetes_service_v1" "fastapi" {
  metadata {
    name      = "fastapi-app-lb"
    namespace = "production"
  }

  depends_on = [
    # Intentional no-op:
    # This block documents that ArgoCD owns deployment order
  ]
}

# ============================================================================
# Prometheus Server Service (Helm-managed)
# ============================================================================
# IP: 192.168.0.204
# Source: argocd/applications/prometheus.yaml
#
# Description:
#   - Metrics endpoint at http://192.168.0.204:9090
#   - Service created by Helm via ArgoCD
#   - Used by Grafana datasources
# ============================================================================

data "kubernetes_service_v1" "prometheus" {
  metadata {
    name      = "prometheus-server"
    namespace = "monitoring"
  }
}

# ============================================================================
# Grafana Dashboard Service (Helm-managed)
# ============================================================================
# IP: 192.168.0.205
# Source: argocd/applications/grafana.yaml
#
# Description:
#   - Dashboard UI at http://192.168.0.205:3000
#   - Service created by Helm
#   - Persistent static IP for users/bookmarks
# ============================================================================

data "kubernetes_service_v1" "grafana" {
  metadata {
    name      = "grafana"
    namespace = "monitoring"
  }
}

# ============================================================================
# Envoy Gateway Service (Helm-managed)
# ============================================================================
# IP: 192.168.0.210
# Source: terraform/modules/gateway-api/main.tf
#
# Description:
#   - External ingress gateway
#   - Routes HTTPRoute objects to backend services
#   - Helm creates Service, Terraform reads it
# ============================================================================

data "kubernetes_service_v1" "envoy_gateway" {
  metadata {
    name      = "envoy-gateway"
    namespace = "gateway-system"
  }
}

# ============================================================================
# OUTPUTS: Expose IP Information
# ============================================================================
# These outputs reflect REAL cluster state.
# They do not assume correctness — they observe it.
# ============================================================================

output "argocd_ip" {
  description = "ArgoCD server LoadBalancer IP"
  value = coalesce(
    try(data.kubernetes_service_v1.argocd.status[0].load_balancer.ingress[0].ip, null),
    try(data.kubernetes_service_v1.argocd.status[0].load_balancer.ingress[0].hostname, null),
    "Pending"
  )
}

output "fastapi_ip" {
  description = "FastAPI application LoadBalancer IP"
  value = coalesce(
    try(data.kubernetes_service_v1.fastapi.status[0].load_balancer.ingress[0].ip, null),
    try(data.kubernetes_service_v1.fastapi.status[0].load_balancer.ingress[0].hostname, null),
    "Pending"
  )
}

output "prometheus_ip" {
  description = "Prometheus server LoadBalancer IP"
  value = coalesce(
    try(data.kubernetes_service_v1.prometheus.status[0].load_balancer.ingress[0].ip, null),
    try(data.kubernetes_service_v1.prometheus.status[0].load_balancer.ingress[0].hostname, null),
    "Pending"
  )
}

output "grafana_ip" {
  description = "Grafana dashboard LoadBalancer IP"
  value = coalesce(
    try(data.kubernetes_service_v1.grafana.status[0].load_balancer.ingress[0].ip, null),
    try(data.kubernetes_service_v1.grafana.status[0].load_balancer.ingress[0].hostname, null),
    "Pending"
  )
}

output "envoy_gateway_ip" {
  description = "Envoy Gateway LoadBalancer IP"
  value = coalesce(
    try(data.kubernetes_service_v1.envoy_gateway.status[0].load_balancer.ingress[0].ip, null),
    try(data.kubernetes_service_v1.envoy_gateway.status[0].load_balancer.ingress[0].hostname, null),
    "Pending"
  )
}

# ============================================================================
# VALIDATION: Service IP Assignments
# ============================================================================
# Summary output for documentation and dashboards
# ============================================================================

output "service_ips_summary" {
  description = "Summary of all service IPs"
  value = {
    argocd        = coalesce(try(data.kubernetes_service_v1.argocd.status[0].load_balancer.ingress[0].ip, null), try(data.kubernetes_service_v1.argocd.status[0].load_balancer.ingress[0].hostname, null), "Pending")
    fastapi       = coalesce(try(data.kubernetes_service_v1.fastapi.status[0].load_balancer.ingress[0].ip, null), try(data.kubernetes_service_v1.fastapi.status[0].load_balancer.ingress[0].hostname, null), "Pending")
    prometheus    = coalesce(try(data.kubernetes_service_v1.prometheus.status[0].load_balancer.ingress[0].ip, null), try(data.kubernetes_service_v1.prometheus.status[0].load_balancer.ingress[0].hostname, null), "Pending")
    grafana       = coalesce(try(data.kubernetes_service_v1.grafana.status[0].load_balancer.ingress[0].ip, null), try(data.kubernetes_service_v1.grafana.status[0].load_balancer.ingress[0].hostname, null), "Pending")
    envoy_gateway = coalesce(try(data.kubernetes_service_v1.envoy_gateway.status[0].load_balancer.ingress[0].ip, null), try(data.kubernetes_service_v1.envoy_gateway.status[0].load_balancer.ingress[0].hostname, null), "Pending")
  }
}

# ============================================================================
# VALIDATION: CI/CD Gate
# ============================================================================
# Fail pipeline if ANY service is still Pending
# ============================================================================

locals {
  # Returns true only if ALL services have an assigned IP
  all_services_ready = alltrue([
    can(data.kubernetes_service_v1.argocd.status[0].load_balancer.ingress[0].ip),
    can(data.kubernetes_service_v1.fastapi.status[0].load_balancer.ingress[0].ip),
    can(data.kubernetes_service_v1.prometheus.status[0].load_balancer.ingress[0].ip),
    can(data.kubernetes_service_v1.grafana.status[0].load_balancer.ingress[0].ip),
    can(data.kubernetes_service_v1.envoy_gateway.status[0].load_balancer.ingress[0].ip),
  ])
}

output "service_ip_validation" {
  description = "CI/CD validation signal: true if all LoadBalancer IPs are assigned"
  value       = local.all_services_ready
}

# Usage in CI:
#   terraform output -raw service_ip_validation \
#     | grep -q true \
#     && echo "✅ All IPs ready" \
#     || (echo "❌ Services still Pending" && exit 1)
#
# ============================================================================
# ARCHITECTURE NOTES
# ============================================================================
#
# Single Source of Truth (IP Assignments):
#   ✅ helm/fastapi-app/values.yaml
#   ✅ terraform/modules/argocd/main.tf
#   ✅ argocd/applications/prometheus.yaml
#   ✅ argocd/applications/grafana.yaml
#
# Ownership Boundaries:
#   - Helm      → creates Services
#   - ArgoCD    → deploys Helm charts
#   - MetalLB  → assigns IPs
#   - Terraform→ reads & validates only
#
# This file MUST remain read-only with respect to Kubernetes resources.
#
# ============================================================================
