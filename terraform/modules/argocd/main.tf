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

# Reference to the already created ArgoCD namespace
data "kubernetes_namespace" "argocd_ns" {
  metadata {
    name = "argocd"
  }
}

# Create a Kubernetes secret for the SSH key
resource "kubernetes_secret" "argocd_ssh_key" {
  depends_on = [data.kubernetes_namespace.argocd_ns]

  metadata {
    name      = "argocd-ssh-key"
    namespace = data.kubernetes_namespace.argocd_ns.metadata[0].name
  }

  data = {
    # Read SSH private key from file
    "sshPrivateKey" = file(var.github_ssh_private_key_path)
  }

  type = "Opaque"
}

# Create a repository credential secret for ArgoCD
resource "kubernetes_secret" "argocd_repo_secret" {
  depends_on = [data.kubernetes_namespace.argocd_ns, kubernetes_secret.argocd_ssh_key]

  metadata {
    name      = "private-repo"
    namespace = data.kubernetes_namespace.argocd_ns.metadata[0].name
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
  depends_on = [data.kubernetes_namespace.argocd_ns, kubernetes_secret.argocd_ssh_key, kubernetes_secret.argocd_repo_secret]

  name       = "argocd"
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-cd"
  version    = "8.3.5" # Use a specific version for stability
  namespace  = data.kubernetes_namespace.argocd_ns.metadata[0].name

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
      until KUBECONFIG=${var.kubeconfig_dir}/kubeconfig.yaml kubectl -n argocd get pods --field-selector=status.phase!=Succeeded,status.phase!=Failed --no-headers | grep -E "Running" | wc -l | grep -q "7"; do
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
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
EOT
}

# Wait for cert-manager to be ready
resource "null_resource" "wait_for_cert_manager" {
  depends_on = [kubectl_manifest.app_of_apps]

  provisioner "local-exec" {
    command = <<-EOT
      echo "Waiting for cert-manager to be ready..."
      until KUBECONFIG=${var.kubeconfig_dir}/kubeconfig.yaml kubectl -n cert-manager get pods --field-selector=status.phase!=Succeeded,status.phase!=Failed --no-headers | grep -E "Running" | wc -l | grep -q "4"; do
        echo "Waiting for cert-manager pods to be ready..."
        sleep 10
      done
      echo "cert-manager is ready!"
    EOT

    interpreter = ["/bin/bash", "-c"]
  }
}

# Wait for certificates to be issued
resource "null_resource" "wait_for_certificates" {
  depends_on = [null_resource.wait_for_cert_manager]

  provisioner "local-exec" {
    command = <<-EOT
      echo "Waiting for certificates to be issued..."
      until KUBECONFIG=${var.kubeconfig_dir}/kubeconfig.yaml kubectl -n argocd get certificate argocd-djasko-com -o jsonpath='{.status.conditions[?(@.type=="Ready")].status}' | grep -q "True"; do
        echo "Waiting for certificate to be ready..."
        sleep 10
      done
      echo "Certificate is ready!"
    EOT

    interpreter = ["/bin/bash", "-c"]
  }
}

# Update Traefik service to remove port 80
resource "null_resource" "traefik_service_update" {
  depends_on = [null_resource.wait_for_certificates]

  provisioner "local-exec" {
    command = "KUBECONFIG=${var.kubeconfig_dir}/kubeconfig.yaml kubectl apply -f ${path.module}/manifests/traefik-service.yaml"
  }
}

# Update ArgoCD service to remove NodePort access
resource "null_resource" "argocd_service_update" {
  depends_on = [null_resource.wait_for_certificates]

  provisioner "local-exec" {
    command = "KUBECONFIG=${var.kubeconfig_dir}/kubeconfig.yaml kubectl apply -f ${path.module}/manifests/argocd-service.yaml"
  }
}
