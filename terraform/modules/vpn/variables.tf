# Variables for the VPN module

variable "region" {
  description = "AWS region to deploy the VPN server"
  type        = string
  default     = "us-east-1"
}

variable "instance_type" {
  description = "EC2 instance type for the VPN server"
  type        = string
  default     = "t3.micro"
}

variable "key_name" {
  description = "Name of the EC2 key pair to use for SSH access"
  type        = string
}

variable "create_vpc" {
  description = "Whether to create a new VPC for the VPN server"
  type        = bool
  default     = true
}

variable "vpc_id" {
  description = "ID of the existing VPC where the VPN server will be deployed (required if create_vpc is false)"
  type        = string
  default     = ""
}

variable "subnet_id" {
  description = "ID of the existing subnet where the VPN server will be deployed (required if create_vpc is false)"
  type        = string
  default     = ""
}

variable "vpc_cidr" {
  description = "CIDR block for the new VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "subnet_cidr" {
  description = "CIDR block for the new subnet"
  type        = string
  default     = "10.0.1.0/24"
}

variable "availability_zone" {
  description = "Availability zone for the subnet"
  type        = string
  default     = "us-east-1a"
}

variable "vpn_ca_cert_path" {
  description = "Path to the VPN CA certificate file"
  type        = string
}

variable "vpn_ca_key_path" {
  description = "Path to the VPN CA private key file"
  type        = string
}

variable "allowed_ssh_cidr_blocks" {
  description = "List of CIDR blocks allowed to SSH to the VPN server"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "allowed_vpn_cidr_blocks" {
  description = "List of CIDR blocks allowed to connect to the VPN server"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "trust_anchor_arn" {
  description = "ARN of the existing IAM Roles Anywhere trust anchor"
  type        = string
}

variable "create_trust_anchor" {
  description = "Whether to create a new IAM Roles Anywhere trust anchor"
  type        = bool
  default     = false
}