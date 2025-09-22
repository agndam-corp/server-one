# Cert Manager Chart

This chart deploys cert-manager to the cluster using the official Helm chart as a dependency.

## Dependencies

- cert-manager v1.15.3 from https://charts.jetstack.io

## Configuration

The cert-manager can be configured through the `cert-manager` section in values.yaml.

## Certificates

This deployment manages the following certificates:
- ArgoCD certificate for argocd.djasko.com
- AdGuard Home certificate for dns-adg.djasko.com
- AdGuard Home UI certificate for dns-adg-ui.djasko.com

## DNS Providers

The cert-manager is configured with a custom webhook for Spaceship DNS provider, enabling automated Let's Encrypt certificate issuance for domains managed by Spaceship DNS.

## Troubleshooting

### Common Issues

1. **Certificate Not Ready**:
   - Check cert-manager logs: `kubectl logs -n cert-manager -l app=cert-manager`
   - Verify ClusterIssuer status: `kubectl get clusterissuer`
   - Check certificate request status: `kubectl get certificaterequest -n <namespace>`

2. **DNS Challenge Failures**:
   - Verify Spaceship API credentials in sealed secrets
   - Check webhook pod status: `kubectl get pods -n cert-manager`
   - Review webhook logs: `kubectl logs -n cert-manager -l app=cert-manager-webhook-spaceship`

3. **Certificate Renewal Issues**:
   - Check certificate expiration: `kubectl get certificate <name> -n <namespace> -o jsonpath='{.status.notAfter}'`
   - Monitor renewal events: `kubectl describe certificate <name> -n <namespace>`