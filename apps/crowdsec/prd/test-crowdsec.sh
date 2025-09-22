#!/bin/bash

# Test script for CrowdSec with Traefik
# This script will help verify that the CrowdSec setup is working correctly

echo "=== CrowdSec Test Script ==="
echo ""

# Check if CrowdSec is deployed
echo "1. Checking if CrowdSec is deployed..."
kubectl get pods -n crowdsec
echo ""

# Check if CrowdSec services are running
echo "2. Checking CrowdSec services..."
kubectl get svc -n crowdsec
echo ""

# Check if CrowdSec secrets exist
echo "3. Checking CrowdSec secrets..."
kubectl get secret crowdsec-secrets -n crowdsec
echo ""

# Check if CrowdSec LAPI pod has the correct environment variables
echo "4. Checking CrowdSec LAPI environment variables..."
kubectl exec -n crowdsec deploy/crowdsec-lapi -- env | grep -E "(ENROLL|BOUNCER)"
echo ""

# Check if CrowdSec is collecting logs from Traefik
echo "5. Checking logs from Traefik..."
kubectl logs -n kube-system -l app.kubernetes.io/name=traefik --tail=20
echo ""

# Check CrowdSec metrics
echo "6. Checking CrowdSec metrics..."
kubectl exec -n crowdsec deploy/crowdsec-lapi -- cscli metrics
echo ""

# Check CrowdSec decisions
echo "7. Checking CrowdSec decisions..."
kubectl exec -n crowdsec deploy/crowdsec-lapi -- cscli decisions list
echo ""

echo "=== Test Script Complete ==="
echo ""
echo "To test the blocking mechanism, you can:"
echo "1. Generate DNS queries from a test client through Traefik"
echo "2. Check if CrowdSec detects and blocks the IP"
echo "3. Verify that the blocked IP is in the decisions list"