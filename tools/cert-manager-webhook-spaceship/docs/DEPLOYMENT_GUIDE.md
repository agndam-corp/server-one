# cert-manager Webhook for Spaceship DNS - Deployment Guide

## Overview

This guide provides detailed instructions for deploying the cert-manager webhook for Spaceship DNS. The webhook enables automatic DNS01 challenge resolution for Let's Encrypt certificates using Spaceship DNS as the DNS provider.

## Prerequisites

Before deploying the webhook, ensure you have:

1. A Kubernetes cluster (v1.20+)
2. cert-manager installed (v1.12+)
3. ArgoCD installed (for GitOps deployment)
4. A Spaceship DNS account with API access
5. A domain managed by Spaceship DNS

## Architecture

The webhook consists of the following components:

1. **Webhook Service**: A Kubernetes service that exposes the webhook API
2. **Webhook Pod**: A pod running the webhook application
3. **APIService**: Registers the webhook as an extension API with Kubernetes
4. **Custom Resource Definitions**: Defines the custom API resources used by the webhook
5. **RBAC Resources**: Grants necessary permissions to the webhook and cert-manager

## Deployment Steps

### 1. Prepare Spaceship API Credentials

Create a Spaceship API key and secret through the Spaceship dashboard.

### 2. Create Kubernetes Secret

Store the Spaceship API credentials as a Kubernetes secret:

```bash
kubectl create secret generic spaceship-api-key \
  --from-literal=api-key='YOUR_SPACESHIP_API_KEY' \
  --from-literal=api-secret='YOUR_SPACESHIP_API_SECRET' \
  --namespace=cert-manager
```

### 3. Configure ArgoCD Application

The webhook is deployed via ArgoCD as part of the app-of-apps pattern. The application manifest is located at `argocd/prd/applications/spaceship-webhook.yaml`.

Example application manifest:

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: cert-manager-webhook-spaceship
  namespace: argocd
spec:
  project: default
  source:
    repoURL: https://github.com/your-org/your-repo.git
    targetRevision: HEAD
    path: tools/cert-manager-webhook-spaceship/deploy/cert-manager-webhook-spaceship
    helm:
      valueFiles:
      - values.yaml
      parameters:
      - name: image.repository
        value: your-registry/cert-manager-webhook-spaceship
      - name: image.tag
        value: latest
  destination:
    server: https://kubernetes.default.svc
    namespace: cert-manager
  syncPolicy:
    automated:
      selfHeal: true
      prune: true
    syncOptions:
    - CreateNamespace=true
```

### 4. Deploy via ArgoCD

Sync the `cert-manager-webhook-spaceship` application in ArgoCD:

```bash
kubectl apply -f argocd/prd/applications/spaceship-webhook.yaml
argocd app sync cert-manager-webhook-spaceship
```

### 5. Verify Deployment

Check that all components are running:

```bash
# Check webhook pod
kubectl get pods -n cert-manager -l app=cert-manager-webhook-spaceship

# Check webhook service
kubectl get service -n cert-manager cert-manager-webhook-spaceship

# Check APIService
kubectl get apiservice v1alpha1.acme.spaceship.com

# Check webhook logs
kubectl logs -n cert-manager -l app=cert-manager-webhook-spaceship
```

## Configuration

### Values.yaml

The webhook can be configured through `values.yaml`:

```yaml
# Default values for cert-manager-webhook-spaceship.
# This is a YAML-formatted file.
# Declare variables to be passed into your templates.

replicaCount: 1

image:
  repository: cert-manager-webhook-spaceship
  tag: latest
  pullPolicy: Never

nameOverride: ""
fullnameOverride: ""

service:
  type: ClusterIP
  port: 443

resources: {}
  # We usually recommend not to specify default resources and to leave this as a conscious
  # choice for the user. This also increases chances charts run on environments with little
  # resources, such as Minikube. If you do want to specify resources, uncomment the following
  # lines, adjust them as necessary, and remove the curly braces after 'resources:'.
  # limits:
  #   cpu: 100m
  #   memory: 128Mi
  # requests:
  #   cpu: 100m
  #   memory: 128Mi

nodeSelector: {}

tolerations: []

affinity: {}

certManager:
  namespace: cert-manager
  serviceAccountName: cert-manager

webhook:
  groupName: acme.spaceship.com
