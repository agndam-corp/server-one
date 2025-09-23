# Outputs for the VPN module

output "vpn_server_public_ip" {
  description = "Public IP address of the VPN server"
  value       = aws_instance.vpn_server.public_ip
}

output "vpn_server_instance_id" {
  description = "Instance ID of the VPN server"
  value       = aws_instance.vpn_server.id
}

output "vpn_server_security_group_id" {
  description = "Security group ID of the VPN server"
  value       = aws_security_group.vpn_server_sg.id
}

output "iam_role_arn" {
  description = "ARN of the IAM role for the VPN server"
  value       = aws_iam_role.vpn_server_role.arn
}

output "iam_instance_profile_name" {
  description = "Name of the IAM instance profile for the VPN server"
  value       = aws_iam_instance_profile.vpn_server_profile.name
}

output "roles_anywhere_trust_anchor_arn" {
  description = "ARN of the IAM Roles Anywhere trust anchor"
  value       = var.create_trust_anchor ? aws_rolesanywhere_trust_anchor.vpn_ca[0].arn : var.trust_anchor_arn
}

output "roles_anywhere_profile_arn" {
  description = "ARN of the IAM Roles Anywhere profile"
  value       = aws_rolesanywhere_profile.vpn_server.arn
}

output "vpc_id" {
  description = "ID of the VPC (created or existing)"
  value       = var.create_vpc ? aws_vpc.vpn_vpc[0].id : var.vpc_id
}

output "subnet_id" {
  description = "ID of the subnet (created or existing)"
  value       = var.create_vpc ? aws_subnet.vpn_subnet[0].id : var.subnet_id
}

output "webapp_control_role_arn" {
  description = "ARN of the IAM role for webapp to control the VPN instance"
  value       = aws_iam_role.webapp_vpn_control_role.arn
}