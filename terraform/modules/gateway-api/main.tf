# resource "kubernetes_namespace_v1" "gw" {
#   metadata { name = "gateway-system" }
# }

# resource "helm_release" "envoy" {
#   name       = "envoy-gateway"
#   repository = "oci://docker.io/envoyproxy"
#   chart      = "gateway-helm"
#   namespace  = kubernetes_namespace_v1.gw.metadata[0].name
# }




# resource "helm_release" "envoy" {
#   name       = "envoy-gateway"
#   repository = "oci://docker.io/envoyproxy"
#   chart      = "gateway-helm"

#   namespace        = kubernetes_namespace_v1.gw.metadata[0].name
#   create_namespace = false

#   dependency_update = true
#   atomic             = true
#   cleanup_on_fail    = true
# }
# ======================================================
# resource "kubernetes_namespace_v1" "gw" {
#   metadata { name = "gateway-system" }
# }

# resource "helm_release" "envoy" {
#   name       = "envoy-gateway"
#   repository = "oci://docker.io/envoyproxy"
#   chart      = "gateway-helm"

#   namespace        = "gateway-system"
#   create_namespace = false

#   dependency_update = true
#   atomic             = true
#   cleanup_on_fail    = true
# }
# resource "kubectl_manifest" "prod_gateway" {
#   yaml_body = file("${path.module}/gateway.yaml")
# }
# resource "kubernetes_namespace_v1" "production" {
#   metadata {
#     name = "production"
#   }
#   depends_on = [
#   kubernetes_namespace_v1.production
# ]
# }
# ======================================================

#################################
# Namespace for Envoy Gateway
#################################
resource "kubernetes_namespace_v1" "gw" {
  metadata {
    name = "gateway-system"
  }
}

#################################
# Envoy Gateway (Controller)
#################################
resource "helm_release" "envoy" {
  name       = "envoy-gateway"
  repository = "oci://docker.io/envoyproxy"
  chart      = "gateway-helm"

  namespace        = kubernetes_namespace_v1.gw.metadata[0].name
  create_namespace = false

  dependency_update = true
  atomic             = true
  cleanup_on_fail    = true

  depends_on = [
    kubernetes_namespace_v1.gw
  ]
}

#################################
# Application Namespace
#################################
# resource "kubernetes_namespace_v1" "production" {
#   metadata {
#     name = "production"
#   }
# }

#################################
# Gateway object 
#################################
resource "kubectl_manifest" "prod_gateway" {
  yaml_body = file("${path.module}/gateway.yaml")

  depends_on = [
    helm_release.envoy
    # kubernetes_namespace_v1.production
  ]
}
