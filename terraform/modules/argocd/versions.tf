# terraform {
#   required_providers {
#     kubernetes = {
#       source = "hashicorp/kubernetes"
#     }
#     helm = {
#       source = "hashicorp/helm"
#     }
#   }
# }
terraform {
  required_providers {

    kubectl = {
      source  = "gavinbunney/kubectl"
      version = "~> 1.19"
    }

    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.33"
    }

    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.16"
    }
  }
}
