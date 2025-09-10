variable "github_ssh_private_key_path" {
  description = "Path to the SSH private key file for accessing the GitHub repository"
  type        = string
  default     = "provide_me"
}

variable "kubeconfig_dir" {
  description = "The directory where the kubeconfig file will be stored"
  type        = string
  default     = "/home/ubuntu/.kube"
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
