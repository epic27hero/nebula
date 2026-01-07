resource "kubernetes_namespace" "gw" {
  metadata { name = "gateway-system" }
}

resource "helm_release" "envoy" {
  name       = "envoy-gateway"
  repository = "oci://docker.io/envoyproxy"
  chart      = "gateway-helm"
  namespace  = kubernetes_namespace.gw.metadata[0].name
}
