#!/bin/sh
# Script to backup AdGuard Home configuration via API and push to git
set -e

# Configuration
CONFIG_DIR="config"

# Create temporary directory
TEMP_DIR="/tmp/adguard-backup-$(date +%s)"
mkdir -p $TEMP_DIR
cd $TEMP_DIR

echo "Created temporary directory: $TEMP_DIR"

# Wait for AdGuard Home to be ready
until curl -s -u "admin:$ADMIN_PASSWORD" http://adguard-home.adguard-home.svc.cluster.local/control/status > /dev/null; do
  echo "Waiting for AdGuard Home to be ready..."
  sleep 5
done

# Create config directory
mkdir -p $CONFIG_DIR
echo "Created config directory: $CONFIG_DIR"

# Get current configuration from various API endpoints
echo "Backing up AdGuard Home configuration..."

# Get general status/settings
echo "Backing up general status/settings..."
if curl -s -u "admin:$ADMIN_PASSWORD" \
  http://adguard-home.adguard-home.svc.cluster.local/control/status > $CONFIG_DIR/general_status.json; then
  echo "General status/settings backed up successfully"
else
  echo "Failed to backup general status/settings"
fi

# Get DNS configuration
echo "Backing up DNS configuration..."
if curl -s -u "admin:$ADMIN_PASSWORD" \
  http://adguard-home.adguard-home.svc.cluster.local/control/dns_info > $CONFIG_DIR/dns_config.json; then
  echo "DNS configuration backed up successfully"
else
  echo "Failed to backup DNS configuration"
fi

# Get filtering status
echo "Backing up filtering status..."
if curl -s -u "admin:$ADMIN_PASSWORD" \
  http://adguard-home.adguard-home.svc.cluster.local/control/filtering/status > $CONFIG_DIR/filtering_status.json; then
  echo "Filtering status backed up successfully"
else
  echo "Failed to backup filtering status"
fi

# Get DHCP configuration
echo "Backing up DHCP configuration..."
if curl -s -u "admin:$ADMIN_PASSWORD" \
  http://adguard-home.adguard-home.svc.cluster.local/control/dhcp/status > $CONFIG_DIR/dhcp_config.json; then
  echo "DHCP configuration backed up successfully"
else
  echo "Failed to backup DHCP configuration"
fi

# Get statistics configuration
echo "Backing up statistics configuration..."
if curl -s -u "admin:$ADMIN_PASSWORD" \
  http://adguard-home.adguard-home.svc.cluster.local/control/stats/config > $CONFIG_DIR/stats_config.json; then
  echo "Statistics configuration backed up successfully"
else
  echo "Failed to backup statistics configuration"
fi

# Get query log configuration
echo "Backing up query log configuration..."
if curl -s -u "admin:$ADMIN_PASSWORD" \
  http://adguard-home.adguard-home.svc.cluster.local/control/querylog/config > $CONFIG_DIR/querylog_config.json; then
  echo "Query log configuration backed up successfully"
else
  echo "Failed to backup query log configuration"
fi

# Get clients
echo "Backing up clients..."
if curl -s -u "admin:$ADMIN_PASSWORD" \
  http://adguard-home.adguard-home.svc.cluster.local/control/clients > $CONFIG_DIR/clients.json; then
  echo "Clients backed up successfully"
else
  echo "Failed to backup clients"
fi

# Get rewrite rules
echo "Backing up rewrite rules..."
if curl -s -u "admin:$ADMIN_PASSWORD" \
  http://adguard-home.adguard-home.svc.cluster.local/control/rewrite/list > $CONFIG_DIR/rewrite_list.json; then
  echo "Rewrite rules backed up successfully"
else
  echo "Failed to backup rewrite rules"
fi

# Get blocked services
echo "Backing up blocked services..."
if curl -s -u "admin:$ADMIN_PASSWORD" \
  http://adguard-home.adguard-home.svc.cluster.local/control/blocked_services/get > $CONFIG_DIR/blocked_services.json; then
  echo "Blocked services backed up successfully"
else
  echo "Failed to backup blocked services"
fi

# Get access list
echo "Backing up access list..."
if curl -s -u "admin:$ADMIN_PASSWORD" \
  http://adguard-home.adguard-home.svc.cluster.local/control/access/list > $CONFIG_DIR/access_list.json; then
  echo "Access list backed up successfully"
