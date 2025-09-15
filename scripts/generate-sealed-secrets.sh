#!/bin/bash

# Script to generate sealed secrets for sensitive data

# Check if kubeseal is available
if ! command -v kubeseal &> /dev/null
then
    echo "kubeseal could not be found. Please install kubeseal first."
    exit 1
fi

# Create temporary directory for secrets
TEMP_DIR="/tmp/sealed-secrets-$(date +%s)"
mkdir -p $TEMP_DIR

# Prompt for sensitive data
echo "=== Sealed Secrets Generator ==="
echo

# ArgoCD Admin Password
echo "Enter ArgoCD Admin Password:"
read -s ARGOCD_PASSWORD
echo

# Spaceship API Key and Secret
echo "Enter Spaceship API Key:"
read SPACESHIP_API_KEY
echo "Enter Spaceship API Secret:"
read -s SPACESHIP_API_SECRET
echo

# GHCR Credentials
echo "Enter GHCR Username (GitHub username):"
read GHCR_USERNAME
echo "Enter GHCR Personal Access Token:"
read -s GHCR_TOKEN
echo

# Create Kubernetes secrets in temporary directory
echo "Creating Kubernetes secrets..."

# ArgoCD Admin Password Secret
kubectl create secret generic argocd-admin-password \
  --from-literal=password="$ARGOCD_PASSWORD" \
  --namespace argocd \
  --dry-run=client \
  -o yaml > $TEMP_DIR/argocd-admin-password.yaml

# Spaceship API Credentials Secret
kubectl create secret generic spaceship-api-key \
  --from-literal=api-key="$SPACESHIP_API_KEY" \
  --from-literal=api-secret="$SPACESHIP_API_SECRET" \
  --namespace cert-manager \
  --dry-run=client \
  -o yaml > $TEMP_DIR/spaceship-api-key.yaml

# GHCR Image Pull Secret
kubectl create secret docker-registry ghcr-secret \
  --docker-server=ghcr.io \
  --docker-username="$GHCR_USERNAME" \
  --docker-password="$GHCR_TOKEN" \
  --docker-email=noreply@github.com \
  --namespace cert-manager \
  --dry-run=client \
  -o yaml > $TEMP_DIR/ghcr-secret.yaml

# Seal the secrets
echo "Sealing secrets..."

# ArgoCD Admin Password SealedSecret
kubeseal --controller-name sealed-secrets --controller-namespace kube-system < $TEMP_DIR/argocd-admin-password.yaml > /home/ubuntu/project/sealed-secrets/argocd-admin-password-sealed.yaml

# Spaceship API Credentials SealedSecret
kubeseal --controller-name sealed-secrets --controller-namespace kube-system < $TEMP_DIR/spaceship-api-key.yaml > /home/ubuntu/project/sealed-secrets/spaceship-api-key-sealed.yaml

# GHCR Image Pull SealedSecret
kubeseal --controller-name sealed-secrets --controller-namespace kube-system < $TEMP_DIR/ghcr-secret.yaml > /home/ubuntu/project/sealed-secrets/ghcr-secret-sealed.yaml

# Clean up temporary files
rm -rf $TEMP_DIR

echo "Sealed secrets created successfully!"
echo "Files saved to /home/ubuntu/project/sealed-secrets/"
echo
echo "To apply the sealed secrets to your cluster, run:"
echo "kubectl apply -f /home/ubuntu/project/sealed-secrets/"