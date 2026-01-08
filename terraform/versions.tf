# terraform {
#   required_version = ">= 1.6.0"

#   required_providers {
#     kubernetes = { source = "hashicorp/kubernetes" }
#     helm       = { source = "hashicorp/helm" }
#     kubectl    = { source = "gavinbunney/kubectl" }
#   }
# }


#####################################
# terraform {
#   required_version = ">= 1.0"
  
#   required_providers {
#     kubernetes = {
#       source  = "hashicorp/kubernetes"
#       version = "~> 2.33"  # Updated to latest
#     }
#     helm = {
#       source  = "hashicorp/helm"
#       version = "~> 2.16"  # Updated to latest
#     }
#     kubectl = {
#       source  = "gavinbunney/kubectl"
#       version = "~> 1.18"  # Updated to latest
#     }
#   }
# }

###########################################

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
