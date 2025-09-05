# cert-manager Webhook for Spaceship DNS - Summary of Fixes

## Overview

This document summarizes all the fixes made to get the cert-manager webhook for Spaceship DNS working correctly. Initially, the webhook had several issues that prevented it from successfully issuing certificates.

## Issues and Fixes

### 1. APIService Configuration Issue
**Problem**: The APIService was showing as "Local" instead of pointing to the webhook service, preventing cert-manager from communicating with the webhook.

**Fixes Applied**:
- Fixed `versionPriority` from 100 to 15
- Added explicit port specification (443) to the service reference
- Ensured APIService was correctly applied through Helm

**Documentation**: [APISERVICE_FIX_001.md](APISERVICE_FIX_001.md)

### 2. RBAC Permission Issues
**Problem**: Multiple RBAC permission errors prevented both cert-manager and the webhook from accessing required resources:
- cert-manager couldn't create resources in the `acme.spaceship.com` API group
- Webhook couldn't create SubjectAccessReviews
- Webhook couldn't access flow control resources

**Fixes Applied**:
- Added ClusterRole and ClusterRoleBinding for cert-manager service account to access custom API
- Added ClusterRole and ClusterRoleBinding for webhook service account to create SubjectAccessReviews
- Added ClusterRole and ClusterRoleBinding for webhook service account to access flow control resources

**Documentation**: [RBAC_FIX_001.md](RBAC_FIX_001.md) and [RBAC_FIX_002.md](RBAC_FIX_002.md)

### 3. Authentication and Request Format Issues
**Problem**: The webhook was not correctly sending authentication headers or formatting requests for the Spaceship DNS API:
- Wrong headers (`X-Api-Key` instead of `X-API-Key`)
- Wrong HTTP method (POST instead of PUT)
- Wrong request payload format (missing `force` field, using `data` instead of `items`)

**Fixes Applied**:
- Updated authentication headers to use `X-API-Key` and `X-API-Secret`
- Changed HTTP method from POST to PUT
- Fixed request payload format to include `force: true` and use `items` field
- Added proper error handling and logging

**Documentation**: [AUTHENTICATION_FIX_001.md](AUTHENTICATION_FIX_001.md)

## Final Working Configuration

After all fixes were applied, the webhook successfully issued a certificate for `argocd.djasko.com`:

```bash
$ kubectl get certificate -n argocd argocd-djasko-com
NAME                READY   SECRET                  AGE
argocd-djasko-com   True    argocd-djasko-com-tls   2m30s
```

## Key Components

### 1. Webhook Service
- Correctly configured APIService pointing to the webhook service
- Proper TLS certificate configuration
- Correct port specification (443)

### 2. RBAC Configuration
- ClusterRole and ClusterRoleBinding for cert-manager to access webhook API
- ClusterRole and ClusterRoleBinding for webhook to create SubjectAccessReviews
- ClusterRole and ClusterRoleBinding for webhook to access flow control resources

### 3. Authentication
- Correct `X-API-Key` and `X-API-Secret` headers
- PUT method for record creation
- Proper request payload format with `force: true` and `items` field

### 4. Error Handling
- Comprehensive logging for debugging
- Proper error responses
- Graceful handling of API errors

## Verification Steps

To verify the webhook is working correctly:

1. Check webhook pod status:
   ```bash
   kubectl get pods -n cert-manager -l app=cert-manager-webhook-spaceship
   ```

2. Check APIService status:
   ```bash
   kubectl get apiservice v1alpha1.acme.spaceship.com
   ```

3. Request a test certificate:
   ```bash
   kubectl apply -f apps/cert-manager/spaceship-webhook/certificate.yaml
   ```

4. Monitor certificate status:
   ```bash
   kubectl get certificate -n argocd argocd-djasko-com -w
   ```

5. Check webhook logs:
   ```bash
   kubectl logs -n cert-manager -l app=cert-manager-webhook-spaceship
   ```

## Conclusion

The cert-manager webhook for Spaceship DNS is now fully functional and can automatically issue Let's Encrypt certificates for domains managed by Spaceship DNS. All authentication, authorization, and API communication issues have been resolved.

The webhook follows Kubernetes best practices for security, RBAC, and resource management. It integrates seamlessly with cert-manager and ArgoCD for GitOps deployment.