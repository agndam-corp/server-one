# Cleanup script for K3s cluster
# This script will completely remove K3s and clean up all related files

#!/bin/bash

echo "Stopping K3s service..."
sudo systemctl stop k3s || true

echo "Removing K3s using official uninstall script..."
if [ -f /usr/local/bin/k3s-uninstall.sh ]; then
  sudo /usr/local/bin/k3s-uninstall.sh
else
  echo "K3s uninstall script not found, proceeding with manual cleanup..."
fi

echo "Cleaning up remaining files..."
sudo rm -rf /etc/rancher/k3s || true
sudo rm -rf /var/lib/rancher/k3s || true
sudo rm -rf /var/lib/kubelet || true
sudo rm -f /usr/local/bin/k3s* || true

echo "Removing kubeconfig directory..."
rm -rf ${KUBECONFIG_DIR:-/home/ubuntu/.kube} || true

echo "K3s cluster completely removed!"