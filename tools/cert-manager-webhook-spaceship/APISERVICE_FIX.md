# cert-manager Webhook for Spaceship DNS - Fix for APIService Issue

## Problem

After deploying the cert-manager webhook for Spaceship DNS, the APIService was showing as "Local" instead of pointing to the webhook service. This prevented cert-manager from properly communicating with the webhook for DNS01 challenges.

## Root Cause

The issue was caused by two problems in the APIService configuration:

1. The `versionPriority` was incorrectly set to 100 instead of 15
2. The service reference was missing the port specification
3. The APIService was not being correctly applied through Helm

## Solution

### 1. Fixed the APIService Template

Updated `deploy/cert-manager-webhook-spaceship/templates/apiservice.yaml`:

```yaml
apiVersion: apiregistration.k8s.io/v1
kind: APIService
metadata:
  name: v1alpha1.{{ .Values.webhook.groupName }}
  labels:
    app: {{ include "cert-manager-webhook-spaceship.name" . }}
    chart: {{ include "cert-manager-webhook-spaceship.chart" . }}
    release: {{ .Release.Name }}
    heritage: {{ .Release.Service }}
  annotations:
    cert-manager.io/inject-ca-from: "{{ .Values.certManager.namespace }}/{{ include "cert-manager-webhook-spaceship.servingCertificate" . }}"
spec:
  group: {{ .Values.webhook.groupName }}
  groupPriorityMinimum: 1000
  versionPriority: 15  # Fixed: Changed from 100 to 15
  service:
    name: {{ include "cert-manager-webhook-spaceship.fullname" . }}
    namespace: {{ .Release.Namespace }}
    port: 443  # Fixed: Added explicit port
  version: v1alpha1
```

### 2. Manual Fix for Existing Deployments

If the APIService is already deployed incorrectly, apply the fix manually:

```bash
# Create a patch file
cat > apiservice-patch.json <<EOF
{
  "apiVersion": "apiregistration.k8s.io/v1",
  "kind": "APIService",
  "metadata": {
    "name": "v1alpha1.acme.spaceship.com"
  },
  "spec": {
    "group": "acme.spaceship.com",
    "groupPriorityMinimum": 1000,
    "versionPriority": 15,
    "service": {
      "name": "cert-manager-webhook-spaceship",
      "namespace": "cert-manager",
      "port": 443
    },
    "version": "v1alpha1"
  }
}
EOF

# Apply the patch
kubectl replace -f apiservice-patch.json
```

## Verification

After applying the fix, verify that the APIService is correctly configured:

```bash
# Check that the service reference is correct
kubectl get apiservice v1alpha1.acme.spaceship.com -o yaml

# Verify that the CA bundle is injected
kubectl get apiservice v1alpha1.acme.spaceship.com -o jsonpath='{.spec.caBundle}' | wc -c

# Check the status
kubectl get apiservice v1alpha1.acme.spaceship.com
```

The APIService should show:
- Service reference pointing to `cert-manager-webhook-spaceship` in `cert-manager` namespace
- Status as "Passed" instead of "Local"
- Non-empty CA bundle