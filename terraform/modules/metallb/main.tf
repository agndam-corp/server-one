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

resource "kubernetes_namespace" "metallb" {
  metadata {
    name = "metallb-system"
    labels = {
      "pod-security.kubernetes.io/enforce" = "privileged"
      "pod-security.kubernetes.io/audit"   = "privileged"
      "pod-security.kubernetes.io/warn"    = "privileged"
    }
  }
}

# Install MetalLB using Helm
resource "helm_release" "metallb" {
  depends_on = [kubernetes_namespace.metallb]

  name       = "metallb"
  repository = "https://metallb.github.io/metallb"
  chart      = "metallb"
  version    = "0.15.2"
  namespace  = kubernetes_namespace.metallb.metadata[0].name

  # Increase timeout for the Helm release
  timeout = 300

  # Use values file for configuration
  values = [
    file("${path.module}/../../values/metallb/values.yaml")
  ]
}

# Wait for MetalLB to be ready before configuring it
resource "null_resource" "wait_for_metallb" {
  depends_on = [helm_release.metallb]

  provisioner "local-exec" {
    command = <<-EOT
      echo "Waiting for MetalLB to be ready..."
      until KUBECONFIG=${var.kubeconfig_dir}/kubeconfig.yaml kubectl -n metallb-system get pods --no-headers | grep -E "(Running|Completed)" | wc -l | grep -q "2"; do
        echo "Waiting for MetalLB pods to be ready..."
        sleep 10
      done
      echo "MetalLB is ready!"
    EOT

    interpreter = ["/bin/bash", "-c"]
  }
}

# Ignore no CRD found during plan
resource "kubectl_manifest" "metallb_ipaddresspool" {
  depends_on = [null_resource.wait_for_metallb]

  yaml_body = <<-EOT
  apiVersion: metallb.io/v1beta1
  kind: IPAddressPool
  metadata:
    name: ${var.metallb_ip_pool_name}
    namespace: ${kubernetes_namespace.metallb.metadata[0].name}
  spec:
    addresses:
%{for addr in var.metallb_ip_addresses~}
      - ${addr}
%{endfor~}
  EOT
}

resource "kubectl_manifest" "metallb_l2advertisement" {
  depends_on = [kubectl_manifest.metallb_ipaddresspool]

  yaml_body = <<-EOT
  apiVersion: metallb.io/v1beta1
  kind: L2Advertisement
  metadata:
    name: production
    namespace: ${kubernetes_namespace.metallb.metadata[0].name}
  spec:
    ipAddressPools:
      - ${var.metallb_ip_pool_name}
  EOT
}

