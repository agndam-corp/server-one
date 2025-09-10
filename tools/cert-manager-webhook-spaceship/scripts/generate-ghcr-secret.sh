#!/bin/bash

# Script to generate GHCR image pull secret for cert-manager-webhook-spaceship

# Check if kubectl is available
if ! command -v kubectl &> /dev/null
then
    echo "kubectl could not be found. Please install kubectl first."
    exit 1
fi

# Prompt for GHCR credentials
echo "Please enter your GHCR credentials:"
read -p "GitHub Username: " GITHUB_USERNAME
read -p "GitHub Personal Access Token: " -s GITHUB_TOKEN
echo

# Create the secret and save to file
echo "Generating Kubernetes secret for GHCR authentication..."
kubectl create secret docker-registry ghcr-secret \
  --docker-server=ghcr.io \
  --docker-username=$GITHUB_USERNAME \
  --docker-password=$GITHUB_TOKEN \
  --docker-email=noreply@github.com \
  -n cert-manager \
  --dry-run=client \
  -o yaml > /home/ubuntu/project/tools/cert-manager-webhook-spaceship/secrets/ghcr-secret.yaml

echo "Secret saved to /home/ubuntu/project/tools/cert-manager-webhook-spaceship/secrets/ghcr-secret.yaml"
echo "To apply the secret to your cluster, run:"
echo "kubectl apply -f /home/ubuntu/project/tools/cert-manager-webhook-spaceship/secrets/ghcr-secret.yaml"