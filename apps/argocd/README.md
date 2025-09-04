# ArgoCD Custom Configuration

This application provides custom configuration for ArgoCD, including SSL termination with Let's Encrypt certificates.

## Components

- Ingress resource for ArgoCD UI with SSL termination
- SSL passthrough to preserve end-to-end encryption

## Prerequisites

- Nginx ingress controller must be installed
- cert-manager must be installed with a working ClusterIssuer
- Certificate for argocd.djasko.com must be created

## Configuration

The ingress configuration is defined in the templates directory.