terraform {
  required_providers {
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = ">= 1.19.0"
    }
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

# Create kube-system namespace if it doesn't exist
resource "kubernetes_namespace" "kube_system" {
  metadata {
    name = "kube-system"
  }
}

# Check if sealed secrets key already exists
data "kubectl_file_documents" "sealed_secrets_key" {
  content = fileexists("${var.sealed_secrets_key_path}") ? file("${var.sealed_secrets_key_path}") : ""
}

# Apply the sealed secrets key if it exists
resource "kubectl_manifest" "sealed_secrets_key" {
  count      = fileexists("${var.sealed_secrets_key_path}") ? 1 : 0
  depends_on = [kubernetes_namespace.kube_system]

  yaml_body = data.kubectl_file_documents.sealed_secrets_key.documents[0]
}

# Install Sealed Secrets using Helm
resource "helm_release" "sealed_secrets" {
  depends_on = [kubernetes_namespace.kube_system, kubectl_manifest.sealed_secrets_key]

  name       = "sealed-secrets"
  repository = "https://bitnami-labs.github.io/sealed-secrets"
  chart      = "sealed-secrets"
  version    = "2.17.4"
  namespace  = "kube-system"

  # Increase timeout for the Helm release
  timeout = 600

  # Use values file for configuration
  values = [
    file("${path.module}/../../values/sealed-secrets/values.yaml")
  ]
}

# Check if argocd admin password sealed secret exists
data "kubectl_file_documents" "argocd_admin_password" {
  content = fileexists("${var.argocd_admin_password_path}") ? file("${var.argocd_admin_password_path}") : ""
}

# Apply the argocd admin password sealed secret if it exists
resource "kubectl_manifest" "argocd_admin_password" {
  count      = fileexists("${var.argocd_admin_password_path}") ? 1 : 0
  depends_on = [helm_release.sealed_secrets]

  yaml_body = data.kubectl_file_documents.argocd_admin_password.documents[0]
}
