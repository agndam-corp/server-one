#!/bin/sh
# Script to configure TLS/encryption settings for AdGuard Home
set -e

# Wait for AdGuard Home to be ready
until curl -s -u "admin:$ADMIN_PASSWORD" http://adguard-home.adguard-home.svc.cluster.local/control/status > /dev/null; do
  echo "Waiting for AdGuard Home to be ready..."
  sleep 5
done

# Get current TLS configuration to see what we're working with
echo "Getting current TLS configuration..."
curl -s -u "admin:$ADMIN_PASSWORD" \
  http://adguard-home.adguard-home.svc.cluster.local/control/tls/status > current_tls_config.json

echo "Current TLS configuration:"
cat current_tls_config.json

# Create TLS configuration with HTTPS, DoH, and DoT enabled
# Disable plain DNS as requested
# Using certificate paths instead of embedding the certificate content
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
  "port_dns_over_quic": 784,
  "port_dnscrypt": 0,
  "dnscrypt_config_file": "",
  "allow_unencrypted_doh": false,
  "strict_sni_check": false,
  "disable_plaintext": true
}
EOF

echo "New TLS configuration:"
cat tls_config.json

# Validate the TLS configuration first
echo "Validating TLS configuration..."
VALIDATION_RESPONSE_CODE=$(curl -s -o /tmp/validation_response.txt -w "%{http_code}" \
  -u "admin:$ADMIN_PASSWORD" \
  -H "Content-Type: application/json" \
  -d @tls_config.json \
  http://adguard-home.adguard-home.svc.cluster.local/control/tls/validate)

echo "Validation response code: $VALIDATION_RESPONSE_CODE"
echo "Validation response body:"
cat /tmp/validation_response.txt

# Check if validation was successful (HTTP 2xx status)
if [ "$VALIDATION_RESPONSE_CODE" -lt 200 ] || [ "$VALIDATION_RESPONSE_CODE" -gt 299 ]; then
  echo "ERROR: TLS configuration validation failed with HTTP $VALIDATION_RESPONSE_CODE"
  echo "Exiting..."
  exit 1
fi

echo "TLS configuration validation successful"

# Configure TLS
echo "Configuring TLS..."
CONFIGURE_RESPONSE_CODE=$(curl -s -o /tmp/configure_response.txt -w "%{http_code}" \
  -u "admin:$ADMIN_PASSWORD" \
  -H "Content-Type: application/json" \
  -d @tls_config.json \
  http://adguard-home.adguard-home.svc.cluster.local/control/tls/configure)

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
  http://adguard-home.adguard-home.svc.cluster.local/control/restart)

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