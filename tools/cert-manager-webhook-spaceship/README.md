# cert-manager-webhook-spaceship

This is a custom webhook for cert-manager that handles DNS challenges for spaceship.com domains.

## Building and Pushing to GHCR

### Prerequisites
1. Create a GitHub Personal Access Token (PAT) with `write:packages` scope
2. Authenticate with GHCR:
   ```bash
   echo YOUR_PAT | docker login ghcr.io -u YOUR_GITHUB_USERNAME --password-stdin
   ```

### Building and Pushing
```bash
# Build and push to GHCR
make release-ghcr

# Or build and push with a specific tag
IMAGE_TAG=v1.0.0 make release-ghcr
```

### Deploying
The webhook is deployed via ArgoCD using the Helm chart in `deploy/cert-manager-webhook-spaceship/`.
The image is configured to pull from GHCR in `values.yaml`.

## Development
```bash
# Run tests
make test

# Build locally
make build
```