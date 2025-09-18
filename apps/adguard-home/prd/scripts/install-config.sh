#!/bin/sh
# Script to perform initial installation of AdGuard Home configuration
set -e

# Create temporary directory
TEMP_DIR="/tmp/adguard-install-$(date +%s)"
mkdir -p $TEMP_DIR
cd $TEMP_DIR

# Wait for AdGuard Home to be ready on port 3000 (initial setup)
until curl -s http://adguard-home.adguard-home.svc.cluster.local:3000/control/install/get_addresses > /dev/null; do
  echo "Waiting for AdGuard Home to be ready for initial setup on port 3000..."
  sleep 5
done

# Prepare initial configuration
echo "Preparing initial configuration..."
# Create the initial configuration JSON
cat > initial_config.json <<EOF
{
  "dns": {
    "ip": "0.0.0.0",
    "port": 53
  },
  "web": {
    "ip": "0.0.0.0",
    "port": 80
  },
  "username": "admin",
  "password": "$ADMIN_PASSWORD"
}
EOF

# Apply initial configuration
echo "Applying initial configuration..."
RESPONSE=$(curl -s -X POST \
  -H "Content-Type: application/json" \
  -d @initial_config.json \
  http://adguard-home.adguard-home.svc.cluster.local:3000/control/install/configure)

if [ $? -eq 0 ]; then
  echo "Initial configuration applied successfully"
  echo "Response: $RESPONSE"
else
  echo "Failed to apply initial configuration"
  exit 1
fi

# Clean up
cd /
rm -rf $TEMP_DIR