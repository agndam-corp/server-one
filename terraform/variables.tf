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

variable "github_ssh_private_key_path" {
  description = "Path to the SSH private key file for accessing the GitHub repository"
  type        = string
  default     = "../private/githubconnection"
}

variable "argocd_applications_repo_url" {
  description = "The Git repository URL for ArgoCD applications"
  type        = string
  default     = "git@github.com:DamianJaskolski95/k8s-server.git"
}

variable "argocd_applications_path" {
  description = "The path in the Git repository where ArgoCD applications are defined"
  type        = string
  default     = "argocd/prd/applications"
}

variable "sealed_secrets_key_path" {
  description = "Path to the sealed secrets key backup file"
  type        = string
  default     = "../private/sealed-secrets-key-backup.yaml"
}

variable "argocd_admin_password_path" {
  description = "Path to the argocd admin password sealed secret file"
  type        = string
  default     = "../sealed-secrets/argocd-admin-password-sealed.yaml"
}


