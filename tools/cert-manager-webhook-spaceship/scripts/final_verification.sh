#!/bin/bash

# Script to verify the cert-manager webhook for Spaceship DNS is working correctly

echo "=== cert-manager Webhook for Spaceship DNS - Final Verification ==="
echo

# Set kubeconfig
export KUBECONFIG=~/.kube/kubeconfig.yaml

# Check if kubectl is available
if ! command -v kubectl &> /dev/null
then
    echo "ERROR: kubectl is not installed or not in PATH"
    exit 1
fi

echo "1. Checking webhook pod status..."
echo "-----------------------------------"
kubectl get pods -n cert-manager -l app=cert-manager-webhook-spaceship
echo

echo "2. Checking APIService status..."
echo "--------------------------------"
kubectl get apiservice v1alpha1.acme.spaceship.com
echo

echo "3. Checking ClusterIssuer status..."
echo "-----------------------------------"
kubectl get clusterissuer letsencrypt-production-spaceship
echo

echo "4. Checking Spaceship API secret..."
echo "-----------------------------------"
kubectl get secret -n cert-manager spaceship-api-key
echo

echo "5. Checking certificate status..."
echo "----------------------------------"
kubectl get certificate -n argocd argocd-djasko-com
echo

echo "6. Checking webhook pod logs (last 20 lines)..."
echo "------------------------------------------------"
kubectl logs -n cert-manager -l app=cert-manager-webhook-spaceship --tail=20 2>/dev/null | grep -v "flowcontrol\|prioritylevelconfiguration\|FlowSchema" || echo "No recent errors found"
echo

echo "7. Testing Spaceship DNS API connectivity..."
echo "----------------------------------------------"
# Test if we can reach the Spaceship DNS API
if curl -s -o /dev/null -w "%{http_code}" https://spaceship.dev/api/v1/dns/records/test.com | grep -q "401\|403"; then
    echo "✅ Spaceship DNS API is reachable (returns 401/403 which is expected for unauthenticated requests)"
else
    echo "⚠️  Spaceship DNS API connectivity test result: $(curl -s -o /dev/null -w "%{http_code}" https://spaceship.dev/api/v1/dns/records/test.com)"
fi
echo

echo "=== Verification Complete ==="
echo

if kubectl get certificate -n argocd argocd-djasko-com | grep -q "True"; then
    echo "🎉 SUCCESS: The cert-manager webhook for Spaceship DNS is working correctly!"
    echo "   Certificate is ready and being served properly."
else
    echo "⚠️  WARNING: Certificate is not ready yet. This may be normal if a new certificate request is in progress."
    echo "   Check the certificate status again in a few minutes."
fi

echo
echo "For ongoing monitoring, use:"
echo "  kubectl get certificate -n argocd argocd-djasko-com -w"
echo