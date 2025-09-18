# AdGuard Home Backup and Restore - Day 1 Summary

## Today's Achievements

Today we made significant progress on implementing a complete backup and restore solution for AdGuard Home:

### 1. Fixed Access Issues
- Identified and fixed the port mapping issue (container listens on port 80, not 3000 after initial setup)
- Updated service configuration to correctly forward port 80 to container port 80
- Verified that the ingress is properly routing traffic to the service

### 2. Enhanced Backup Script
- Updated backup script to remove sensitive information (password hashes) before saving to Git
- Added support for backing up configuration from multiple API endpoints:
  - General status/settings
  - DNS configuration
  - Filtering status
  - DHCP configuration
  - Statistics configuration
  - Query log configuration
  - Clients
  - Rewrite rules
  - Blocked services
  - Access list
  - Parental control status
  - Safe browsing status
  - Safe search settings
  - TLS configuration
  - Profile information

### 3. Improved Security
- Added bcrypt password handling (AdGuard Home handles this automatically via API)
- Separated sensitive information from configuration backups
- Updated scripts to use Git credentials from sealed secrets

### 4. Custom Docker Image
- Created a custom Docker image with necessary tools (curl, git, jq)
- Updated backup and apply jobs to use the custom Docker image
- Set proper permissions for scripts in volume mounts

### 5. Restructured Configuration
- Changed from single file backup to separate files in a config directory
- Updated CONFIG_FILE_PATH to point to the config directory
- Improved organization of backed up configuration files

### 6. Initial Setup Support
- Added support for initial AdGuard Home configuration
- Created install-config.sh script for first-time setup
- Prepared scripts to handle both initial setup and ongoing configuration management

## Files Modified Today

1. `/home/ubuntu/project/apps/adguard-home/prd/service.yaml` - Fixed port mapping
2. `/home/ubuntu/project/apps/adguard-home/prd/scripts-configmap.yaml` - Enhanced backup and apply scripts
3. `/home/ubuntu/project/apps/adguard-home/prd/backup-cronjob.yaml` - Updated to use custom Docker image
4. `/home/ubuntu/project/apps/adguard-home/prd/apply-config-job.yaml` - Updated to use custom Docker image
5. Various sealed secret files - Updated to include additional configuration

## Issues Resolved

1. **Bad Gateway Error**: Fixed by correcting the service port mapping
2. **Authentication Issues**: Resolved by using proper API authentication
3. **Git Operations**: Fixed by ensuring proper permissions and using sealed secrets for credentials
4. **Configuration Backup**: Enhanced to back up all relevant configuration endpoints
5. **Security**: Improved by removing sensitive information from backups

## Next Steps

Tomorrow we'll focus on:

1. Testing the apply configuration job by running it manually
2. Verifying that the configuration is properly backed up to Git
3. Testing the initial setup script
4. Handling complex configuration types that require special handling
5. Adding error handling and retry mechanisms
6. Documenting how to manually trigger backup and restore jobs

## Lessons Learned

1. AdGuard Home switches from port 3000 to port 80 after initial setup
2. The API requires proper authentication for most endpoints
3. Sensitive information like password hashes should be removed from backups
4. Using sealed secrets is the proper way to handle sensitive data in Kubernetes
5. Custom Docker images with necessary tools provide better reliability than trying to install tools at runtime
6. Organizing configuration into separate files makes management easier