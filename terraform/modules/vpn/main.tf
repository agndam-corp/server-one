# Terraform module for VPN server with IAM Roles Anywhere

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# Create VPC for the VPN server if not provided
resource "aws_vpc" "vpn_vpc" {
  count = var.create_vpc ? 1 : 0

  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "vpn-vpc"
  }
}

# Create Internet Gateway for the VPC
resource "aws_internet_gateway" "vpn_igw" {
  count  = var.create_vpc ? 1 : 0
  vpc_id = aws_vpc.vpn_vpc[0].id

  tags = {
    Name = "vpn-igw"
  }
}

# Create a public subnet
resource "aws_subnet" "vpn_subnet" {
  count = var.create_vpc ? 1 : 0

  vpc_id                  = aws_vpc.vpn_vpc[0].id
  cidr_block              = var.subnet_cidr
  availability_zone       = var.availability_zone
  map_public_ip_on_launch = true

  tags = {
    Name = "vpn-subnet"
  }
}

# Create route table for the VPC
resource "aws_route_table" "vpn_route_table" {
  count  = var.create_vpc ? 1 : 0
  vpc_id = aws_vpc.vpn_vpc[0].id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.vpn_igw[0].id
  }

  tags = {
    Name = "vpn-route-table"
  }
}

# Associate route table with subnet
resource "aws_route_table_association" "vpn_route_table_association" {
  count          = var.create_vpc ? 1 : 0
  subnet_id      = aws_subnet.vpn_subnet[0].id
  route_table_id = aws_route_table.vpn_route_table[0].id
}

# Create IAM role for the VPN server
resource "aws_iam_role" "vpn_server_role" {
  name = "vpn-server-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

# Create IAM role for the webapp to control the VPN server
resource "aws_iam_role" "webapp_vpn_control_role" {
  name = "webapp-vpn-control-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "rolesanywhere.amazonaws.com"
        }
        Action = "sts:AssumeRole"
        Condition = {
          StringEquals = {
            "aws:PrincipalTag/x509Subject/CN" = "webapp"
          }
          ArnEquals = {
            "aws:SourceArn" = var.trust_anchor_arn
          }
        }
      }
    ]
  })
}

# Attach necessary policies to the VPN server IAM role
resource "aws_iam_role_policy_attachment" "vpn_server_policy" {
  role       = aws_iam_role.vpn_server_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# Create policy for webapp to control VPN instance
resource "aws_iam_policy" "webapp_vpn_control_policy" {
  name        = "webapp-vpn-control-policy"
  description = "Policy for webapp to control VPN instance"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ec2:StartInstances",
          "ec2:StopInstances",
          "ec2:DescribeInstances",
          "ec2:DescribeInstanceStatus"
        ]
        Resource = "arn:aws:ec2:${var.region}:${data.aws_caller_identity.current.account_id}:instance/${aws_instance.vpn_server.id}"
      },
      {
        Effect = "Allow"
        Action = [
          "ec2:DescribeInstances",
          "ec2:DescribeInstanceStatus"
        ]
        Resource = "*"
      }
    ]
  })
}

# Attach policy to webapp role
resource "aws_iam_role_policy_attachment" "webapp_vpn_control_policy_attachment" {
  role       = aws_iam_role.webapp_vpn_control_role.name
  policy_arn = aws_iam_policy.webapp_vpn_control_policy.arn
}

# Create IAM instance profile for the VPN server
resource "aws_iam_instance_profile" "vpn_server_profile" {
  name = "vpn-server-profile"
  role = aws_iam_role.vpn_server_role.name
}

# Create security group for the VPN server
resource "aws_security_group" "vpn_server_sg" {
  vpc_id = var.create_vpc ? aws_vpc.vpn_vpc[0].id : var.vpc_id

  name        = "vpn-server-sg"
  description = "Security group for VPN server"

  # Allow SSH access
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.allowed_ssh_cidr_blocks
    description = "SSH access"
  }

  # Allow VPN traffic (WireGuard default port)
  ingress {
    from_port   = 51820
    to_port     = 51820
    protocol    = "udp"
    cidr_blocks = var.allowed_vpn_cidr_blocks
    description = "WireGuard VPN"
  }

  # Allow all outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "All outbound traffic"
  }

  tags = {
    Name = "vpn-server-sg"
  }
}

# Create EC2 instance for the VPN server
resource "aws_instance" "vpn_server" {
  ami                         = data.aws_ami.amazon_linux_2.id
  instance_type               = var.instance_type
  key_name                    = var.key_name
  vpc_security_group_ids      = [aws_security_group.vpn_server_sg.id]
  subnet_id                   = var.create_vpc ? aws_subnet.vpn_subnet[0].id : var.subnet_id
  associate_public_ip_address = true
  iam_instance_profile        = aws_iam_instance_profile.vpn_server_profile.name

  tags = {
    Name = "vpn-server"
  }

  # User data script to install and configure WireGuard
  user_data = base64encode(templatefile("${path.module}/templates/user-data.sh.tmpl", {
    vpn_ca_cert = file(var.vpn_ca_cert_path)
    vpn_ca_key  = file(var.vpn_ca_key_path)
  }))
}

# Find the latest Amazon Linux 2 AMI
data "aws_ami" "amazon_linux_2" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# Get current AWS account ID
data "aws_caller_identity" "current" {}

# Create IAM Roles Anywhere trust anchor
resource "aws_rolesanywhere_trust_anchor" "vpn_ca" {
  count = var.create_trust_anchor ? 1 : 0
  name  = "vpn-ca-trust-anchor"

  source {
    source_data {
      x509_certificate_data = file(var.vpn_ca_cert_path)
    }
    source_type = "CERTIFICATE_BUNDLE"
  }
}

# Create IAM Roles Anywhere profile
resource "aws_rolesanywhere_profile" "vpn_server" {
  name      = "vpn-server-profile"
  role_arns = [aws_iam_role.vpn_server_role.arn]
}