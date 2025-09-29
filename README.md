# Kubernetes Server Setup

This repository contains the configuration and deployment files for a Kubernetes server setup using K3s, ArgoCD, and various applications.

## Overview

This project implements a comprehensive infrastructure for hosting web applications with integrated AWS EC2 instance management. The system provides:

- Secure user authentication and authorization
- Role-based access control (admin/users)
- AWS EC2 instance lifecycle management (start/stop/status)
- Multi-region AWS support
- Database-backed instance configuration storage
- RESTful API with Swagger documentation
- Containerized deployment via Kubernetes

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
- AdGuard Home DNS ad-blocker with GitOps configuration management
- And any other applications defined in the `argocd/prd/applications/` directory

## Directory Structure

- `apps/` - Application manifests (Helm charts and Kustomize)
  - `adguard-home/` - AdGuard Home DNS ad-blocker with GitOps configuration management
  - `cert-manager/` - Certificate management with Let's Encrypt
- `argocd/` - ArgoCD configuration and applications
  - `prd/applications/` - ArgoCD Application manifests for each deployed service
- `namespaces/` - Kubernetes namespace definitions
- `scripts/` - Utility scripts
- `sealed-secrets/` - Sealed secrets for sensitive data
- `terraform/` - Terraform configuration for infrastructure
- `tools/` - Custom tools and utilities

## DNS Configuration

The setup includes a complete DNS solution with AdGuard Home providing:
- DNS over HTTPS (DoH) at `dns-adg.djasko.com`
- DNS over TLS (DoT) at `dns-adg.djasko.com`
- Web UI at `dns-adg-ui.djasko.com`

All DNS services are secured with Let's Encrypt certificates managed by cert-manager.

## AWS Instance Management

This project includes a comprehensive AWS EC2 instance management system with the following features:

### Key Features
- **Multi-region Support**: Manage EC2 instances across multiple AWS regions
- **Database-backed Configuration**: Instance configurations stored in MariaDB
- **Role-based Access Control**: Separate permissions for regular users and administrators
- **RESTful API**: Clean API endpoints for all instance operations
- **Swagger Documentation**: Interactive API documentation at `/swagger/index.html`

### API Endpoints

#### Instance Operations (User)
- `GET /instances` - List all instances owned by the current user
- `GET /instances/:id` - Get details of a specific instance
- `POST /instances` - Create a new instance configuration
- `PUT /instances/:id` - Update an existing instance configuration
- `DELETE /instances/:id` - Delete an instance configuration

#### Instance Actions
- `POST /start` - Start an EC2 instance (requires instanceId and region)
- `POST /stop` - Stop an EC2 instance (requires instanceId and region)
- `GET /status` - Get the status of an EC2 instance (requires instanceId and region as query parameters)

#### Admin Operations
- `POST /admin/instances` - Admin endpoint to create instances for any user
- `PUT /admin/instances/:id` - Admin endpoint to update any instance
- `DELETE /admin/instances/:id` - Admin endpoint to delete any instance

### Database Schema

Instances are stored in the `aws_instances` table with the following fields:
- `id` - Unique identifier
- `name` - Human-readable name for the instance
- `instance_id` - AWS EC2 instance ID
- `region` - AWS region where the instance is located
- `description` - Description of the instance
- `status` - Current status (managed in the application)
- `created_by` - User ID of the owner
- `created_at` - Timestamp when the record was created
- `updated_at` - Timestamp when the record was last updated

### Sample Data Initialization

To initialize sample instances for testing, use the script:
```bash
cd project/scripts
./init-sample-instances.sh
```

This will create sample VPN server instances in different AWS regions.

## Security Notes

- All sensitive data is stored as sealed secrets and can be safely committed to the repository
- The sealed secrets controller key is backed up in the private directory for disaster recovery
- ArgoCD admin password is deployed via Terraform to break the chicken-and-egg problem
- All other sealed secrets are deployed via ArgoCD for proper GitOps workflow
- Never commit unencrypted secrets to the repository
- Regularly rotate credentials and update sealed secrets
- Use role-based access control (RBAC) to limit access to secrets
- AdGuard Home configuration is managed through GitOps with automated backups to git

## Troubleshooting

### Common Issues

1. **DNS Resolution Issues**: 
   - Verify that the Traefik service is properly configured with the required ports
   - Check that the IngressRouteTCP resources are correctly routing traffic
   - Ensure that certificates are properly issued and mounted

2. **Certificate Issues**:
   - Check cert-manager logs: `kubectl logs -n cert-manager -l app=cert-manager`
   - Verify certificate status: `kubectl get certificates -A`
   - Check for certificate issuance errors: `kubectl describe certificate <name> -n <namespace>`

3. **AdGuard Home Configuration**:
   - Check AdGuard Home pod logs: `kubectl logs -n adguard-home -l app=adguard-home`
   - Verify TLS configuration: `kubectl exec -it <adguard-pod> -n adguard-home -- curl http://localhost:80/control/tls/status`
   - Check backup job status: `kubectl get jobs -n adguard-home`

4. **Traefik Configuration**:
   - Verify Traefik deployment: `kubectl get deployment traefik -n kube-system`
   - Check Traefik logs: `kubectl logs -n kube-system -l app.kubernetes.io/name=traefik`
   - Ensure Traefik service exposes required ports: `kubectl get svc traefik -n kube-system`