#!/bin/bash

# Script to remove iptables rules for redirecting traffic to nginx ingress controller

# Node IP
NODE_IP="146.59.45.254"

# Nginx ingress NodePort configuration
NGINX_HTTP_PORT="32080"
NGINX_HTTPS_PORT="32443"

# Remove the HTTP redirect rule
iptables -t nat -D PREROUTING -p tcp --dport 80 -j DNAT --to-destination $NODE_IP:$NGINX_HTTP_PORT 2>/dev/null

# Remove the HTTPS redirect rule
iptables -t nat -D PREROUTING -p tcp --dport 443 -j DNAT --to-destination $NODE_IP:$NGINX_HTTPS_PORT 2>/dev/null

# Save the iptables rules (command may vary based on distribution)
# For Ubuntu/Debian:
# iptables-save > /etc/iptables/rules.v4

echo "iptables redirect rules removed successfully!"