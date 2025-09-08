# cert-manager Webhook for Spaceship DNS - Deployment Checklist

## Pre-Deployment Checklist

### 1. Environment Preparation
- [ ] Kubernetes cluster v1.33+ available and accessible
- [ ] cert-manager v1.15.3+ installed and running
- [ ] ArgoCD installed and configured
- [ ] Spaceship DNS account with API access
- [ ] Domain managed by Spaceship DNS

### 2. Code Preparation
- [ ] Latest code pulled from repository
- [ ] Dependencies updated (`go mod tidy`)
- [ ] Docker image built with correct Go version (1.22+)
- [ ] Docker image pushed to registry

### 3. Configuration
- [ ] `values.yaml` updated with correct image repository
- [ ] Spaceship API key and secret prepared
- [ ] Domain verification (ensure domain is managed by Spaceship DNS)

## Deployment Steps

### 1. Create API Secret
```bash
kubectl create secret generic spaceship-api-key \
  --from-literal=api-key='YOUR_SPACESHIP_API_KEY' \
  --from-literal=api-secret='YOUR_SPACESHIP_API_SECRET' \
  --namespace=cert-manager
```

### 2. Deploy via ArgoCD
- [ ] Sync `cert-manager-webhook-spaceship` application in ArgoCD
- [ ] Verify webhook pod is running: `kubectl get pods -n cert-manager -l app=cert-manager-webhook-spaceship`
- [ ] Verify APIService is available: `kubectl get apiservice v1alpha1.acme.spaceship.com`

### 3. Create ClusterIssuer
```bash
kubectl apply -f apps/cert-manager/spaceship-webhook/clusterissuer.yaml
kubectl get clusterissuer letsencrypt-production-spaceship
```

### 4. Request Test Certificate
```bash
kubectl apply -f apps/cert-manager/spaceship-webhook/certificate.yaml
```

## Post-Deployment Verification

### 1. Component Status
- [ ] Webhook pod: `Running` with `READY 1/1`
- [ ] APIService: `AVAILABLE True`
- [ ] ClusterIssuer: `READY True`
- [ ] Certificate: `READY True`

### 2. Logs Check
- [ ] Webhook logs: No errors (`kubectl logs -n cert-manager -l app=cert-manager-webhook-spaceship`)
- [ ] cert-manager logs: No RBAC errors (`kubectl logs -n cert-manager -l app=cert-manager`)

### 3. Certificate Verification
```bash
kubectl get certificate -n argocd argocd-djasko-com
kubectl describe certificate -n argocd argocd-djasko-com
```

## Troubleshooting Quick Reference

### Common Issues
1. **APIService Shows "Local"**: Check versionPriority (should be 15) and port (should be 443)
2. **RBAC Errors**: Verify ClusterRole and ClusterRoleBinding for both cert-manager and webhook
3. **Authentication Failures**: Check API key/secret in Kubernetes secret
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

## Success Criteria

✅ All checklist items completed
✅ Certificate shows as `READY True`
✅ No errors in logs
✅ Certificate can be used by applications (e.g., Ingress, ArgoCD)

## Notes

- Deployment time: ~5-10 minutes
- First certificate issuance: ~2-5 minutes
- Certificate renewal: Automatic via cert-manager
- Monitor for 24 hours after deployment to ensure stability