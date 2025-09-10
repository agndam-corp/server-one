terraform {
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = ">= 2.0"
    }
  }
}

# Create namespace for ArgoCD
resource "kubernetes_namespace" "argocd" {
  metadata {
    name = "argocd"
  }
}

# Create a Kubernetes secret for the SSH key
resource "kubernetes_secret" "argocd_ssh_key" {
  depends_on = [kubernetes_namespace.argocd]

  metadata {
    name      = "argocd-ssh-key"
    namespace = kubernetes_namespace.argocd.metadata[0].name
  }

  data = {
    # Read SSH private key from file
    "sshPrivateKey" = file(var.github_ssh_private_key_path)
  }

  type = "Opaque"
}

# Create a repository credential secret for ArgoCD
resource "kubernetes_secret" "argocd_repo_secret" {
  depends_on = [kubernetes_namespace.argocd, kubernetes_secret.argocd_ssh_key]

  metadata {
    name      = "private-repo"
    namespace = kubernetes_namespace.argocd.metadata[0].name
    labels = {
      "argocd.argoproj.io/secret-type" = "repository"
    }
  }

  data = {
    type          = "git"
    url           = "git@github.com:DamianJaskolski95/k8s-server.git"
    sshPrivateKey = file(var.github_ssh_private_key_path)
  }

  type = "Opaque"
}

# Install ArgoCD using Helm
resource "helm_release" "argocd" {
  depends_on = [kubernetes_namespace.argocd, kubernetes_secret.argocd_ssh_key, kubernetes_secret.argocd_repo_secret]

  name       = "argocd"
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-cd"
  version    = "8.3.5" # Use a specific version for stability
  namespace  = kubernetes_namespace.argocd.metadata[0].name

  # Increase timeout for the Helm release
  timeout = 600

  # Use values file for configuration
  values = [
    file("${path.module}/../../values/argocd/values.yaml")
  ]
}
