# cert-manager-webhook-spaceship

A cert-manager webhook solver for Spaceship.com DNS provider.

## Overview

This project implements a cert-manager webhook that allows automated DNS01 challenges with Spaceship.com's DNS service. It enables fully automated certificate issuance and renewal for domains managed by Spaceship.com.

## Prerequisites

- Kubernetes cluster with cert-manager installed
- Spaceship.com API credentials
- Docker for building the webhook image
- kubectl for deploying to Kubernetes

## Installation

### 1. Build and Deploy the Webhook

```bash
# Clone the repository
git clone <repository-url>
cd tools/cert-manager-webhook-spaceship

# Build the Docker image
make build

# Push the Docker image to a registry (you'll need to be logged in)
make push

# Deploy to Kubernetes
make deploy
```

### 2. Create Spaceship.com API Key Secret

Create a secret containing your Spaceship.com API key:

```bash
# Create the secret (replace with your actual API key)
kubectl create secret generic spaceship-api-key \
  --from-literal=api-key='YOUR_SPACESHIP_API_KEY' \
  -n cert-manager
```

### 3. Configure ClusterIssuer

Update your ClusterIssuer to use the Spaceship.com webhook:

```yaml
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: letsencrypt-prod
spec:
  acme:
    server: https://acme-v02.api.letsencrypt.org/directory
    email: your-email@example.com
    privateKeySecretRef:
      name: letsencrypt-prod
    solvers:
    - dns01:
        webhook:
          groupName: acme.spaceship.com
          solverName: spaceship
          config:
            apiKeySecretRef:
              name: spaceship-api-key
              key: api-key
```

Apply the configuration:
```bash
kubectl apply -f deploy/cluster-issuer.yaml
```

## Configuration

The webhook requires the following configuration:
- Spaceship.com API key stored in a Kubernetes secret
- Proper RBAC permissions for the webhook service account
- Correct groupName and solverName in the ClusterIssuer configuration

## Development

This webhook is built using the cert-manager webhook example as a base:
https://github.com/cert-manager/webhook-example

### Implementing Spaceship.com API Integration

To complete the webhook implementation, you'll need to:

1. Obtain API documentation from Spaceship.com
2. Implement the `createTXTRecord` and `deleteTXTRecord` methods in `main.go`
3. Handle authentication with the Spaceship.com API
4. Parse domain names correctly to identify the root domain and subdomain
5. Test the implementation thoroughly

### Testing

Run unit tests:
```bash
make test
```

## Contributing

Contributions are welcome! Please feel free to submit issues and pull requests.

1. Fork the repository
2. Create a feature branch
3. Commit your changes
4. Push to the branch
5. Create a pull request

## License

This project is licensed under the MIT License - see the LICENSE file for details.