else
  echo "Failed to backup access list"
fi

# Get parental control status
echo "Backing up parental control status..."
if curl -s -u "admin:$ADMIN_PASSWORD" \
  http://adguard-home.adguard-home.svc.cluster.local/control/parental/status > $CONFIG_DIR/parental_status.json; then
  echo "Parental control status backed up successfully"
else
  echo "Failed to backup parental control status"
fi

# Get safe browsing status
echo "Backing up safe browsing status..."
if curl -s -u "admin:$ADMIN_PASSWORD" \
  http://adguard-home.adguard-home.svc.cluster.local/control/safebrowsing/status > $CONFIG_DIR/safebrowsing_status.json; then
  echo "Safe browsing status backed up successfully"
else
  echo "Failed to backup safe browsing status"
fi

# Get safe search settings
echo "Backing up safe search settings..."
if curl -s -u "admin:$ADMIN_PASSWORD" \
  http://adguard-home.adguard-home.svc.cluster.local/control/safesearch/settings > $CONFIG_DIR/safesearch_settings.json; then
  echo "Safe search settings backed up successfully"
else
  echo "Failed to backup safe search settings"
fi

# Get TLS configuration
echo "Backing up TLS configuration..."
if curl -s -u "admin:$ADMIN_PASSWORD" \
  http://adguard-home.adguard-home.svc.cluster.local/control/tls/status > $CONFIG_DIR/tls_status.json; then
  echo "TLS configuration backed up successfully"
else
  echo "Failed to backup TLS configuration"
fi

# Get profile information
echo "Backing up profile information..."
if curl -s -u "admin:$ADMIN_PASSWORD" \
  http://adguard-home.adguard-home.svc.cluster.local/control/profile > $CONFIG_DIR/profile.json; then
  echo "Profile information backed up successfully"
else
  echo "Failed to backup profile information"
fi

# Debug: Show what we have in the config directory
echo "Contents of config directory:"
ls -la $CONFIG_DIR/

# Create a temporary git repository
echo "Creating temporary git repository..."
mkdir repo
cd repo

# Clone the repository
echo "Cloning repository..."
if git clone https://${GIT_USERNAME}:${GIT_TOKEN}@${GIT_REPO#https://} .; then
  echo "Repository cloned successfully"
  git config user.name "$GIT_USERNAME"
  git config user.email "$GIT_EMAIL"
else
  echo "Failed to clone repository"
  exit 1
fi

# Debug: Show repository structure
echo "Repository structure before copying:"
find . -type d -name ".git" -prune -o -print

# Copy configuration files
echo "Copying configuration files..."
mkdir -p "$CONFIG_FILE_PATH"
cp -r ../$CONFIG_DIR/* "$CONFIG_FILE_PATH/"

# Debug: Show what we have copied
echo "Copied configuration files:"
find "$CONFIG_FILE_PATH" -type f -exec ls -la {} \;
git status

# Check if there are changes (both tracked and untracked files)
echo "Checking for changes..."
CHANGES_FOUND=false

# Check for untracked files
if [ -n "$(git ls-files --others --exclude-standard "$CONFIG_FILE_PATH")" ]; then
  echo "Found untracked files"
  CHANGES_FOUND=true
fi

# Check for modified tracked files
if ! git diff --quiet "$CONFIG_FILE_PATH"; then
  echo "Found modified tracked files"
  CHANGES_FOUND=true
fi

if [ "$CHANGES_FOUND" = true ]; then
  echo "Configuration has changed, committing..."
  
  # Show what changes we have
  echo "Changes to be committed:"
  git status "$CONFIG_FILE_PATH"
  
  # Add and commit changes
  git add "$CONFIG_FILE_PATH"
  git commit -m "Update AdGuard Home configuration $(date)"
  
  # Push changes
  echo "Pushing changes to repository..."
  if git push origin $GIT_BRANCH; then
    echo "Configuration backup completed and pushed to git"
  else
    echo "Failed to push changes to repository"
  fi
else
  echo "Configuration unchanged, no commit needed"
fi

# Clean up
cd /
rm -rf $TEMP_DIR