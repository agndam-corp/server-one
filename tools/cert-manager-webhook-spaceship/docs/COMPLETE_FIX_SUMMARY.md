# cert-manager Webhook for Spaceship DNS - Complete Fix Summary

## Overview

This document provides a comprehensive summary of all the fixes made to get the cert-manager webhook for Spaceship DNS working correctly. Initially, the webhook had several critical issues that prevented it from successfully issuing certificates.

## Issues Resolved

### 1. APIService Configuration Issue
**Problem**: The APIService was showing as "Local" instead of correctly pointing to the webhook service.

**Root Cause**: Incorrect `versionPriority` value and missing port specification in the APIService configuration.

**Fix**: 
- Changed `versionPriority` from 100 to 15
- Added explicit port 443 specification
- Ensured APIService was correctly applied through Helm

**Verification**: APIService now shows as "True" and available.

### 2. RBAC Permission Issues
**Problem**: Multiple RBAC permission errors prevented both cert-manager and the webhook from accessing required resources.

**Root Cause**: Missing permissions for cert-manager to access the webhook's custom API group and for the webhook to create SubjectAccessReviews.

**Fix**:
- Added ClusterRole and ClusterRoleBinding for cert-manager service account to access `acme.spaceship.com` API group
- Added ClusterRole and ClusterRoleBinding for webhook service account to create SubjectAccessReviews
- Removed problematic flowcontrol permissions that were causing errors in newer Kubernetes versions

**Verification**: No more RBAC permission errors in logs.

### 3. Authentication and Request Format Issues
**Problem**: The webhook was not correctly sending authentication headers or formatting requests for the Spaceship DNS API.

**Root Cause**: Incorrect headers, HTTP method, and request payload format.

**Fix**:
- Updated authentication headers to use `X-API-Key` and `X-API-Secret`
- Changed HTTP method from POST to PUT as required by Spaceship API
- Fixed request payload format to include `force: true` and use `items` field instead of `data`
- Added proper error handling and logging

**Verification**: Certificates are now successfully issued.

### 4. Kubernetes Version Compatibility Issues
**Problem**: Flowcontrol-related errors due to incompatible Kubernetes API versions.

**Root Cause**: Client-go library trying to access deprecated `flowcontrol.apiserver.k8s.io/v1beta3` API version.

**Fix**:
- Updated go.mod to match cert-manager v1.15.3 dependencies
- Upgraded Go version in Dockerfile from 1.21 to 1.22
- Removed deprecated flowcontrol RBAC permissions
- Updated all Kubernetes dependencies to compatible versions

**Verification**: No more flowcontrol errors in logs.

## Current Working Configuration

### Components Status
- ✅ Webhook pod running without errors
- ✅ APIService correctly registered and available
- ✅ RBAC permissions properly configured
- ✅ Authentication working with Spaceship DNS API
- ✅ Certificate issuance successful

### Verification Commands
```bash
# Check webhook pod status
kubectl get pods -n cert-manager -l app=cert-manager-webhook-spaceship

# Check APIService status
kubectl get apiservice v1alpha1.acme.spaceship.com

# Check certificate status
kubectl get certificate -n argocd argocd-djasko-com

# Check webhook logs (should be clean)
kubectl logs -n cert-manager -l app=cert-manager-webhook-spaceship
```

## Technical Details

### Authentication Flow
1. Webhook retrieves API key and secret from Kubernetes secret
2. Sends authenticated requests to Spaceship DNS API using `X-API-Key` and `X-API-Secret` headers
3. Uses PUT method with proper payload format including `force: true` and `items` field

### Request Format
```json
{
  "force": true,
  "items": [
    {
      "name": "_acme-challenge.argocd",
      "type": "TXT",
      "value": "challenge-token-value",
      "ttl": 60
    }
  ]
}
```

### API Endpoints
- Create records: `PUT /v1/dns/records/{domain}`
- Delete records: `PUT /v1/dns/records/{domain}` (with empty items array)

## Dependencies

### Compatible Versions
- cert-manager: v1.15.3
- Kubernetes client-go: v0.30.1
- Kubernetes cluster: v1.33.4+k3s1
- Go: 1.22

### Dependency Updates
The go.mod file was updated to ensure all dependencies are compatible with cert-manager v1.15.3 and Kubernetes v1.33.

## Deployment

### Image Building
```bash
cd tools/cert-manager-webhook-spaceship
make build
```

### ArgoCD Deployment
The webhook is deployed via ArgoCD as part of the app-of-apps pattern. After building and pushing the updated image, sync the application in ArgoCD.

### Configuration
The webhook requires a Kubernetes secret containing the Spaceship API key and secret:
```bash
kubectl create secret generic spaceship-api-key \
  --from-literal=api-key='YOUR_SPACESHIP_API_KEY' \
  --from-literal=api-secret='YOUR_SPACESHIP_API_SECRET' \
  --namespace=cert-manager
```

## Testing

### Certificate Request
To test the webhook, request a certificate:
```bash
kubectl apply -f apps/cert-manager/spaceship-webhook/certificate.yaml
```

### Verification
Monitor the certificate status:
```bash
kubectl get certificate -n argocd argocd-djasko-com -w
```

A successful certificate issuance will show:
```
NAME                READY   SECRET                  AGE
argocd-djasko-com   True    argocd-djasko-com-tls   50m
```

## Troubleshooting

### Common Issues
1. **APIService Shows as "Local"**: Check versionPriority and port specification
2. **RBAC Permission Errors**: Verify ClusterRole and ClusterRoleBinding configurations
3. **Authentication Failures**: Check API key and secret in Kubernetes secret
4. **Flowcontrol Errors**: Ensure Kubernetes version compatibility

### Diagnostic Commands
```bash
# Check all components
kubectl get pods,apiservice,clusterissuer,certificate -n cert-manager
kubectl get certificate -n argocd argocd-djasko-com

# Check logs
kubectl logs -n cert-manager -l app=cert-manager-webhook-spaceship
kubectl logs -n cert-manager -l app=cert-manager

# Describe resources
kubectl describe certificate -n argocd argocd-djasko-com
kubectl describe challenge -n argocd <challenge-name>
```

## Conclusion

The cert-manager webhook for Spaceship DNS is now fully functional and can successfully automate Let's Encrypt certificate issuance for domains managed by Spaceship DNS. All authentication, authorization, and API compatibility issues have been resolved.

The webhook follows Kubernetes best practices for security, RBAC, and resource management, and integrates seamlessly with cert-manager and ArgoCD for GitOps deployment.

Regular maintenance includes:
1. Keeping dependencies up to date
2. Rotating Spaceship API credentials
3. Monitoring certificate expiration and renewal
4. Verifying continued compatibility with Kubernetes upgrades