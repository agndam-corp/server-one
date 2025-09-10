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
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = ">= 1.19.0"
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

# Wait for ArgoCD to be ready before deploying applications
resource "null_resource" "wait_for_argocd" {
  depends_on = [helm_release.argocd]

  provisioner "local-exec" {
    command = <<-EOT
      echo "Waiting for ArgoCD to be ready..."
      until KUBECONFIG=${var.kubeconfig_dir}/kubeconfig.yaml kubectl -n argocd get pods --no-headers | grep -E "(Running|Completed)" | wc -l | grep -q "7"; do
        echo "Waiting for ArgoCD pods to be ready..."
        sleep 10
      done
      echo "ArgoCD is ready!"
    EOT

    interpreter = ["/bin/bash", "-c"]
  }
}

# Deploy the App of Apps definition
resource "kubectl_manifest" "app_of_apps" {
  depends_on = [null_resource.wait_for_argocd]

  yaml_body = <<-EOT
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: app-of-apps
  namespace: argocd
spec:
  project: default
  source:
    repoURL: ${var.argocd_applications_repo_url}
    path: ${var.argocd_applications_path}
    targetRevision: HEAD
  destination:
    server: https://kubernetes.default.svc
    namespace: argocd
EOT
}
