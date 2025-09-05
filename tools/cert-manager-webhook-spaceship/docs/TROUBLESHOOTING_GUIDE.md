# cert-manager Webhook for Spaceship DNS - Comprehensive Troubleshooting Guide

## Common Issues and Solutions

### 1. Certificate Not Ready

#### Symptom
```bash
kubectl get certificate -n argocd argocd-djasko-com
NAME                READY   SECRET                  AGE
argocd-djasko-com   False   argocd-djasko-com-tls   5m
```

#### Diagnosis
Check the certificate details:
```bash
kubectl describe certificate -n argocd argocd-djasko-com
```

Check the CertificateRequest:
```bash
kubectl get certificaterequest -n argocd
kubectl describe certificaterequest -n argocd argocd-djasko-com-1
```

Check the Order:
```bash
kubectl get order -n argocd
kubectl describe order -n argocd argocd-djasko-com-1-2053381265
```

Check the Challenge:
```bash
kubectl get challenge -n argocd
kubectl describe challenge -n argocd argocd-djasko-com-1-2053381265-2073290511
```

#### Solutions
1. Check webhook pod logs for errors:
   ```bash
   kubectl logs -n cert-manager -l app=cert-manager-webhook-spaceship
   ```

2. Verify the Spaceship API key secret exists:
   ```bash
   kubectl get secret -n cert-manager spaceship-api-key
   ```

3. Check if the API key and secret are correct by testing with curl:
   ```bash
   curl -X PUT \
     -H "X-API-Key: YOUR_API_KEY" \
     -H "X-API-Secret: YOUR_API_SECRET" \
     -H "Content-Type: application/json" \
     -d '{"force":true,"items":[{"name":"_acme-challenge.test","type":"TXT","value":"test","ttl":60}]}' \
     https://spaceship.dev/api/v1/dns/records/YOUR_DOMAIN
   ```

### 2. Challenge Fails with 401 Unauthorized

#### Symptom
Challenge events show:
```
Error presenting challenge: failed to create DNS record: unexpected status code: 401, body: {"detail":"Api key or secret not provided."}
```

#### Diagnosis
This indicates an authentication issue with the Spaceship API.

#### Solution
1. Verify the Spaceship API key secret contains both `api-key` and `api-secret`:
   ```bash
   kubectl get secret -n cert-manager spaceship-api-key -o yaml
   ```

2. Recreate the secret with correct values:
   ```bash
   kubectl delete secret -n cert-manager spaceship-api-key
   kubectl create secret generic spaceship-api-key \
     --from-literal=api-key='YOUR_API_KEY' \
     --from-literal=api-secret='YOUR_API_SECRET' \
     -n cert-manager
   ```

3. Restart the webhook pod:
   ```bash
   kubectl delete pod -n cert-manager -l app=cert-manager-webhook-spaceship
   ```

### 3. Challenge Fails with 422 Unprocessable Entity

#### Symptom
Challenge events show:
```
Error presenting challenge: failed to create DNS record: unexpected status code: 422, body: {"detail":"The request is invalid.","data":[{"field":"items","details":"The items field is required."}]}
```

#### Diagnosis
This indicates the request format is incorrect.

#### Solution
This should be fixed in the latest version of the webhook. Ensure you're using the latest image:

1. Check the webhook deployment:
   ```bash
   kubectl get deployment -n cert-manager cert-manager-webhook-spaceship -o yaml
   ```

2. If needed, update the image tag and redeploy.

### 4. Webhook Pod CrashLoopBackOff

#### Symptom
```bash
kubectl get pods -n cert-manager
NAME                                              READY   STATUS             RESTARTS   AGE
cert-manager-webhook-spaceship-57cc8b8c9d-xyz12   0/1     CrashLoopBackOff   5          10m
```

#### Diagnosis
Check the pod logs:
```bash
kubectl logs -n cert-manager cert-manager-webhook-spaceship-57cc8b8c9d-xyz12
```

#### Solutions
1. Check if the TLS certificate is correctly mounted:
   ```bash
   kubectl describe pod -n cert-manager cert-manager-webhook-spaceship-57cc8b8c9d-xyz12
   ```

2. Verify the certificate exists:
   ```bash
   kubectl get certificate -n cert-manager cert-manager-webhook-spaceship-webhook-tls
   ```

