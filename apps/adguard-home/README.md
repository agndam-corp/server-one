# AdGuard Home

This directory contains the Kustomize manifests for deploying AdGuard Home to the Kubernetes cluster.

## Overview

AdGuard Home is a network-wide software for blocking ads and tracking. It operates as a DNS server that blocks unwanted requests when your device attempts to connect to a server or domain that serves ads, tracking scripts, and malware.

## Components

- **Deployment**: Runs the AdGuard Home container with emptyDir storage for configuration and data
- **Service**: Exposes AdGuard Home HTTP and DNS ports within the cluster
- **Ingress**: Configures Traefik to route external traffic to AdGuard Home
- **Certificate**: TLS certificate for secure access via HTTPS
- **CronJob**: Periodically backs up AdGuard Home configuration via API to git
- **Job**: Manually triggered job to apply configuration via API from git
- **Scripts ConfigMap**: Contains backup and apply scripts
- **Backup File**: `configmap.backup` - File that stores the current configuration in git

## Configuration

The application is configured through:
- Web UI for runtime configuration
- API for programmatic configuration management
- Git for persistent configuration storage

## Access

AdGuard Home is accessible at:
- Web interface: https://dns-adg.djasko.com
- DNS server: dns-adg.djasko.com (port 53)

## Configuration Management

Since AdGuard Home modifies its configuration at runtime, we use a GitOps approach for configuration management:

1. **Initial Setup**: AdGuard Home starts with default configuration
2. **Runtime Configuration**: Configure through the web UI
3. **Backup**: The CronJob (`backup-cronjob.yaml`) runs daily to:
   - Get the current configuration via API
   - Update `configmap.backup` with the current configuration
   - Commit and push changes to git
4. **Apply Configuration**: The Job (`apply-config-job.yaml`) can be manually triggered to:
   - Get the configuration from `configmap.backup` in git
   - Apply it via the AdGuard Home API

To manually trigger the configuration apply job:
```bash
kubectl create job --from=job/adguard-home-apply-config adguard-home-apply-config-manual-$(date +%s) -n adguard-home
```

## Required Configuration

Before deploying, you need to update the scripts with your specific configuration:

1. Update the `GIT_REPO` variable in `scripts-configmap.yaml` with your git repository URL
2. Update the `GIT_USERNAME` and `GIT_EMAIL` variables in `scripts-configmap.yaml` with your git credentials
3. Update the `CONFIG_FILE_PATH` variable if you want to store the configuration in a different location
4. Generate a git token with appropriate permissions and add it using the `generate-sealed-secrets.sh` script

Note: The initial configuration is managed entirely through the web UI or API. The `configmap.yaml` file has been removed as it had no value in the current setup.