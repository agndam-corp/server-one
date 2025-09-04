# Terraform and provider versions
terraform {
  required_version = ">= 1.0"

  required_providers {
    # Using null provider for executing shell commands to install K3s
    null = {
      source  = "hashicorp/null"
      version = "~> 3.0"
    }
    
    # Using Helm provider for installing ArgoCD
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.0"
    }
    
    # Using Kubernetes provider for interacting with the cluster
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.0"
    }
  }
}