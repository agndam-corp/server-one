#!/bin/sh
# Script to configure TLS/encryption settings for AdGuard Home
set -e

# Wait for AdGuard Home to be ready
until curl -s -u "admin:$ADMIN_PASSWORD" https://adguard-home.adguard-home.svc.cluster.local/control/status --insecure > /dev/null; do
  echo "Waiting for AdGuard Home to be ready..."
  sleep 5
done

# Get current TLS configuration to see what we're working with
echo "Getting current TLS configuration..."
curl -s -u "admin:$ADMIN_PASSWORD" \
  https://adguard-home.adguard-home.svc.cluster.local/control/tls/status --insecure > current_tls_config.json

echo "Current TLS configuration:"
cat current_tls_config.json

# Create TLS configuration to enable HTTPS on port 443
# Also enable DNS-over-TLS and DNS-over-QUIC
cat > tls_config.json <<EOF
{
  "enabled": true,
  "server_name": "dns-adg.djasko.com",
  "certificate_path": "/etc/adguardhome/tls/tls.crt",
  "private_key_path": "/etc/adguardhome/tls/tls.key",
  "private_key_saved": true,
  "force_https": true,
  "port_https": 443,
  "port_dns_over_tls": 853,
  "port_dns_over_quic": 853,
  "port_dnscrypt": 0,
  "dnscrypt_config_file": "",
  "allow_unencrypted_doh": false,
  "strict_sni_check": false,
  "disable_plaintext": true,
  "serve_plain_dns": true
}
EOF

echo "New TLS configuration:"
cat tls_config.json

# Skip validation due to redirect issues and go directly to configuration
echo "Skipping validation due to redirect issues, going directly to configuration"

# Configure TLS
echo "Configuring TLS..."
CONFIGURE_RESPONSE_CODE=$(curl -s -o /tmp/configure_response.txt -w "%{http_code}" \
  -u "admin:$ADMIN_PASSWORD" \
  -H "Content-Type: application/json" \
  -d @tls_config.json \
  https://adguard-home.adguard-home.svc.cluster.local/control/tls/configure --insecure)

echo "Configuration response code: $CONFIGURE_RESPONSE_CODE"
echo "Configuration response body:"
cat /tmp/configure_response.txt

# Check if configuration was successful (HTTP 2xx status)
if [ "$CONFIGURE_RESPONSE_CODE" -lt 200 ] || [ "$CONFIGURE_RESPONSE_CODE" -gt 299 ]; then
  echo "ERROR: TLS configuration failed with HTTP $CONFIGURE_RESPONSE_CODE"
  echo "Exiting..."
  exit 1
fi

echo "TLS configuration applied successfully"

# Restart AdGuard Home to apply changes
echo "Restarting AdGuard Home to apply TLS configuration..."
RESTART_RESPONSE_CODE=$(curl -s -o /tmp/restart_response.txt -w "%{http_code}" \
  -u "admin:$ADMIN_PASSWORD" \
  -X POST \
  https://adguard-home.adguard-home.svc.cluster.local/control/restart --insecure)

echo "Restart response code: $RESTART_RESPONSE_CODE"
echo "Restart response body:"
cat /tmp/restart_response.txt

# Check if restart was successful (HTTP 2xx status)
if [ "$RESTART_RESPONSE_CODE" -lt 200 ] || [ "$RESTART_RESPONSE_CODE" -gt 299 ]; then
  echo "ERROR: Failed to restart AdGuard Home with HTTP $RESTART_RESPONSE_CODE"
  echo "Exiting..."
  exit 1
fi

echo "AdGuard Home restarted successfully"
echo "TLS configuration applied and AdGuard Home restarted"