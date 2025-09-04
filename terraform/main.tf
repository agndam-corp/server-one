# Main Terraform configuration for K3s cluster and ArgoCD

# Provider configurations
provider "null" {
  # Configuration for the null provider
}

provider "helm" {
  kubernetes {
    config_path = "${var.kubeconfig_dir}/kubeconfig.yaml"
  }
}

provider "kubernetes" {
  config_path = "${var.kubeconfig_dir}/kubeconfig.yaml"
}

# Resource to install K3s using the null_resource provider
# This approach executes shell commands to set up the cluster
resource "null_resource" "install_k3s" {
  # Trigger recreation if cluster_name variable changes
  triggers = {
    cluster_name = var.cluster_name
  }

  # Provisioner to download and install K3s with encryption and kubeconfig options
  provisioner "local-exec" {
    command = <<-EOT
      # Download and install K3s with encryption enabled and kubeconfig written
      # Using --write-kubeconfig-mode 644 to make kubeconfig readable
      # Using --secrets-encryption to enable secrets encryption
      curl -sfL https://get.k3s.io | sh -s - --write-kubeconfig-mode 644 --secrets-encryption
      
      # Wait for K3s to be ready
      until sudo k3s kubectl get nodes &>/dev/null; do
        echo "Waiting for K3s to be ready..."
        sleep 5
      done
      
      echo "K3s installed and ready with encryption enabled!"
    EOT

    interpreter = ["/bin/bash", "-c"]
  }

  # Provisioner to output kubeconfig
  provisioner "local-exec" {
    command = <<-EOT
      # Ensure the kubeconfig directory exists
      mkdir -p ${var.kubeconfig_dir}
      
      # Copy the kubeconfig file
      sudo cp /etc/rancher/k3s/k3s.yaml ${var.kubeconfig_dir}/kubeconfig.yaml
      
      # Update the kubeconfig file with the correct cluster name
      sed -i "s/default/${var.cluster_name}/g" ${var.kubeconfig_dir}/kubeconfig.yaml
      
      echo "Kubeconfig copied to ${var.kubeconfig_dir}/kubeconfig.yaml"
    EOT

    interpreter = ["/bin/bash", "-c"]
  }
}

# Resource to ensure K3s is running (checks if the process is active)
resource "null_resource" "k3s_running_check" {
  depends_on = [null_resource.install_k3s]

  triggers = {
    cluster_name = var.cluster_name
  }

  provisioner "local-exec" {
    command = <<-EOT
      echo "Checking if K3s is running..."
      if sudo systemctl is-active --quiet k3s; then
        echo "K3s is running"
      else
        echo "K3s is not running"
        exit 1
      fi
    EOT

    interpreter = ["/bin/bash", "-c"]
  }
}

# Create namespace for ArgoCD
resource "kubernetes_namespace" "argocd" {
  depends_on = [null_resource.k3s_running_check]

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
    type = "git"
    url  = "git@github.com:DamianJaskolski95/k8s-server.git"
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
  version    = "7.7.10" # Use a specific version for stability
  namespace  = kubernetes_namespace.argocd.metadata[0].name

  # Increase timeout for the Helm release
  timeout = 600

  # Expose ArgoCD server with NodePort service (for local development)
  set {
    name  = "server.service.type"
    value = "NodePort"
  }

  # Set server name
  set {
    name  = "server.name"
    value = "argocd-server"
  }

  # Set NodePort for HTTP
  set {
    name  = "server.service.nodePortHttp"
    value = "30080"
  }

  # Set NodePort for HTTPS
  set {
    name  = "server.service.nodePortHttps"
    value = "30443"
  }
}
