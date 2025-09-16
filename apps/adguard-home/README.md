# AdGuard Home

This directory contains the Kustomize manifests for deploying AdGuard Home to the Kubernetes cluster.

## Overview

AdGuard Home is a network-wide software for blocking ads and tracking. It operates as a DNS server that blocks unwanted requests when your device attempts to connect to a server or domain that serves ads, tracking scripts, and malware.

## Components

- **Deployment**: Runs the AdGuard Home container with emptyDir storage for configuration and data
- **Service**: Exposes AdGuard Home HTTP and DNS ports within the cluster
- **Ingress**: Configures Traefik to route external traffic to AdGuard Home
- **ConfigMap**: Contains the initial AdGuard Home configuration (for reference only)
- **Certificate**: TLS certificate for secure access via HTTPS
- **CronJob**: Periodically backs up AdGuard Home configuration via API
- **Job**: Manually triggered job to apply configuration via API
- **Scripts ConfigMap**: Contains backup and apply scripts

## Configuration

The application is configured through:
- Initial configuration in `configmap.yaml` (used for reference only)
- Web UI for runtime configuration
- API for programmatic configuration management

## Access

AdGuard Home is accessible at:
- Web interface: https://dns-adg.djasko.com
- DNS server: dns-adg.djasko.com (port 53)

## Configuration Management

Since AdGuard Home modifies its configuration at runtime, we use an API-based approach for configuration management:

1. **Initial Setup**: AdGuard Home starts with default configuration
2. **Runtime Configuration**: Configure through the web UI
3. **Backup**: The CronJob (`backup-cronjob.yaml`) runs daily to backup the current configuration via API
4. **Apply Configuration**: The Job (`apply-config-job.yaml`) can be manually triggered to apply configuration via API

To manually trigger the configuration apply job:
```bash
kubectl create job --from=cronjob/adguard-home-apply-config adguard-home-apply-config-manual-$(date +%s)
```

## Updating Initial Configuration

To update the initial AdGuard Home configuration:
1. Modify the `configmap.yaml` file (for reference)
2. Commit and push changes to Git
3. ArgoCD will automatically sync the changes to the cluster

Note: Changes to the ConfigMap will not automatically apply to running instances. Use the web UI or API for runtime configuration changes.