```

### ClusterIssuer Configuration

Create a ClusterIssuer to use the webhook:

```yaml
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: letsencrypt-production-spaceship
spec:
  acme:
    server: https://acme-v02.api.letsencrypt.org/directory
    email: your-email@example.com
    privateKeySecretRef:
      name: letsencrypt-production-spaceship
    solvers:
    - dns01:
        webhook:
          groupName: acme.spaceship.com
          solverName: spaceship
          config:
            baseUrl: https://spaceship.dev/api
            apiKeyRef:
              name: spaceship-api-key
              key: api-key
            apiSecretRef:
              name: spaceship-api-key
              key: api-secret
```

Apply the ClusterIssuer:

```bash
kubectl apply -f apps/cert-manager/spaceship-webhook/clusterissuer.yaml
```

### Certificate Request

Request a certificate:

```yaml
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: example-com
  namespace: default
spec:
  secretName: example-com-tls
  issuerRef:
    name: letsencrypt-production-spaceship
    kind: ClusterIssuer
  dnsNames:
  - example.com
  - www.example.com
```

Apply the certificate:

```bash
kubectl apply -f apps/cert-manager/spaceship-webhook/certificate.yaml
```

## Validation

### Check Webhook Health

```bash
# Check webhook pod status
kubectl get pods -n cert-manager -l app=cert-manager-webhook-spaceship

# Check webhook service
kubectl get service -n cert-manager cert-manager-webhook-spaceship

# Check APIService
kubectl get apiservice v1alpha1.acme.spaceship.com

# Check webhook logs
kubectl logs -n cert-manager -l app=cert-manager-webhook-spaceship
```

### Test Certificate Issuance

Request a test certificate:

```bash
kubectl apply -f - <<EOF
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: test-cert
  namespace: default
spec:
  secretName: test-cert-tls
  issuerRef:
    name: letsencrypt-production-spaceship
    kind: ClusterIssuer
  dnsNames:
  - test.yourdomain.com
EOF
```

Monitor the certificate status:

```bash
kubectl get certificate test-cert -w
```

### Verify Certificate

Once issued, verify the certificate:

```bash
# Check certificate details
kubectl describe certificate test-cert

# Check the TLS secret
kubectl get secret test-cert-tls -o yaml

# Decode the certificate
kubectl get secret test-cert-tls -o jsonpath='{.data.tls\.crt}' | base64 --decode | openssl x509 -text -noout
```

## Troubleshooting

Refer to the [Troubleshooting Guide](TROUBLESHOOTING_GUIDE.md) for common issues and solutions.

## Upgrade

To upgrade the webhook:

1. Build and push a new image with the updated version
2. Update the image tag in the ArgoCD application
3. Sync the application in ArgoCD

```bash
# Build new image
cd tools/cert-manager-webhook-spaceship
make build

# Tag and push
docker tag cert-manager-webhook-spaceship:latest your-registry/cert-manager-webhook-spaceship:v1.2.0
docker push your-registry/cert-manager-webhook-spaceship:v1.2.0

# Update ArgoCD application with new tag
# Sync the application
argocd app sync cert-manager-webhook-spaceship
```

## Monitoring

### Logs

Monitor the webhook logs for issues:

```bash
kubectl logs -n cert-manager -l app=cert-manager-webhook-spaceship -f
```

### Metrics

The webhook exposes Prometheus metrics on port 8080 at `/metrics`.

### Events

Monitor Kubernetes events for certificate-related activities:

```bash
kubectl get events -n cert-manager --watch
kubectl get events -n default --watch
```

## Security Considerations

### API Credentials

1. Store Spaceship API credentials as Kubernetes secrets
2. Use RBAC to restrict access to the secrets
3. Rotate API credentials regularly

### Network Security

1. The webhook service listens on port 443 with TLS encryption
2. Communication between cert-manager and the webhook is encrypted
3. The webhook validates all incoming requests

### RBAC

The webhook follows the principle of least privilege:

1. The webhook service account has only the permissions it needs
2. cert-manager has only the permissions it needs to interact with the webhook
3. Access to secrets is restricted to authorized components

## Backup and Recovery

### Backup

Backup the webhook deployment and associated resources:

```bash
# Backup the webhook deployment
kubectl get deployment -n cert-manager cert-manager-webhook-spaceship -o yaml > backup-webhook-deployment.yaml

# Backup the APIService
kubectl get apiservice v1alpha1.acme.spaceship.com -o yaml > backup-apiservice.yaml

# Backup RBAC resources
kubectl get clusterrole,clusterrolebinding -l app=cert-manager-webhook-spaceship -o yaml > backup-rbac.yaml
```

### Recovery

Restore from backups if needed:

```bash
# Restore the webhook deployment
kubectl apply -f backup-webhook-deployment.yaml

# Restore the APIService
kubectl apply -f backup-apiservice.yaml

# Restore RBAC resources
kubectl apply -f backup-rbac.yaml
```