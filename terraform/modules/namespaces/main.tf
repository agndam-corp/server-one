terraform {
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.0"
    }
  }
}

# Create all required namespaces
resource "kubernetes_namespace" "required" {
  for_each = var.namespaces

  metadata {
    name = each.key
    labels = lookup(each.value, "labels", {})
    annotations = lookup(each.value, "annotations", {})
  }
}