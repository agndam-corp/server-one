# Certificates Application

This application manages SSL certificates for various services using cert-manager.

## Certificates

- `argocd-djasko-com` - Certificate for ArgoCD UI (argocd.djasko.com)

## Prerequisites

- cert-manager must be installed and configured with a ClusterIssuer
- The domain must be pointing to the cluster's IP address

## Configuration

Certificates are defined in the templates directory as Kubernetes Certificate resources.