# Kubernetes Server Setup

This repository contains the configuration and deployment files for a Kubernetes server setup using K3s, ArgoCD, and various applications.

## Prerequisites

Before deploying, ensure you have the following tools installed:

1. **kubectl** - Kubernetes command-line tool
2. **helm** - Helm package manager for Kubernetes
3. **kubeseal** - Sealed Secrets CLI tool for encrypting secrets
4. **docker** - Docker for building and pushing container images
5. **terraform** - Terraform for infrastructure deployment

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
- Deploy Sealed Secrets controller (from backed up key if available)
- Deploy ArgoCD admin password sealed secret (to break the chicken-and-egg problem)
- Deploy ArgoCD

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

Note: The Sealed Secrets controller is deployed by Terraform, so make sure to run Terraform apply first.

### 3. Apply Sealed Secrets
After generating sealed secrets, apply them to the cluster:

```bash
kubectl apply -f sealed-secrets/
```

### 4. Automated Application Deployment
After applying sealed secrets, ArgoCD automatically deploys all applications through the App of Apps pattern:

**Phase 1 (Terraform Deployed)**:
- Sealed Secrets controller
- ArgoCD admin password sealed secret
- ArgoCD

**Phase 2 (ArgoCD Deployed)**:
- All other sealed secrets from the `sealed-secrets/` directory
- cert-manager with custom webhook for Spaceship DNS
- AdGuard Home DNS ad-blocker
- And any other applications defined in the `argocd/prd/applications/` directory

## Directory Structure

- `apps/` - Application manifests (Helm charts and Kustomize)
  - `adguard-home/` - AdGuard Home DNS ad-blocker
  - `cert-manager/` - Certificate management with Let's Encrypt
- `argocd/` - ArgoCD configuration and applications
  - `prd/applications/` - ArgoCD Application manifests for each deployed service
- `namespaces/` - Kubernetes namespace definitions
- `scripts/` - Utility scripts
- `sealed-secrets/` - Sealed secrets for sensitive data
- `terraform/` - Terraform configuration for infrastructure
- `tools/` - Custom tools and utilities

## Security Notes

- All sensitive data is stored as sealed secrets and can be safely committed to the repository
- The sealed secrets controller key is backed up in the private directory for disaster recovery
- ArgoCD admin password is deployed via Terraform to break the chicken-and-egg problem
- All other sealed secrets are deployed via ArgoCD for proper GitOps workflow
- Never commit unencrypted secrets to the repository
- Regularly rotate credentials and update sealed secrets
- Use role-based access control (RBAC) to limit access to secrets