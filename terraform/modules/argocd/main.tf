# resource "kubernetes_namespace_v1" "argocd" {
#   metadata { name = "argocd" }
# }

# resource "helm_release" "argocd" {
#   name       = "argocd"
#   repository = "https://argoproj.github.io/argo-helm"
#   chart      = "argo-cd"
#   namespace  = "argocd"

#   values = [<<EOF
# server:
#   service:
#     type: LoadBalancer
# EOF
# ]
# }

resource "kubernetes_namespace_v1" "argocd" {
  metadata {
    name = "argocd"
  }
}

resource "helm_release" "argocd" {
  name       = "argocd"
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-cd"
  namespace  = kubernetes_namespace_v1.argocd.metadata[0].name
  version    = "7.7.12"
  timeout    = 600
  wait       = true

  values = [
    yamlencode({
      server = {
        service = {
          type = "LoadBalancer"
        }
        resources = {
          requests = {
            cpu    = "50m"
            memory = "128Mi"
          }
        }
      }
      controller = {
        resources = {
          requests = {
            cpu    = "100m"
            memory = "256Mi"
          }
        }
      }
      repoServer = {
        resources = {
          requests = {
            cpu    = "50m"
            memory = "128Mi"
          }
        }
      }
    })
  ]

  depends_on = [kubernetes_namespace_v1.argocd]
}