# Sealed Secrets

This directory contains sealed secrets for sensitive data in the cluster.

## What are Sealed Secrets?

Sealed Secrets is a Kubernetes controller and tool for one-way encrypted Secrets. It allows you to store encrypted secrets in Git and have them automatically decrypted in the cluster.

## How to Use

1. **Generate sealed secrets**:
   Run the script to generate sealed secrets:
   ```bash
   ./scripts/generate-sealed-secrets.sh
   ```

2. **Apply sealed secrets**:
   Apply the sealed secrets to your cluster:
   ```bash
   kubectl apply -f sealed-secrets/
   ```

## Current Sealed Secrets

- `argocd-admin-password-sealed.yaml` - ArgoCD admin password
- `spaceship-api-key-sealed.yaml` - Spaceship API credentials
- `ghcr-secret-sealed.yaml` - GHCR image pull secret
- `adguard-home-git-token-sealed.yaml` - AdGuard Home Git repository credentials
- `adguard-home-admin-password-sealed.yaml` - AdGuard Home admin password

## Adding New Sealed Secrets

To add new sealed secrets:

1. Create a regular Kubernetes secret:
   ```bash
   kubectl create secret generic my-secret \
     --from-literal=key=value \
     --namespace my-namespace \
     --dry-run=client \
     -o yaml > my-secret.yaml
   ```

2. Seal the secret (make sure to specify the controller name and namespace):
   ```bash
   kubeseal --controller-name sealed-secrets --controller-namespace kube-system < my-secret.yaml > my-secret-sealed.yaml
   ```

3. Add the sealed secret to this directory and commit it to Git.

## Security Notes

- The sealed secrets can only be decrypted by the Sealed Secrets controller in the cluster where they were created
- The encryption is one-way - you cannot retrieve the original secret from the sealed secret
- Store the sealed secrets in Git - they are safe to share publicly
- Never store unencrypted secrets in Git
- The sealed secrets controller key is backed up in the private directory for disaster recovery

## Troubleshooting

### Common Issues

1. **Sealed Secret Decryption Failures**:
   - Verify the sealed secrets controller is running: `kubectl get pods -n kube-system -l name=sealed-secrets-controller`
   - Check controller logs: `kubectl logs -n kube-system -l name=sealed-secrets-controller`
   - Ensure the sealed secret was created for the correct cluster and namespace

2. **Secret Not Available**:
   - Verify the sealed secret was applied: `kubectl get sealedsecret -n <namespace>`
   - Check if the secret was created: `kubectl get secret -n <namespace>`
   - Review events: `kubectl describe sealedsecret <name> -n <namespace>`