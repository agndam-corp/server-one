#!/bin/sh
# Script to apply configuration to AdGuard Home via API from git
set -e

# Configuration
CONFIG_DIR="config"

# Create temporary directory
TEMP_DIR="/tmp/adguard-apply-$(date +%s)"
mkdir -p $TEMP_DIR
cd $TEMP_DIR

# Wait for AdGuard Home to be ready
until curl -s -u "admin:$ADMIN_PASSWORD" http://adguard-home.adguard-home.svc.cluster.local/control/status > /dev/null; do
  echo "Waiting for AdGuard Home to be ready..."
  sleep 5
done

# Clone the repository
echo "Cloning repository..."
git clone https://${GIT_USERNAME}:${GIT_TOKEN}@${GIT_REPO#https://} repo
cd repo

# Checkout the specified branch
git checkout $GIT_BRANCH

# Check if configuration directory exists
if [ ! -d "$CONFIG_FILE_PATH" ]; then
  echo "Configuration directory not found: $CONFIG_FILE_PATH"
  exit 1
fi

# Apply configuration via API
echo "Applying AdGuard Home configuration..."

# Apply DNS configuration
if [ -f "$CONFIG_FILE_PATH/dns_config.json" ]; then
  echo "Applying DNS configuration..."
  curl -X POST \
    -u "admin:$ADMIN_PASSWORD" \
    -H "Content-Type: application/json" \
    -d @"$CONFIG_FILE_PATH/dns_config.json" \
    http://adguard-home.adguard-home.svc.cluster.local/control/dns_config
fi

# Apply filtering configuration
if [ -f "$CONFIG_FILE_PATH/filtering_status.json" ]; then
  echo "Applying filtering configuration..."
  curl -X POST \
    -u "admin:$ADMIN_PASSWORD" \
    -H "Content-Type: application/json" \
    -d @"$CONFIG_FILE_PATH/filtering_status.json" \
    http://adguard-home.adguard-home.svc.cluster.local/control/filtering/config
fi

# Apply statistics configuration
if [ -f "$CONFIG_FILE_PATH/stats_config.json" ]; then
  echo "Applying statistics configuration..."
  curl -X PUT \
    -u "admin:$ADMIN_PASSWORD" \
    -H "Content-Type: application/json" \
    -d @"$CONFIG_FILE_PATH/stats_config.json" \
    http://adguard-home.adguard-home.svc.cluster.local/control/stats/config/update
fi

# Apply query log configuration
if [ -f "$CONFIG_FILE_PATH/querylog_config.json" ]; then
  echo "Applying query log configuration..."
  curl -X PUT \
    -u "admin:$ADMIN_PASSWORD" \
    -H "Content-Type: application/json" \
    -d @"$CONFIG_FILE_PATH/querylog_config.json" \
    http://adguard-home.adguard-home.svc.cluster.local/control/querylog/config/update
fi

# Apply DHCP configuration
if [ -f "$CONFIG_FILE_PATH/dhcp_config.json" ]; then
  echo "Applying DHCP configuration..."
  curl -X POST \
    -u "admin:$ADMIN_PASSWORD" \
    -H "Content-Type: application/json" \
    -d @"$CONFIG_FILE_PATH/dhcp_config.json" \
    http://adguard-home.adguard-home.svc.cluster.local/control/dhcp/set_config
fi

# Apply parental control status
if [ -f "$CONFIG_FILE_PATH/parental_status.json" ]; then
  echo "Applying parental control status..."
  if grep -q '"enabled":true' "$CONFIG_FILE_PATH/parental_status.json"; then
    curl -X POST \
      -u "admin:$ADMIN_PASSWORD" \
      http://adguard-home.adguard-home.svc.cluster.local/control/parental/enable
  else
    curl -X POST \
      -u "admin:$ADMIN_PASSWORD" \
      http://adguard-home.adguard-home.svc.cluster.local/control/parental/disable
  fi
fi

# Apply safe browsing status
if [ -f "$CONFIG_FILE_PATH/safebrowsing_status.json" ]; then
  echo "Applying safe browsing status..."
  if grep -q '"enabled":true' "$CONFIG_FILE_PATH/safebrowsing_status.json"; then
    curl -X POST \
      -u "admin:$ADMIN_PASSWORD" \
      http://adguard-home.adguard-home.svc.cluster.local/control/safebrowsing/enable
  else
    curl -X POST \
      -u "admin:$ADMIN_PASSWORD" \
      http://adguard-home.adguard-home.svc.cluster.local/control/safebrowsing/disable
  fi
fi

# Apply safe search settings
if [ -f "$CONFIG_FILE_PATH/safesearch_settings.json" ]; then
  echo "Applying safe search settings..."
  curl -X PUT \
    -u "admin:$ADMIN_PASSWORD" \
    -H "Content-Type: application/json" \
    -d @"$CONFIG_FILE_PATH/safesearch_settings.json" \
    http://adguard-home.adguard-home.svc.cluster.local/control/safesearch/settings
fi

# Apply blocked services
if [ -f "$CONFIG_FILE_PATH/blocked_services.json" ]; then
  echo "Applying blocked services..."
  curl -X POST \
    -u "admin:$ADMIN_PASSWORD" \
    -H "Content-Type: application/json" \
    -d @"$CONFIG_FILE_PATH/blocked_services.json" \
    http://adguard-home.adguard-home.svc.cluster.local/control/blocked_services/update
fi

# Apply access list
if [ -f "$CONFIG_FILE_PATH/access_list.json" ]; then
  echo "Applying access list..."
  curl -X POST \
    -u "admin:$ADMIN_PASSWORD" \
    -H "Content-Type: application/json" \
    -d @"$CONFIG_FILE_PATH/access_list.json" \
    http://adguard-home.adguard-home.svc.cluster.local/control/access/set
fi

# Apply TLS configuration
# if [ -f "$CONFIG_FILE_PATH/tls_status.json" ]; then
#   echo "Applying TLS configuration..."
#   curl -X POST \
#     -u "admin:$ADMIN_PASSWORD" \
#     -H "Content-Type: application/json" \
#     -d @"$CONFIG_FILE_PATH/tls_status.json" \
#     http://adguard-home.adguard-home.svc.cluster.local/control/tls/configure
# fi

echo "Configuration applied successfully"

# Clean up
cd /
rm -rf $TEMP_DIR