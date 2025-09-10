#!/bin/bash

# Script to generate Spaceship.com API credentials secret

# Check if kubectl is available
if ! command -v kubectl &> /dev/null
then
    echo "kubectl could not be found. Please install kubectl first."
    exit 1
fi

# Check if secrets directory exists, create if not
SECRETS_DIR="/home/ubuntu/project/tools/cert-manager-webhook-spaceship/secrets"
mkdir -p $SECRETS_DIR

# Prompt for API credentials
echo "Please enter your Spaceship.com API credentials:"
read -p "API Key: " API_KEY
read -p "API Secret: " -s API_SECRET
echo

# Create the secret and save to file
echo "Generating Kubernetes secret for Spaceship API credentials..."
kubectl create secret generic spaceship-api-key \
  --from-literal=api-key="$API_KEY" \
  --from-literal=api-secret="$API_SECRET" \
  -n cert-manager \
  --dry-run=client \
  -o yaml > $SECRETS_DIR/spaceship-api-secret.yaml

echo "Secret saved to $SECRETS_DIR/spaceship-api-secret.yaml"
echo "To apply the secret to your cluster, run:"
echo "kubectl apply -f $SECRETS_DIR/spaceship-api-secret.yaml"