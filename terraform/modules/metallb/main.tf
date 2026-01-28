# resource "kubernetes_namespace_v1" "ns" {
#   metadata { name = "metallb-system" }
# }

# resource "helm_release" "metallb" {
#   name       = "metallb"
#   repository = "https://metallb.github.io/metallb"
#   chart      = "metallb"
#   namespace  = kubernetes_namespace_v1.ns.metadata[0].name
# }

# # resource "kubectl_manifest" "pool" {
# #   yaml_body = <<EOF
# # apiVersion: metallb.io/v1beta1
# # kind: IPAddressPool
# # metadata:
# #   name: pool
# #   namespace: metallb-system
# # spec:
# #   addresses:
# #   - ${var.ip_range}
# # EOF
# # }

# resource "kubectl_manifest" "pool" {
#   yaml_body = yamlencode({
#     apiVersion = "metallb.io/v1beta1"
#     kind       = "IPAddressPool"
#     metadata = {
#       name      = "pool"
#       namespace = "metallb-system"
#     }
#     spec = {
#       addresses = [var.ip_range]
#     }
#   })

#   lifecycle {
#     ignore_changes = [yaml_body]
#   }

#   depends_on = [helm_release.metallb]
# }

resource "kubernetes_namespace_v1" "ns" {
  metadata {
    name = "metallb-system"
  }
}

resource "helm_release" "metallb" {
  name       = "metallb"
  repository = "https://metallb.github.io/metallb"
  chart      = "metallb"
  namespace  = kubernetes_namespace_v1.ns.metadata[0].name
  version    = "0.14.9"

  timeout       = 300
  wait          = true
  wait_for_jobs = true

  depends_on = [kubernetes_namespace_v1.ns]
}

resource "kubectl_manifest" "pool" {
  yaml_body = yamlencode({
    apiVersion = "metallb.io/v1beta1"
    kind       = "IPAddressPool"
    metadata = {
      name      = "pool"
      namespace = "metallb-system"
    }
    spec = {
      addresses = [var.ip_range]
    }
  })

  depends_on = [helm_release.metallb]
}

resource "kubectl_manifest" "l2" {
  yaml_body = yamlencode({
    apiVersion = "metallb.io/v1beta1"
    kind       = "L2Advertisement"
    metadata = {
      name      = "l2"
      namespace = "metallb-system"
    }
    spec = {
      ipAddressPools = ["pool"]
    }
  })

  depends_on = [kubectl_manifest.pool]
}