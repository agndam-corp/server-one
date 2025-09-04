# Nginx Ingress Controller

This chart deploys the Nginx Ingress Controller to the cluster using the official Helm chart as a dependency.

## Dependencies

- ingress-nginx 4.11.3 from https://kubernetes.github.io/ingress-nginx

## Configuration

The nginx ingress controller can be configured through the `ingress-nginx` section in values.yaml.

See `values-reference.yaml` for all available options.