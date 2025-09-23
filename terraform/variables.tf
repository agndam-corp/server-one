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
  default     = "../sealed-secrets/prd/argocd-secret-sealed.yaml"
}

variable "vpn_region" {
  description = "AWS region to deploy the VPN server"
  type        = string
  default     = "us-east-1"
}

variable "vpn_instance_type" {
  description = "EC2 instance type for the VPN server"
  type        = string
  default     = "t3.micro"
}

variable "vpn_key_name" {
  description = "Name of the EC2 key pair to use for SSH access to the VPN server"
  type        = string
}

variable "vpn_ca_cert_path" {
  description = "Path to the VPN CA certificate file"
  type        = string
}

variable "vpn_ca_key_path" {
  description = "Path to the VPN CA private key file"
  type        = string
}

variable "vpn_allowed_ssh_cidr_blocks" {
  description = "List of CIDR blocks allowed to SSH to the VPN server"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "vpn_allowed_vpn_cidr_blocks" {
  description = "List of CIDR blocks allowed to connect to the VPN server"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "vpn_create_vpc" {
  description = "Whether to create a new VPC for the VPN server"
  type        = bool
  default     = true
}

variable "vpn_vpc_id" {
  description = "ID of the existing VPC where the VPN server will be deployed (required if vpn_create_vpc is false)"
  type        = string
  default     = ""
}

variable "vpn_subnet_id" {
  description = "ID of the existing subnet where the VPN server will be deployed (required if vpn_create_vpc is false)"
  type        = string
  default     = ""
}

variable "vpn_vpc_cidr" {
  description = "CIDR block for the new VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "vpn_subnet_cidr" {
  description = "CIDR block for the new subnet"
  type        = string
  default     = "10.0.1.0/24"
}

variable "vpn_availability_zone" {
  description = "Availability zone for the subnet"
  type        = string
  default     = "us-east-1a"
}

variable "vpn_trust_anchor_arn" {
  description = "ARN of the existing IAM Roles Anywhere trust anchor"
  type        = string
}

variable "vpn_create_trust_anchor" {
  description = "Whether to create a new IAM Roles Anywhere trust anchor"
  type        = bool
  default     = false
}


