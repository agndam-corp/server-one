# Kubernetes Server Setup

This repository contains the configuration and deployment files for a Kubernetes server setup using K3s, ArgoCD, and various applications.

## Prerequisites

Before deploying, ensure you have the following tools installed:

1. **kubectl** - Kubernetes command-line tool
2. **helm** - Helm package manager for Kubernetes
3. **kubeseal** - Sealed Secrets CLI tool for encrypting secrets
4. **docker** - Docker for building and pushing container images
5. **terraform** - Terraform for implementing whole arch

## Setup Process

### 1. Initial Cluster Setup
The cluster is deployed using Terraform:
```bash
cd terraform
terraform init
terraform apply
```

This will:
- Install K3s cluster
- Deploy ArgoCD
- Deploy Sealed Secrets controller
- Deploy all applications via ArgoCD App of Apps pattern

### 2. Sealed Secrets Generation
Before deploying applications that require secrets, generate sealed secrets:

```bash
./scripts/generate-sealed-secrets.sh
```

This script will prompt for:
- ArgoCD Admin Password
- Spaceship API Key and Secret
- GHCR Username and Personal Access Token

The script will create sealed secrets for:
- ArgoCD admin password
- Spaceship API credentials
- GHCR image pull secret

### 3. Apply Sealed Secrets
After generating sealed secrets, apply them to the cluster:

```bash
kubectl apply -f sealed-secrets/
```

### 4. Application Deployment
Applications are automatically deployed by ArgoCD through the App of Apps pattern. The applications include:
- cert-manager with custom webhook for Spaceship DNS
- Sealed Secrets controller
- And any other applications defined in the `argocd/prd/applications/` directory

## Directory Structure

- `apps/` - Application Helm charts
- `argocd/` - ArgoCD configuration and applications
- `namespaces/` - Kubernetes namespace definitions
- `scripts/` - Utility scripts
- `sealed-secrets/` - Sealed secrets for sensitive data
- `terraform/` - Terraform configuration for infrastructure
- `tools/` - Custom tools and utilities

## Security Notes

- All sensitive data should be stored as sealed secrets
- Never commit unencrypted secrets to the repository
- Regularly rotate credentials and update sealed secrets
- Use role-based access control (RBAC) to limit access to secrets