#!/bin/bash

# Script to set up iptables rules for redirecting traffic to nginx ingress controller
# This redirects traffic from standard HTTP/HTTPS ports to the nginx NodePort

# Node IP
NODE_IP="146.59.45.254"

# Nginx ingress NodePort configuration
NGINX_HTTP_PORT="32080"
NGINX_HTTPS_PORT="32443"

# Flush existing rules in the NAT table (optional - be careful with this)
# iptables -t nat -F

# Redirect HTTP traffic (port 80) to nginx ingress NodePort
iptables -t nat -A PREROUTING -p tcp --dport 80 -j DNAT --to-destination $NODE_IP:$NGINX_HTTP_PORT

# Redirect HTTPS traffic (port 443) to nginx ingress NodePort
iptables -t nat -A PREROUTING -p tcp --dport 443 -j DNAT --to-destination $NODE_IP:$NGINX_HTTPS_PORT

# Enable masquerading for outbound traffic
iptables -t nat -A POSTROUTING -j MASQUERADE

# Save the iptables rules (command may vary based on distribution)
# For Ubuntu/Debian:
# iptables-save > /etc/iptables/rules.v4

echo "iptables rules applied successfully!"
echo "HTTP traffic on port 80 will be redirected to $NODE_IP:$NGINX_HTTP_PORT"
echo "HTTPS traffic on port 443 will be redirected to $NODE_IP:$NGINX_HTTPS_PORT"