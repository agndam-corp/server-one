# AdGuard Home

This directory contains the Kustomize manifests for deploying AdGuard Home to the Kubernetes cluster.

## Overview

AdGuard Home is a network-wide software for blocking ads and tracking. It operates as a DNS server that blocks unwanted requests when your device attempts to connect to a server or domain that serves ads, tracking scripts, and malware.

## Components

- **Deployment**: Runs the AdGuard Home container with the specified configuration
- **Service**: Exposes AdGuard Home HTTP and DNS ports within the cluster
- **Ingress**: Configures Traefik to route external traffic to AdGuard Home
- **ConfigMap**: Contains the initial AdGuard Home configuration
- **Certificate**: TLS certificate for secure access via HTTPS

## Configuration

The application is configured through:
- `configmap.yaml` - Initial AdGuard Home configuration
- `deployment.yaml` - Container image and resource settings
- `service.yaml` - Service configuration
- `ingress.yaml` - Traefik ingress configuration
- Certificate in `apps/cert-manager/prd/templates/adguard-home-certificate.yaml`

## Access

AdGuard Home is accessible at:
- Web interface: https://dns-adg.djasko.com
- DNS server: dns-adg.djasko.com (port 53)

## Updating Configuration

To update the AdGuard Home configuration:
1. Modify the `configmap.yaml` file
2. Commit and push changes to Git
3. ArgoCD will automatically sync the changes to the cluster

Note: Changes made through the web interface are not persisted. To make persistent changes, update the ConfigMap and redeploy.