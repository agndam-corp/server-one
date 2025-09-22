# ArgoCD Applications

This directory contains the ArgoCD Application manifests for deploying applications to the Kubernetes cluster.

## Applications

- `adguard-home_adguard-home.yaml` - AdGuard Home DNS ad-blocker with DNS over HTTPS and DNS over TLS support
- `cert-manager_cert-manager.yaml` - Certificate management with Let's Encrypt and Spaceship DNS webhook
- `cluster-sealed-secrets.yaml` - Sealed Secrets controller
- `spaceship-webhook.yaml` - Custom webhook for Spaceship DNS provider

## Structure

Each application manifest follows the ArgoCD Application CRD format and specifies:
- Source repository and path
- Destination namespace
- Sync policy
- Project

## DNS Services

The cluster provides secure DNS services through AdGuard Home:
- DNS over HTTPS (DoH) at `dns-adg.djasko.com`
- DNS over TLS (DoT) at `dns-adg.djasko.com`
- Web UI at `dns-adg-ui.djasko.com`

All services are secured with Let's Encrypt certificates managed by cert-manager.

## Adding New Applications

To add a new application:
1. Create an Application manifest in this directory
2. Define the source, destination, and sync policy
3. Commit and push to Git
4. ArgoCD will automatically detect and deploy the new application

## Troubleshooting Applications

### Common Issues

1. **Application Sync Failures**:
   - Check application status: `kubectl get applications -n argocd`
   - Review sync details: `kubectl describe application <name> -n argocd`
   - Check ArgoCD logs: `kubectl logs -n argocd -l app.kubernetes.io/name=argocd-application-controller`

2. **Resource Health Issues**:
   - Verify resource status in target namespace
   - Check pod logs: `kubectl logs -n <namespace> <pod-name>`
   - Review events: `kubectl get events -n <namespace>`