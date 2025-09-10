# Terraform variables for K3s cluster and ArgoCD setup

# Cluster configuration
cluster_name = "k3s-cluster"

# Kubeconfig directory
kubeconfig_dir = "/home/ubuntu/.kube"

# GitHub SSH private key path
github_ssh_private_key_path = "../private/githubconnection"

# MetalLB IP addresses (list of CIDR blocks)
# Using a range that should be available in your subnet
metallb_ip_addresses = ["146.59.44.100-146.59.44.110"]

# MetalLB name for pool adresses
metallb_ip_pool_name = "production"
