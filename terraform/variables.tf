# Input variables for the K3s cluster and ArgoCD Terraform configuration

variable "cluster_name" {
  description = "The name of the K3s cluster"
  type        = string
  default     = "k3s-cluster"
}

variable "kubeconfig_dir" {
  description = "The directory where the kubeconfig file will be stored"
  type        = string
  default     = "/home/ubuntu/.kube"
}

variable "argocd_admin_password" {
  description = "The admin password for ArgoCD"
  type        = string
  sensitive   = true
  default     = "admin123"  # Default password - should be changed in production
}
