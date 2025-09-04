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
