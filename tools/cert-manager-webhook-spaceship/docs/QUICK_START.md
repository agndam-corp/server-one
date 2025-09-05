# cert-manager Webhook for Spaceship DNS - Quick Start Guide

## Overview

This guide provides a quick start for deploying the cert-manager webhook for Spaceship DNS to automate Let's Encrypt certificate issuance for domains managed by Spaceship DNS.

## Prerequisites

1. Kubernetes cluster with cert-manager installed
2. Spaceship DNS account with API access
3. Domain managed by Spaceship DNS

## Quick Deployment

### 1. Clone the Repository

```bash
git clone https://github.com/your-org/your-repo.git
cd your-repo
```

### 2. Create Spaceship API Secret

```bash
kubectl create secret generic spaceship-api-key \
  --from-literal=api-key='YOUR_SPACESHIP_API_KEY' \
  --from-literal=api-secret='YOUR_SPACESHIP_API_SECRET' \
  --namespace=cert-manager
```

### 3. Deploy the Webhook

```bash
# Build and push the webhook image
cd tools/cert-manager-webhook-spaceship
make build
docker tag cert-manager-webhook-spaceship:latest your-registry/cert-manager-webhook-spaceship:latest
docker push your-registry/cert-manager-webhook-spaceship:latest

# Deploy via ArgoCD (recommended)
kubectl apply -f argocd/prd/applications/spaceship-webhook.yaml
argocd app sync cert-manager-webhook-spaceship
```

### 4. Create ClusterIssuer

```bash
kubectl apply -f apps/cert-manager/spaceship-webhook/clusterissuer.yaml
```

### 5. Request a Certificate

```bash
kubectl apply -f apps/cert-manager/spaceship-webhook/certificate.yaml
```

## Verify Installation

### Check Components

```bash
# Check webhook pod
kubectl get pods -n cert-manager -l app=cert-manager-webhook-spaceship

# Check APIService
kubectl get apiservice v1alpha1.acme.spaceship.com

# Check ClusterIssuer
kubectl get clusterissuer letsencrypt-production-spaceship

# Check Certificate
kubectl get certificate -n argocd argocd-djasko-com
```

### Monitor Logs

```bash
# Webhook logs
kubectl logs -n cert-manager -l app=cert-manager-webhook-spaceship -f

# Certificate events
kubectl get events -n argocd --watch
```

## Configuration

### Custom Image Registry

Update `argocd/prd/applications/spaceship-webhook.yaml` to use your image registry:

```yaml
spec:
  source:
    helm:
      parameters:
      - name: image.repository
        value: your-registry/cert-manager-webhook-spaceship
      - name: image.tag
        value: latest
```

### Custom Domain

Update `apps/cert-manager/spaceship-webhook/certificate.yaml` for your domain:

```yaml
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: your-domain-com
  namespace: your-namespace
spec:
  secretName: your-domain-com-tls
  issuerRef:
    name: letsencrypt-production-spaceship
    kind: ClusterIssuer
  dnsNames:
  - your-domain.com
  - www.your-domain.com
```

## Troubleshooting

### Common Issues

1. **Certificate Not Ready**: Check webhook logs for authentication errors
2. **401 Unauthorized**: Verify Spaceship API key and secret
3. **422 Unprocessable Entity**: Check request format
4. **APIService Shows "Local"**: Apply APIService fix

### Quick Checks

```bash
# Verify secret exists
kubectl get secret -n cert-manager spaceship-api-key

# Check webhook logs
kubectl logs -n cert-manager -l app=cert-manager-webhook-spaceship

# Describe certificate
kubectl describe certificate -n argocd argocd-djasko-com

# Describe challenge
kubectl describe challenge -n argocd argocd-djasko-com-1-2053381265-2073290511
```

## Next Steps

1. Review the [Deployment Guide](DEPLOYMENT_GUIDE.md) for detailed configuration options
2. Check the [Troubleshooting Guide](TROUBLESHOOTING_GUIDE.md) for common issues
3. Explore the [API Documentation](../README.md#api-documentation) for advanced usage

## Support

For issues, please check:

1. [GitHub Issues](https://github.com/your-org/your-repo/issues)
2. [Troubleshooting Guide](TROUBLESHOOTING_GUIDE.md)
3. Webhook logs: `kubectl logs -n cert-manager -l app=cert-manager-webhook-spaceship`