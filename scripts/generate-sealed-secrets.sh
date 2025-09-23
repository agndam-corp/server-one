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

# AdGuard Home Git Token
echo "Enter AdGuard Home Git Token (for configuration backup):"
read -s ADGUARD_GIT_TOKEN
echo

# AdGuard Home Admin Password (for API authentication)
echo "Enter AdGuard Home Admin Password (plain text for API authentication):"
read -s ADGUARD_ADMIN_PASSWORD
echo

# AdGuard Home Admin Password (bcrypt hash for config file - leave empty if you want to use the plain text password)
echo "Enter AdGuard Home Admin Password (bcrypt hash for config file - optional, leave empty to use plain text password):"
read -s ADGUARD_ADMIN_PASSWORD_HASH
echo

# AdGuard Home Git Repository
echo "Enter AdGuard Home Git Repository URL (e.g., https://github.com/username/repo.git):"
read ADGUARD_GIT_REPO
echo

# AdGuard Home Git User Email
echo "Enter AdGuard Home Git User Email (for commits):"
read ADGUARD_GIT_EMAIL
echo

# AdGuard Home Git Username
echo "Enter AdGuard Home Git Username (for authentication):"
read ADGUARD_GIT_USERNAME
echo

# CrowdSec Enrollment Key
echo "Enter CrowdSec Enrollment Key (leave empty to generate a random one):"
read CROWDSEC_ENROLL_KEY
echo

# CrowdSec Bouncer Key
echo "Enter CrowdSec Bouncer Key (leave empty to generate a random one):"
read CROWDSEC_BOUNCER_KEY
echo

# VPN CA Certificate and Key
echo "Enter path to VPN CA Certificate file:"
read VPN_CA_CERT_PATH
echo "Enter path to VPN CA Private Key file:"
read VPN_CA_KEY_PATH
echo

# Webapp Configuration
echo "Enter the VPN Instance ID:"
read VPN_INSTANCE_ID
echo "Enter Webapp Basic Auth Username:"
read WEBAPP_AUTH_USERNAME
echo "Enter Webapp Basic Auth Password:"
read -s WEBAPP_AUTH_PASSWORD
echo

# Create Kubernetes secrets in temporary directory
echo "Creating Kubernetes secrets..."

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

# GHCR Image Pull Secret for adguard-home namespace
kubectl create secret docker-registry ghcr-secret \
  --docker-server=ghcr.io \
  --docker-username="$GHCR_USERNAME" \
  --docker-password="$GHCR_TOKEN" \
  --docker-email=noreply@github.com \
  --namespace adguard-home \
  --dry-run=client \
  -o yaml > $TEMP_DIR/ghcr-secret-adguard-home.yaml

# GHCR Image Pull Secret for webapp namespace
kubectl create secret docker-registry ghcr-secret \
  --docker-server=ghcr.io \
  --docker-username="$GHCR_USERNAME" \
  --docker-password="$GHCR_TOKEN" \
  --docker-email=noreply@github.com \
  --namespace webapp \
  --dry-run=client \
  -o yaml > $TEMP_DIR/ghcr-secret-webapp.yaml

# AdGuard Home Git Token Secret
kubectl create secret generic adguard-home-git-token \
  --from-literal=token="$ADGUARD_GIT_TOKEN" \
  --from-literal=repo="$ADGUARD_GIT_REPO" \
  --from-literal=email="$ADGUARD_GIT_EMAIL" \
  --from-literal=username="$ADGUARD_GIT_USERNAME" \
  --namespace adguard-home \
  --dry-run=client \
  -o yaml > $TEMP_DIR/adguard-home-git-token.yaml

# AdGuard Home Admin Password Secret (for API authentication)
kubectl create secret generic adguard-home-admin-password \
  --from-literal=password="$ADGUARD_ADMIN_PASSWORD" \
  --namespace adguard-home \
  --dry-run=client \
  -o yaml > $TEMP_DIR/adguard-home-admin-password.yaml

# AdGuard Home Admin Password Hash Secret (for config file - optional)
if [ -n "$ADGUARD_ADMIN_PASSWORD_HASH" ]; then
  kubectl create secret generic adguard-home-admin-password-hash \
    --from-literal=password_hash="$ADGUARD_ADMIN_PASSWORD_HASH" \
    --namespace adguard-home \
    --dry-run=client \
    -o yaml > $TEMP_DIR/adguard-home-admin-password-hash.yaml
fi

# CrowdSec Secrets
# Generate random keys if not provided
if [ -z "$CROWDSEC_ENROLL_KEY" ]; then
  CROWDSEC_ENROLL_KEY=$(openssl rand -hex 32)
  echo "Generated CrowdSec Enrollment Key: $CROWDSEC_ENROLL_KEY"
fi

if [ -z "$CROWDSEC_BOUNCER_KEY" ]; then
  CROWDSEC_BOUNCER_KEY=$(openssl rand -hex 32)
  echo "Generated CrowdSec Bouncer Key: $CROWDSEC_BOUNCER_KEY"
fi

