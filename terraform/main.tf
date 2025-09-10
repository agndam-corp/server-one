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

provider "kubectl" {
  config_path = "${var.kubeconfig_dir}/kubeconfig.yaml"
}

# Resource to clean up any existing K3s installation
resource "null_resource" "cleanup_k3s" {
  triggers = {
    cluster_name = var.cluster_name
  }

  provisioner "local-exec" {
    when    = destroy
    command = "${path.module}/cleanup.sh"
  }
}

# Resource to install K3s using the null_resource provider
# This approach executes shell commands to set up the cluster
resource "null_resource" "install_k3s" {
  depends_on = [null_resource.cleanup_k3s]

  # Trigger recreation if cluster_name variable changes
  triggers = {
    cluster_name = var.cluster_name
  }

  # Provisioner to download and install K3s with encryption and kubeconfig options
  provisioner "local-exec" {
    command = <<-EOT
      # Create Traefik config with fixed node ports before installing K3s
      mkdir -p /var/lib/rancher/k3s/server/manifests
      cat > /var/lib/rancher/k3s/server/manifests/traefik-config.yaml << 'EOF'
apiVersion: helm.cattle.io/v1
kind: HelmChartConfig
metadata:
  name: traefik
  namespace: kube-system
spec:
  valuesContent: |-
    ports:
      web:
        nodePort: 31292
      websecure:
        nodePort: 32286
EOF
      
      # Download and install K3s with encryption enabled and kubeconfig written
      # Using --write-kubeconfig-mode 644 to make kubeconfig readable
      # Using --secrets-encryption to enable secrets encryption
      curl -sfL https://get.k3s.io | sh -s - --write-kubeconfig-mode 644 --secrets-encryption
      
      # Wait for K3s to be ready
      until sudo k3s kubectl get nodes &>/dev/null; do
        echo "Waiting for K3s to be ready..."
        sleep 5
      done
      
      echo "K3s installed and ready with encryption enabled and fixed Traefik node ports!"
    EOT

    interpreter = ["/bin/bash", "-c"]
  }

  # Provisioner to output kubeconfig and set up k9s context
  provisioner "local-exec" {
    command = <<-EOT
      # Ensure the kubeconfig directory exists
      mkdir -p ${var.kubeconfig_dir}
      
      # Copy the kubeconfig file
      sudo cp /etc/rancher/k3s/k3s.yaml ${var.kubeconfig_dir}/kubeconfig.yaml
      
      # Update the kubeconfig file with the correct cluster name
      sed -i "s/default/${var.cluster_name}/g" ${var.kubeconfig_dir}/kubeconfig.yaml
      
      # Set proper permissions
      chmod 600 ${var.kubeconfig_dir}/kubeconfig.yaml
      
      # Set up k9s config directory
      mkdir -p ~/.config/k9s
      
      # Create k9s config file
      cat > ~/.config/k9s/config.yaml << EOF
k9s:
  refreshRate: 2
  maxConnRetry: 5
  enableMouse: false
  headless: false
  logoless: false
  crumbsless: false
  readOnly: false
  noExitOnCtrlC: false
  ui:
    enableMouse: false
    headless: false
    logoless: false
    crumbsless: false
    reactive: false
    noIcons: false
  skipLatestRevCheck: false
  disablePodCounting: false
  shellPod:
    image: busybox:1.35.0
    command: []
    args: []
    namespace: default
    limits:
      cpu: 100m
      memory: 100Mi
  imageScans:
    enable: true
    exclusions:
      namespaces: []
      labels: {}
  logger:
    tail: 100
    buffer: 5000
    sinceSeconds: 60
    fullScreen: false
    textWrap: false
    showTime: false
  thresholds:
    cpu:
      critical: 90
      warn: 70
    memory:
      critical: 90
      warn: 70
EOF
      
      # Set KUBECONFIG environment variable
      export KUBECONFIG=${var.kubeconfig_dir}/kubeconfig.yaml
      
      echo "Kubeconfig copied to ${var.kubeconfig_dir}/kubeconfig.yaml"
      echo "k9s configuration created"
      echo "To use k9s with the new cluster, run: export KUBECONFIG=${var.kubeconfig_dir}/kubeconfig.yaml && k9s"
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

# Resource to wait for the cluster to be fully ready
resource "null_resource" "cluster_ready" {
  depends_on = [null_resource.k3s_running_check]

  provisioner "local-exec" {
    command = <<-EOT
      echo "Waiting for cluster to be fully ready..."
      # Wait for core system pods to be running
      until sudo k3s kubectl wait --for=condition=Ready pods --all -A --timeout=300s &>/dev/null; do
        echo "Waiting for all pods to be ready..."
        sleep 30
      done
      echo "Cluster is fully ready!"
    EOT

    interpreter = ["/bin/bash", "-c"]
  }
}

# Deploy Sealed Secrets
module "sealed_secrets" {
  source = "./modules/sealed-secrets"

  providers = {
    kubernetes = kubernetes
    helm       = helm
    kubectl    = kubectl
  }

  depends_on = [null_resource.cluster_ready]

  kubeconfig_dir              = var.kubeconfig_dir
  sealed_secrets_key_path     = var.sealed_secrets_key_path
  argocd_admin_password_path  = var.argocd_admin_password_path
}

# Deploy ArgoCD
module "argocd" {
  source = "./modules/argocd"

  providers = {
    kubernetes = kubernetes
    helm       = helm
    kubectl    = kubectl
  }

  depends_on = [module.sealed_secrets]

  kubeconfig_dir               = var.kubeconfig_dir
  github_ssh_private_key_path  = var.github_ssh_private_key_path
  argocd_applications_repo_url = var.argocd_applications_repo_url
  argocd_applications_path     = var.argocd_applications_path
}
