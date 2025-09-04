#!/bin/bash

# Build and deploy the cert-manager webhook for Spaceship.com

# Set variables
IMAGE_NAME="damianjaskolski95/cert-manager-webhook-spaceship"
IMAGE_TAG="latest"
NAMESPACE="cert-manager"

# Check if docker is available
if ! command -v docker &> /dev/null
then
    echo "Docker could not be found. Please install Docker first."
    exit 1
fi

# Check if kubectl is available
if ! command -v kubectl &> /dev/null
then
    echo "kubectl could not be found. Please install kubectl first."
    exit 1
fi

# Build the Docker image
echo "Building Docker image..."
docker build -t ${IMAGE_NAME}:${IMAGE_TAG} .

# Push the Docker image (you'll need to be logged in to Docker Hub)
echo "Pushing Docker image..."
docker push ${IMAGE_NAME}:${IMAGE_TAG}

# Deploy to Kubernetes
echo "Deploying to Kubernetes..."
kubectl apply -f deploy/webhook.yaml

# Wait for deployment to be ready
echo "Waiting for deployment to be ready..."
kubectl rollout status deployment/cert-manager-webhook-spaceship -n ${NAMESPACE}

echo "Webhook deployment completed!"