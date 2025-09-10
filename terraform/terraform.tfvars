# Terraform variables for K3s cluster and ArgoCD setup

# Cluster configuration
cluster_name = "k3s-cluster"

# Kubeconfig directory
kubeconfig_dir = "/home/ubuntu/.kube"

# GitHub SSH private key path
github_ssh_private_key_path = "../private/githubconnection"

# ArgoCD applications repository configuration
argocd_applications_repo_url = "git@github.com:DamianJaskolski95/k8s-server.git"
argocd_applications_path     = "argocd/prd/applications"

# Sealed Secrets configuration
sealed_secrets_key_path     = "../private/sealed-secrets-key-backup.yaml"
argocd_admin_password_path  = "../sealed-secrets/argocd-admin-password-sealed.yaml"