3. If the certificate is missing, check the cert-manager logs:
   ```bash
   kubectl logs -n cert-manager cert-manager-657b64db68-abc123
   ```

### 5. RBAC Permission Errors

#### Symptom
Webhook pod logs show:
```
spaceship.acme.spaceship.com is forbidden: User "system:serviceaccount:cert-manager:cert-manager" cannot create resource "spaceship" in API group "acme.spaceship.com" at the cluster scope
```

#### Diagnosis
The cert-manager service account lacks permissions to access the webhook's custom API.

#### Solution
This should be fixed by the RBAC fixes in the deployment. Ensure the ClusterIssuer is correctly configured and the ArgoCD application is synced.

### 6. APIService Shows as "Local"

#### Symptom
```bash
kubectl get apiservice v1alpha1.acme.spaceship.com
NAME                          SERVICE   AVAILABLE   AGE
v1alpha1.acme.spaceship.com   Local     True        10m
```

#### Diagnosis
The APIService is not correctly pointing to the webhook service.

#### Solution
Apply the APIService fix:
```bash
kubectl patch apiservice v1alpha1.acme.spaceship.com -p '{"spec":{"service":{"name":"cert-manager-webhook-spaceship","namespace":"cert-manager","port":443},"versionPriority":15}}' --type=merge
```

## Debugging Steps

### 1. Check All Components

```bash
# Check cert-manager components
kubectl get pods -n cert-manager

# Check the webhook service
kubectl get service -n cert-manager cert-manager-webhook-spaceship

# Check the webhook pod logs
kubectl logs -n cert-manager -l app=cert-manager-webhook-spaceship --tail=100

# Check the cert-manager logs
kubectl logs -n cert-manager -l app=cert-manager --tail=50
```

### 2. Test API Connectivity

```bash
# Test Spaceship API connectivity from the webhook pod
kubectl exec -n cert-manager -l app=cert-manager-webhook-spaceship -- curl -v https://spaceship.dev/api/v1/dns/records/test.com
```

### 3. Verify Certificate Issuance Flow

```bash
# Watch for certificate events
kubectl get events -n argocd --watch

# Describe the certificate
kubectl describe certificate -n argocd argocd-djasko-com

# Describe the order
kubectl describe order -n argocd argocd-djasko-com-1-2053381265

# Describe the challenge
kubectl describe challenge -n argocd argocd-djasko-com-1-2053381265-2073290511
```

## Useful Commands

### Check Certificate Status
```bash
kubectl get certificate -A
kubectl describe certificate -n argocd argocd-djasko-com
```

### Check Certificate Requests
```bash
kubectl get certificaterequest -A
kubectl describe certificaterequest -n argocd argocd-djasko-com-1
```

### Check Orders
```bash
kubectl get order -A
kubectl describe order -n argocd argocd-djasko-com-1-2053381265
```

### Check Challenges
```bash
kubectl get challenge -A
kubectl describe challenge -n argocd argocd-djasko-com-1-2053381265-2073290511
```

### Check Secrets
```bash
kubectl get secret -n cert-manager
kubectl get secret -n argocd argocd-djasko-com-tls -o yaml
```

### Restart Components
```bash
# Restart cert-manager
kubectl delete pod -n cert-manager -l app=cert-manager

# Restart webhook
kubectl delete pod -n cert-manager -l app=cert-manager-webhook-spaceship

# Restart cert-manager-webhook
kubectl delete pod -n cert-manager -l app=cert-manager-webhook
```

## Spaceship DNS API Testing

### Test Record Creation
```bash
curl -X PUT \
  -H "X-API-Key: YOUR_API_KEY" \
  -H "X-API-Secret: YOUR_API_SECRET" \
  -H "Content-Type: application/json" \
  -d '{"force":true,"items":[{"name":"_acme-challenge.test","type":"TXT","value":"test-value","ttl":60}]}' \
  https://spaceship.dev/api/v1/dns/records/YOUR_DOMAIN
```

### Test Record Deletion
```bash
curl -X PUT \
  -H "X-API-Key: YOUR_API_KEY" \
  -H "X-API-Secret: YOUR_API_SECRET" \
  -H "Content-Type: application/json" \
  -d '{"force":true,"items":[]}' \
  https://spaceship.dev/api/v1/dns/records/YOUR_DOMAIN
```