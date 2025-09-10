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

variable "kubeconfig_dir" {
  description = "The directory where the kubeconfig file will be stored"
  type        = string
  default     = "/home/ubuntu/.kube"
}