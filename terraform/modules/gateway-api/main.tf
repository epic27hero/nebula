# resource "kubernetes_namespace_v1" "gw" {
#   metadata { name = "gateway-system" }
# }

# resource "helm_release" "envoy" {
#   name       = "envoy-gateway"
#   repository = "oci://docker.io/envoyproxy"
#   chart      = "gateway-helm"
#   namespace  = kubernetes_namespace_v1.gw.metadata[0].name
# }



resource "kubernetes_namespace_v1" "gw" {
  metadata { name = "gateway-system" }
}

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

resource "helm_release" "envoy" {
  name       = "envoy-gateway"
  repository = "oci://docker.io/envoyproxy"
  chart      = "gateway-helm"

  namespace        = "gateway-system"
  create_namespace = false

  dependency_update = true
  atomic             = true
  cleanup_on_fail    = true
}