# ArgoCD Applications

This directory contains the ArgoCD Application manifests for deploying applications to the Kubernetes cluster.

## Applications

- `adguard-home_adguard-home.yaml` - AdGuard Home DNS ad-blocker
- `cert-manager_cert-manager.yaml` - Certificate management with Let's Encrypt
- `cluster-sealed-secrets.yaml` - Sealed Secrets controller
- `spaceship-webhook.yaml` - Custom webhook for Spaceship DNS provider

## Structure

Each application manifest follows the ArgoCD Application CRD format and specifies:
- Source repository and path
- Destination namespace
- Sync policy
- Project

## Adding New Applications

To add a new application:
1. Create an Application manifest in this directory
2. Define the source, destination, and sync policy
3. Commit and push to Git
4. ArgoCD will automatically detect and deploy the new application