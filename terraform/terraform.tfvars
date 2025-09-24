# Terraform variables for K3s cluster and ArgoCD setup

# Cluster configuration
cluster_name = "k3s-cluster"

# Kubeconfig directory
kubeconfig_dir = "/home/ubuntu/.kube"

# GitHub SSH private key path
github_ssh_private_key_path = "../private/githubconnection"

# VPN configuration
vpn_region                  = "us-east-1"
vpn_instance_type           = "t3.micro"
vpn_key_name                = "my-vpn-keypair"
vpn_ca_cert_path            = "/home/ubuntu/webapp/project/private/agndam-root-ca.crt"
vpn_ca_key_path             = "/home/ubuntu/webapp/project/private/agndam-root-ca.key"
vpn_allowed_ssh_cidr_blocks = ["0.0.0.0/0"]
vpn_allowed_vpn_cidr_blocks = ["0.0.0.0/0"]

# IAM Roles Anywhere configuration
# If you've already created a trust anchor, set create_trust_anchor to false and provide the ARN
vpn_create_trust_anchor = false
vpn_trust_anchor_arn    = "arn:aws:rolesanywhere:us-east-1:015482588147:trust-anchor/79c0c605-d2bc-4f48-83eb-aa1bc9717253"

# VPC configuration
# Set create_vpc to false if you want to use an existing VPC
vpn_create_vpc = true
# If create_vpc is false, you must provide the following:
# vpn_vpc_id = "vpc-xxxxxxxx"
# vpn_subnet_id = "subnet-xxxxxxxx"
# If create_vpc is true, you can customize the following (optional):
# vpn_vpc_cidr = "10.0.0.0/16"
# vpn_subnet_cidr = "10.0.1.0/24"
# vpn_availability_zone = "us-east-1a"
