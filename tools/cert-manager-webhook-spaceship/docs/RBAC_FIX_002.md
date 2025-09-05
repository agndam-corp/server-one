# cert-manager Webhook for Spaceship DNS - Additional RBAC Fix

## Problem

After deploying the cert-manager webhook for Spaceship DNS, the webhook pod was showing errors in its logs:

```
subjectaccessreviews.authorization.k8s.io is forbidden: User "system:serviceaccount:cert-manager:cert-manager-webhook-spaceship" cannot create resource "subjectaccessreviews" in API group "authorization.k8s.io" at the cluster scope

prioritylevelconfigurations.flowcontrol.apiserver.k8s.io is forbidden: User "system:serviceaccount:cert-manager:cert-manager-webhook-spaceship" cannot list resource "prioritylevelconfigurations" in API group "flowcontrol.apiserver.k8s.io" at the cluster scope
```

## Root Cause

The webhook service account did not have the necessary permissions to create SubjectAccessReviews and access flow control resources.

## Solution

Added ClusterRole and ClusterRoleBinding to grant the webhook service account permissions to create SubjectAccessReviews and access flow control resources:

```yaml
# Grant permissions to webhook service account to create SubjectAccessReviews
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: {{ include "cert-manager-webhook-spaceship.fullname" . }}:webhook-access
rules:
  - apiGroups:
      - "authorization.k8s.io"
    resources:
      - "subjectaccessreviews"
    verbs:
      - "create"
  - apiGroups:
      - "flowcontrol.apiserver.k8s.io"
    resources:
      - "prioritylevelconfigurations"
      - "flowschemas"
    verbs:
      - "list"
      - "watch"
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: {{ include "cert-manager-webhook-spaceship.fullname" . }}:webhook-access
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: {{ include "cert-manager-webhook-spaceship.fullname" . }}:webhook-access
subjects:
  - apiGroup: ""
    kind: ServiceAccount
    name: {{ include "cert-manager-webhook-spaceship.fullname" . }}
    namespace: {{ .Release.Namespace }}
```

## Verification

After applying this fix, sync the ArgoCD application to redeploy the webhook with the updated RBAC permissions. The webhook pod should no longer show these permission errors.