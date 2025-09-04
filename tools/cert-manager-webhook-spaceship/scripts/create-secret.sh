#!/bin/bash

# Script to create Spaceship.com API credentials secret

# Check if kubectl is available
if ! command -v kubectl &> /dev/null
then
    echo "kubectl could not be found. Please install kubectl first."
    exit 1
fi

# Check if namespace exists, create if not
NAMESPACE="cert-manager"
if ! kubectl get namespace $NAMESPACE &> /dev/null
then
    echo "Creating namespace $NAMESPACE"
    kubectl create namespace $NAMESPACE
fi

# Prompt for API credentials
echo "Please enter your Spaceship.com API credentials:"
read -p "API Key: " API_KEY
read -p "API Secret: " -s API_SECRET
echo

# Create the secret
echo "Creating secret with API credentials..."
kubectl create secret generic spaceship-api-credentials \
  --from-literal=api-key="$API_KEY" \
  --from-literal=api-secret="$API_SECRET" \
  -n $NAMESPACE

echo "Secret 'spaceship-api-credentials' created successfully in namespace '$NAMESPACE'"

# Verify the secret was created
echo "Verifying secret..."
if kubectl get secret spaceship-api-credentials -n $NAMESPACE &> /dev/null
then
    echo "Secret verified successfully!"
else
    echo "Failed to verify secret. Please check if it was created correctly."
    exit 1
fi