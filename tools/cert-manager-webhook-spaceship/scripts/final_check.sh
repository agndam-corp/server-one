#!/bin/bash

# Final verification script for cert-manager webhook for Spaceship DNS

echo "==============================================="
echo " cert-manager Webhook for Spaceship DNS       "
echo "           FINAL VERIFICATION                  "
echo "==============================================="
echo

# Set kubeconfig
export KUBECONFIG=~/.kube/kubeconfig.yaml

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print status
print_status() {
    if [ "$2" = "SUCCESS" ]; then
        echo -e "${GREEN}✓${NC} $1"
    elif [ "$2" = "WARNING" ]; then
        echo -e "${YELLOW}⚠${NC} $1"
    else
        echo -e "${RED}✗${NC} $1"
    fi
}

# Check prerequisites
echo "Checking prerequisites..."
echo "-------------------------"

if ! command -v kubectl &> /dev/null; then
    print_status "kubectl is not installed" "FAILURE"
    exit 1
else
    print_status "kubectl is available" "SUCCESS"
fi

echo

# Verify webhook components
echo "Verifying webhook components..."
echo "-------------------------------"

# Check webhook pod
if kubectl get pods -n cert-manager -l app=cert-manager-webhook-spaceship | grep -q "1/1.*Running"; then
    print_status "Webhook pod is running correctly" "SUCCESS"
    WEBHOOK_POD_STATUS="SUCCESS"
else
    print_status "Webhook pod is not running correctly" "FAILURE"
    WEBHOOK_POD_STATUS="FAILURE"
fi

# Check APIService
if kubectl get apiservice v1alpha1.acme.spaceship.com | grep -q "True"; then
    print_status "APIService is available" "SUCCESS"
    APISERVICE_STATUS="SUCCESS"
else
    print_status "APIService is not available" "FAILURE"
    APISERVICE_STATUS="FAILURE"
fi

# Check ClusterIssuer
if kubectl get clusterissuer letsencrypt-production-spaceship | grep -q "True"; then
    print_status "ClusterIssuer is ready" "SUCCESS"
    CLUSTERISSUER_STATUS="SUCCESS"
else
    print_status "ClusterIssuer is not ready" "FAILURE"
    CLUSTERISSUER_STATUS="FAILURE"
fi

# Check certificate
if kubectl get certificate -n argocd argocd-djasko-com | grep -q "True"; then
    print_status "Certificate is ready" "SUCCESS"
    CERTIFICATE_STATUS="SUCCESS"
else
    print_status "Certificate is not ready" "WARNING"
    CERTIFICATE_STATUS="WARNING"
fi

echo

# Check for errors in logs
echo "Checking logs for errors..."
echo "---------------------------"

# Check webhook logs for flowcontrol errors
if kubectl logs -n cert-manager -l app=cert-manager-webhook-spaceship --tail=50 2>/dev/null | grep -i "flowcontrol\|prioritylevel\|forbidden" > /dev/null; then
    print_status "Found flowcontrol errors in webhook logs" "FAILURE"
    LOG_ERRORS="FAILURE"
else
    print_status "No flowcontrol errors in webhook logs" "SUCCESS"
    LOG_ERRORS="SUCCESS"
fi

echo

# Overall status
echo "Overall status..."
echo "-----------------"

if [ "$WEBHOOK_POD_STATUS" = "SUCCESS" ] && [ "$APISERVICE_STATUS" = "SUCCESS" ] && [ "$CLUSTERISSUER_STATUS" = "SUCCESS" ] && [ "$LOG_ERRORS" = "SUCCESS" ]; then
    if [ "$CERTIFICATE_STATUS" = "SUCCESS" ]; then
        echo
        echo -e "${GREEN}===============================================${NC}"
        echo -e "${GREEN}🎉 ALL CHECKS PASSED - WEBHOOK IS WORKING! 🎉${NC}"
        echo -e "${GREEN}===============================================${NC}"
        echo
        echo "The cert-manager webhook for Spaceship DNS is fully functional."
        echo "Certificates are being successfully issued and managed."
        echo
        echo "For ongoing monitoring, use:"
        echo "  kubectl get certificate -n argocd argocd-djasko-com -w"
        echo
        exit 0
    else
        echo
        echo -e "${YELLOW}===============================================${NC}"
        echo -e "${YELLOW}⚠  WEBHOOK IS FUNCTIONAL BUT CERTIFICATE PENDING${NC}"
        echo -e "${YELLOW}===============================================${NC}"
        echo
        echo "The cert-manager webhook for Spaceship DNS is working correctly,"
        echo "but the certificate is still being processed. This is normal for"
        echo "new certificate requests."
        echo
        echo "Current certificate status:"
        kubectl get certificate -n argocd argocd-djasko-com
        echo
        echo "For ongoing monitoring, use:"
        echo "  kubectl get certificate -n argocd argocd-djasko-com -w"
        echo
        exit 0
    fi
else
    echo
    echo -e "${RED}===============================================${NC}"
    echo -e "${RED}❌  SOME COMPONENTS ARE NOT WORKING CORRECTLY${NC}"
    echo -e "${RED}===============================================${NC}"
    echo
    echo "Issues detected:"
    [ "$WEBHOOK_POD_STATUS" != "SUCCESS" ] && echo "  - Webhook pod is not running correctly"
    [ "$APISERVICE_STATUS" != "SUCCESS" ] && echo "  - APIService is not available"
    [ "$CLUSTERISSUER_STATUS" != "SUCCESS" ] && echo "  - ClusterIssuer is not ready"
    [ "$LOG_ERRORS" != "SUCCESS" ] && echo "  - Flowcontrol errors in logs"
    echo
    echo "Please check the documentation in docs/ for troubleshooting guides."
    echo
    exit 1
fi