variable "metallb_ip_addresses" {
  description = "IP addresses for MetalLB to use"
  type        = list(string)
  default     = ["146.59.45.254/32"]
}

variable "kubeconfig_dir" {
  description = "The directory where the kubeconfig file will be stored"
  type        = string
  default     = "/home/ubuntu/.kube"
}

variable "metallb_ip_pool_name" {
  description = "Name for pool adresses"
  type        = string
  default     = "production"
}