kubectl create secret generic crowdsec-secrets \
  --from-literal=enrollment-key="$CROWDSEC_ENROLL_KEY" \
  --from-literal=bouncer-key="$CROWDSEC_BOUNCER_KEY" \
  --namespace crowdsec \
  --dry-run=client \
  -o yaml > $TEMP_DIR/crowdsec-secrets.yaml

# Seal the secrets
echo "Sealing secrets..."

# Spaceship API Credentials SealedSecret
kubeseal --controller-name sealed-secrets --controller-namespace kube-system < $TEMP_DIR/spaceship-api-key.yaml > /home/ubuntu/project/sealed-secrets/prd/spaceship-api-key-sealed.yaml

# GHCR Image Pull SealedSecret
kubeseal --controller-name sealed-secrets --controller-namespace kube-system < $TEMP_DIR/ghcr-secret.yaml > /home/ubuntu/project/sealed-secrets/prd/ghcr-secret-sealed.yaml

# GHCR Image Pull SealedSecret for adguard-home namespace
kubeseal --controller-name sealed-secrets --controller-namespace kube-system < $TEMP_DIR/ghcr-secret-adguard-home.yaml > /home/ubuntu/project/sealed-secrets/prd/ghcr-secret-adguard-home-sealed.yaml

# GHCR Image Pull SealedSecret for webapp namespace
kubeseal --controller-name sealed-secrets --controller-namespace kube-system < $TEMP_DIR/ghcr-secret-webapp.yaml > /home/ubuntu/project/sealed-secrets/prd/ghcr-secret-webapp-sealed.yaml

# AdGuard Home Git Token SealedSecret
kubeseal --controller-name sealed-secrets --controller-namespace kube-system < $TEMP_DIR/adguard-home-git-token.yaml > /home/ubuntu/project/sealed-secrets/prd/adguard-home-git-token-sealed.yaml

# AdGuard Home Admin Password SealedSecret (for API authentication)
kubeseal --controller-name sealed-secrets --controller-namespace kube-system < $TEMP_DIR/adguard-home-admin-password.yaml > /home/ubuntu/project/sealed-secrets/prd/adguard-home-admin-password-sealed.yaml

# AdGuard Home Admin Password Hash SealedSecret (for config file - optional)
if [ -f $TEMP_DIR/adguard-home-admin-password-hash.yaml ]; then
  kubeseal --controller-name sealed-secrets --controller-namespace kube-system < $TEMP_DIR/adguard-home-admin-password-hash.yaml > /home/ubuntu/project/sealed-secrets/prd/adguard-home-admin-password-hash-sealed.yaml
fi

# CrowdSec SealedSecret
kubeseal --controller-name sealed-secrets --controller-namespace kube-system < $TEMP_DIR/crowdsec-secrets.yaml > /home/ubuntu/project/sealed-secrets/prd/crowdsec-secrets-sealed.yaml

# VPN CA Certificate and Key Secret
if [ -f "$VPN_CA_CERT_PATH" ] && [ -f "$VPN_CA_KEY_PATH" ]; then
  kubectl create secret generic vpn-ca-cert-key \
    --from-file=ca.crt=$VPN_CA_CERT_PATH \
    --from-file=ca.key=$VPN_CA_KEY_PATH \
    --namespace cert-manager \
    --dry-run=client \
    -o yaml > $TEMP_DIR/vpn-ca-cert-key.yaml

  # VPN CA Certificate and Key SealedSecret
  kubeseal --controller-name sealed-secrets --controller-namespace kube-system < $TEMP_DIR/vpn-ca-cert-key.yaml > /home/ubuntu/project/sealed-secrets/prd/vpn-ca-cert-key-sealed.yaml
else
  echo "Warning: VPN CA certificate or key file not found. Skipping VPN CA secret creation."
fi

# Webapp Configuration Secrets
kubectl create secret generic vpn-instance-config \\
  --from-literal=instanceId="$VPN_INSTANCE_ID" \\
  --namespace webapp \\
  --dry-run=client \\
  -o yaml > $TEMP_DIR/vpn-instance-config.yaml

kubectl create secret generic webapp-auth \\
  --from-literal=username="$WEBAPP_AUTH_USERNAME" \\
  --from-literal=password="$WEBAPP_AUTH_PASSWORD" \\
  --namespace webapp \\
  --dry-run=client \\
  -o yaml > $TEMP_DIR/webapp-auth.yaml

# Webapp Configuration SealedSecrets
kubeseal --controller-name sealed-secrets --controller-namespace kube-system < $TEMP_DIR/vpn-instance-config.yaml > /home/ubuntu/project/sealed-secrets/prd/vpn-instance-config-sealed.yaml
kubeseal --controller-name sealed-secrets --controller-namespace kube-system < $TEMP_DIR/webapp-auth.yaml > /home/ubuntu/project/sealed-secrets/prd/webapp-auth-sealed.yaml

# Clean up temporary files
rm -rf $TEMP_DIR

echo "Sealed secrets created successfully!"
echo "Files saved to /home/ubuntu/project/sealed-secrets/"
echo
echo "To apply the sealed secrets to your cluster, run:"
echo "kubectl apply -f /home/ubuntu/project/sealed-secrets/"
echo
echo "Please save these keys in a secure location."