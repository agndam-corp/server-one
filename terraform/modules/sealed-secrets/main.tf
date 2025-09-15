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

# Wait for Kubernetes API to be ready before applying manifests
resource "null_resource" "wait_for_k8s_api" {
  provisioner "local-exec" {
    command = <<-EOT
      echo "Waiting for Kubernetes API to be ready..."
      timeout=300
      start_time=$(date +%s)
      until KUBECONFIG=${var.kubeconfig_dir}/kubeconfig.yaml kubectl cluster-info &>/dev/null; do
        current_time=$(date +%s)
        elapsed_time=$((current_time - start_time))
        if [ $elapsed_time -gt $timeout ]; then
          echo "Timeout waiting for Kubernetes API"
          exit 1
        fi
        echo "Still waiting for Kubernetes API to be ready..."
        sleep 10
      done
      echo "Kubernetes API is ready!"
    EOT

    interpreter = ["/bin/bash", "-c"]
  }
}

# Check if sealed secrets key already exists
data "kubectl_file_documents" "sealed_secrets_key" {
  content = fileexists("${var.sealed_secrets_key_path}") ? file("${var.sealed_secrets_key_path}") : ""
}

# Apply the sealed secrets key if it exists
resource "kubectl_manifest" "sealed_secrets_key" {
  count = fileexists("${var.sealed_secrets_key_path}") ? 1 : 0

  yaml_body = data.kubectl_file_documents.sealed_secrets_key.documents[0]
  
  depends_on = [null_resource.wait_for_k8s_api]
}

# Install Sealed Secrets using Helm
resource "helm_release" "sealed_secrets" {
  depends_on = [kubectl_manifest.sealed_secrets_key]

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

# Wait for ArgoCD namespace to exist
resource "null_resource" "wait_for_argocd_namespace" {
  count = fileexists("${var.argocd_admin_password_path}") ? 1 : 0

  provisioner "local-exec" {
    command = <<-EOT
      echo "Waiting for ArgoCD namespace to be created..."
      timeout=120
      start_time=$(date +%s)
      until KUBECONFIG=${var.kubeconfig_dir}/kubeconfig.yaml kubectl get namespace argocd &>/dev/null; do
        current_time=$(date +%s)
        elapsed_time=$((current_time - start_time))
        if [ $elapsed_time -gt $timeout ]; then
          echo "Timeout waiting for ArgoCD namespace"
          exit 1
        fi
        echo "Still waiting for ArgoCD namespace to be created..."
        sleep 5
      done
      echo "ArgoCD namespace exists!"
    EOT

    interpreter = ["/bin/bash", "-c"]
  }

  depends_on = [helm_release.sealed_secrets, null_resource.wait_for_k8s_api]
}

# Data source to check if ArgoCD namespace exists
data "kubernetes_namespace" "argocd" {
  count = fileexists("${var.argocd_admin_password_path}") ? 1 : 0
  metadata {
    name = "argocd"
  }
  
  depends_on = [null_resource.wait_for_argocd_namespace]
}

# Apply the argocd admin password sealed secret if it exists
resource "kubectl_manifest" "argocd_admin_password" {
  count      = fileexists("${var.argocd_admin_password_path}") ? 1 : 0
  depends_on = [helm_release.sealed_secrets, null_resource.wait_for_k8s_api, null_resource.wait_for_argocd_namespace, data.kubernetes_namespace.argocd]

  yaml_body = data.kubectl_file_documents.argocd_admin_password.documents[0]
}
