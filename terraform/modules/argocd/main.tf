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

############################################
# Namespace
############################################
resource "kubernetes_namespace_v1" "argocd" {
  metadata {
    name = "argocd"
  }
}

############################################
# ArgoCD Installation (Helm)
############################################
resource "helm_release" "argocd" {
  name       = "argocd"
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-cd"
  namespace  = kubernetes_namespace_v1.argocd.metadata[0].name
  version    = "7.7.12"

  timeout = 600
  wait    = true

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

  depends_on = [
    kubernetes_namespace_v1.argocd
  ]
}

############################################
# ArgoCD Application (GitOps)
############################################
# resource "kubectl_manifest" "fastapi_prod_app" {

#   depends_on = [
#     helm_release.argocd
#   ]

#   yaml_body = <<EOF
# apiVersion: argoproj.io/v1alpha1
# kind: Application
# metadata:
#   name: fastapi-prod
#   namespace: argocd
# spec:
#   project: default

#   source:
#     repoURL: http://192.168.0.190/root/project_nebula.git
#     targetRevision: master
#     path: k8s/production

#   destination:
#     server: https://kubernetes.default.svc
#     namespace: production

#   syncPolicy:
#     automated:
#       prune: true
#       selfHeal: true
# EOF
# }
