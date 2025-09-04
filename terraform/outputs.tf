# Output values from the K3s cluster and ArgoCD setup

output "cluster_name" {
  description = "The name of the created K3s cluster"
  value       = var.cluster_name
}

output "kubeconfig_path" {
  description = "The path to the kubeconfig file for the cluster"
  value       = "${var.kubeconfig_dir}/kubeconfig.yaml"
}

# Output the command to set KUBECONFIG environment variable
output "kubeconfig_command" {
  description = "Command to set KUBECONFIG environment variable"
  value       = "export KUBECONFIG=${var.kubeconfig_dir}/kubeconfig.yaml"
}

# Output the command to check cluster nodes
output "check_nodes_command" {
  description = "Command to check cluster nodes"
  value       = "kubectl get nodes"
}

# ArgoCD outputs
output "argocd_http_url" {
  description = "The HTTP URL to access ArgoCD"
  value       = "http://localhost:30080"
}

output "argocd_https_url" {
  description = "The HTTPS URL to access ArgoCD"
  value       = "https://localhost:30443"
}

output "argocd_get_password_command" {
  description = "Command to get the auto-generated ArgoCD admin password"
  value       = "kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d"
}