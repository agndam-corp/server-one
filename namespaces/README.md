# Kubernetes Namespaces

This directory contains the namespace definitions for the Kubernetes cluster.

## Namespaces

- `adguard-home.yaml` - Namespace for the AdGuard Home DNS ad-blocker
- `argocd.yaml` - Namespace for the ArgoCD deployment
- `cert-manager.yaml` - Namespace for the cert-manager deployment
- `ingress-nginx.yaml` - Namespace for the NGINX ingress controller

## Structure

Each namespace file defines a Kubernetes Namespace resource with:
- Metadata including name
- Optional labels and annotations

## Adding New Namespaces

To add a new namespace:
1. Create a new YAML file in this directory with the namespace definition
2. Commit and push to Git
3. ArgoCD will automatically create the namespace in the cluster