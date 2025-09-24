# CrowdSec for AdGuard Home

This directory contains the configuration for deploying CrowdSec to monitor and protect your AdGuard Home DNS server.

## Overview

CrowdSec is a free, modern & collaborative behavior detection engine, coupled with a global IP reputation network. It detects peers on automated attacks and shares signals with the community.

This setup is specifically configured to:
1. Monitor Traefik access logs (since AdGuard Home doesn't see real client IPs due to Traefik proxying)
2. Detect suspicious DNS activities through Traefik
3. Automatically block malicious IPs

## Configuration

The values.yaml file is configured to:
- Collect logs from Traefik pods in the `kube-system` namespace
- Enable security scenarios from the CrowdSec hub
- Deploy custom scenarios for detecting DNS abuse and suspicious patterns
- Parse Traefik logs to extract real client IPs from forwarded headers
- Extract DNS query information from Traefik logs
- Deploy the Kubernetes bouncer for automatic IP blocking
- Reference Kubernetes secrets for sensitive credentials

## Deployment

This application is deployed via ArgoCD using the application manifest in `argocd/prd/applications/crowdsec.yaml`.

## Secrets Management

CrowdSec requires sensitive credentials:
- `ENROLL_KEY`: Used to enroll your CrowdSec instance with the central console
- `ENROLL_INSTANCE_NAME`: Instance name for enrollment
- `ENROLL_TAGS`: Tags for enrollment
- `BOUNCER_KEY_traefik`: Used for communication between the Local API and Traefik bouncer

These secrets are managed using Sealed Secrets:
1. Generate the secrets using the script: `/scripts/generate-sealed-secrets.sh`
2. Apply the sealed secrets: `kubectl apply -f /home/ubuntu/webapp/project/sealed-secrets/prd/crowdsec-secrets-sealed.yaml`

## Handling Traefik Proxy Issue

Since Traefik acts as a proxy, AdGuard Home doesn't see the real client IPs. To address this:

1. We collect logs directly from Traefik pods
2. CrowdSec is configured with a custom parser to extract the real client IP from Traefik's forwarded headers
3. We detect DNS queries by looking for requests to the AdGuard Home domain (`*.dns-adg.djasko.com`)

## Custom Scenarios

We've implemented two custom scenarios:
1. DNS abuse detection - detects when a single IP makes excessive DNS queries through Traefik
2. Suspicious pattern detection - detects queries for known malicious domains

## Customization

To customize the deployment:
1. Modify the values.yaml file
2. Update the ArgoCD application if needed
3. Sync the application in ArgoCD

## Testing

To test the setup:
1. Generate some DNS queries from a test client through Traefik
2. Check the CrowdSec dashboard to see if the queries are being logged
3. Generate some suspicious traffic to test the blocking mechanism