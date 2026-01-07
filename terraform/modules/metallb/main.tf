resource "kubernetes_namespace" "ns" {
  metadata { name = "metallb-system" }
}

resource "helm_release" "metallb" {
  name       = "metallb"
  repository = "https://metallb.github.io/metallb"
  chart      = "metallb"
  namespace  = kubernetes_namespace.ns.metadata[0].name
}

resource "kubectl_manifest" "pool" {
  yaml_body = <<EOF
apiVersion: metallb.io/v1beta1
kind: IPAddressPool
metadata:
  name: pool
  namespace: metallb-system
spec:
  addresses:
  - ${var.ip_range}
EOF
}
