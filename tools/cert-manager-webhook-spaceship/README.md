# Spaceship DNS Webhook for cert-manager

This webhook allows cert-manager to automate the DNS01 challenge for Let's Encrypt certificates using Spaceship DNS as the DNS provider.

## Prerequisites

- Kubernetes cluster with cert-manager installed (v1.12+)
- Spaceship DNS account with API access

## Installation

### 1. Build and Push the Webhook Image

```bash
# Build the Docker image
cd tools/cert-manager-webhook-spaceship
make build

# Push to your registry
docker tag cert-manager-webhook-spaceship:latest your-registry/cert-manager-webhook-spaceship:latest
docker push your-registry/cert-manager-webhook-spaceship:latest
```

### 2. Update Image Repository

Update the image repository in `deploy/cert-manager-webhook-spaceship/values.yaml` to point to your registry.

### 3. Deploy via ArgoCD

The webhook is deployed via ArgoCD as part of the app-of-apps pattern. The application manifest is located at `argocd/prd/applications/spaceship-webhook.yaml`.

To deploy, simply sync the `cert-manager-webhook-spaceship` application in ArgoCD.

If you need to make changes to the deployment, update the application manifest in `argocd/prd/applications/spaceship-webhook.yaml`.

### 4. Configure Spaceship API Access

Create a Kubernetes secret containing your Spaceship API key:

```bash
kubectl create secret generic spaceship-api-key \
  --from-literal=api-key='YOUR_SPACESHIP_API_KEY' \
  --namespace=cert-manager
```

### 5. Create a ClusterIssuer

Apply the ClusterIssuer configuration:

```bash
kubectl apply -f apps/cert-manager/spaceship-webhook/clusterissuer.yaml
```

## Troubleshooting

If you encounter issues:

1. Check the webhook pod logs:
   ```bash
   kubectl logs -n cert-manager -l app=cert-manager-webhook-spaceship
   ```

2. Verify the secret exists:
   ```bash
   kubectl get secret spaceship-api-key -n cert-manager
   ```

3. Check the certificate status:
   ```bash
   kubectl describe certificate argocd-djasko-com -n argocd
   ```

4. If you see RBAC errors, ensure the webhook has the necessary permissions to access configmaps in the kube-system namespace.

## Usage

### Request a Certificate

To request a certificate for `argocd.djasko.com`, apply the certificate configuration:

```bash
kubectl apply -f apps/cert-manager/spaceship-webhook/certificate.yaml
```

This will create a certificate for `argocd.djasko.com` in the `argocd` namespace.

## How It Works

The webhook implements the cert-manager DNS01 challenge solver interface to create and delete TXT records in Spaceship DNS for ACME DNS01 challenges.

When a certificate is requested, cert-manager will call the webhook to:

1. Create a TXT record with the challenge token in your Spaceship DNS zone
2. Wait for the certificate to be issued
3. Delete the TXT record after the challenge is complete

## API Documentation

The webhook uses the Spaceship DNS API:

- Create records: `POST /v1/dns/records/{domain}`
- Delete records: `DELETE /v1/dns/records/{domain}/{name}/{type}`

## Troubleshooting

If you encounter issues:

1. Check the webhook pod logs:
   ```bash
   kubectl logs -n cert-manager -l app=cert-manager-webhook-spaceship
   ```

2. Verify the secret exists:
   ```bash
   kubectl get secret spaceship-api-key -n cert-manager
   ```

3. Check the certificate status:
   ```bash
   kubectl describe certificate argocd-djasko-com -n argocd
   ```