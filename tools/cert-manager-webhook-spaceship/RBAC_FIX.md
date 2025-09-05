# cert-manager Webhook for Spaceship DNS - RBAC Fix

## Problem

After deploying the cert-manager webhook for Spaceship DNS, certificate issuance was failing with the following error:

```
spaceship.acme.spaceship.com is forbidden: User "system:serviceaccount:cert-manager:cert-manager" cannot create resource "spaceship" in API group "acme.spaceship.com" at the cluster scope
```

## Root Cause

The cert-manager service account did not have the necessary permissions to access the custom API group (`acme.spaceship.com`) provided by our webhook.

## Solution

Added ClusterRole and ClusterRoleBinding to grant the cert-manager service account permissions to access our custom API:

```yaml
# Grant permissions to cert-manager service account to access our custom API
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: {{ include "cert-manager-webhook-spaceship.fullname" . }}:cert-manager-access
rules:
  - apiGroups:
      - "acme.spaceship.com"
    resources:
      - "*"
    verbs:
      - "create"
      - "get"
      - "list"
      - "update"
      - "delete"
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: {{ include "cert-manager-webhook-spaceship.fullname" . }}:cert-manager-access
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: {{ include "cert-manager-webhook-spaceship.fullname" . }}:cert-manager-access
subjects:
  - apiGroup: ""
    kind: ServiceAccount
    name: {{ .Values.certManager.serviceAccountName }}
    namespace: {{ .Values.certManager.namespace }}
```

## Verification

After applying this fix, sync the ArgoCD application to redeploy the webhook with the updated RBAC permissions. The certificate issuance should then proceed successfully.