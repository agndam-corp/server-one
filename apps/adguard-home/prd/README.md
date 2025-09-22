# AdGuard Home Configuration Backup and Restore

This directory contains the Kubernetes manifests and scripts for backing up and restoring AdGuard Home configuration with DNS over HTTPS and DNS over TLS support.

## Overview

Today we've made significant progress on implementing a complete backup and restore solution for AdGuard Home. The solution includes:

1. **Backup System**: A cronjob that automatically backs up AdGuard Home configuration to a Git repository
2. **Restore System**: A job that can restore configuration from the Git repository
3. **Initial Setup**: Scripts for initial AdGuard Home configuration
4. **Security**: Proper handling of sensitive information and authentication
5. **DNS Security**: Support for DNS over HTTPS and DNS over TLS with automated certificate management

## Components

### 1. Backup CronJob (`backup-cronjob.yaml`)
- Runs daily at 2 AM to backup AdGuard Home configuration
- Backs up configuration from multiple API endpoints:
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
- Pushes changes to a Git repository using sealed secrets for authentication

### 2. Apply Configuration Job (`apply-config-job.yaml`)
- Can be manually triggered to restore configuration from Git repository
- Applies configuration via AdGuard Home API
- Handles authentication with sealed secrets

### 3. Scripts ConfigMap (`scripts-configmap.yaml`)
Contains the backup and apply scripts:

#### Backup Script (`backup-config.sh`)
- Authenticates with AdGuard Home API
- Retrieves configuration from multiple API endpoints
- Removes sensitive information (password hashes) before saving
- Commits changes to Git repository only if configuration has changed
- Pushes changes to remote repository

#### Apply Script (`apply-config.sh`)
- Clones configuration from Git repository
- Applies configuration via AdGuard Home API
- Handles authentication with sealed secrets

#### Install Script (`install-config.sh`)
- Performs initial AdGuard Home configuration
- Sets up basic configuration for first-time setup

#### Configure Encryption Script (`configure-encryption.sh`)
- Configures TLS settings for DNS over HTTPS and DNS over TLS
- Sets up certificates for secure DNS services
- Enables DoH and DoT functionality

### 4. Sealed Secrets
We use sealed secrets for storing sensitive information:
- Git token for repository access
- Git repository URL
- Git username and email
- AdGuard Home admin password

## DNS Services

The AdGuard Home setup provides multiple DNS services:

1. **DNS over HTTPS (DoH)**: Available at `dns-adg.djasko.com` on port 443
2. **DNS over TLS (DoT)**: Available at `dns-adg.djasko.com` on port 853
3. **Web UI**: Accessible at `dns-adg-ui.djasko.com` with proper SSL termination

All services are secured with Let's Encrypt certificates managed by cert-manager.

## Security Considerations

1. **Sensitive Information Handling**: 
   - Password hashes are removed from configuration before saving to Git
   - Sealed secrets are used for all sensitive data
   - Git token is stored as a sealed secret

2. **Authentication**:
   - All API calls to AdGuard Home use basic authentication
   - Git operations use token authentication
   - Sealed secrets are used for all credentials

3. **TLS Configuration**:
   - Certificates are provided by cert-manager
   - TLS secrets are mounted from cert-manager generated secrets
   - Automated certificate renewal and management

4. **Network Security**:
   - Traefik handles SSL termination and routing
   - IngressRouteTCP resources manage DoH and DoT traffic
   - Proper firewall rules and network policies

## Configuration Endpoints Backed Up

The backup script retrieves configuration from the following AdGuard Home API endpoints:
- `/control/status` - General status and settings
- `/control/dns_info` - DNS configuration
- `/control/filtering/status` - Filtering status
- `/control/dhcp/status` - DHCP configuration
- `/control/stats/config` - Statistics configuration
- `/control/querylog/config` - Query log configuration
- `/control/clients` - Clients list
- `/control/rewrite/list` - Rewrite rules
- `/control/blocked_services/get` - Blocked services
- `/control/access/list` - Access list
- `/control/parental/status` - Parental control status
- `/control/safebrowsing/status` - Safe browsing status
- `/control/safesearch/settings` - Safe search settings
- `/control/tls/status` - TLS configuration
- `/control/profile` - Profile information

## Next Steps

1. **Testing**: 
   - Test the apply configuration job by running it manually
   - Verify that the configuration is properly restored from Git
   - Test the initial setup script

2. **Improvements**:
   - Handle complex configuration types (clients, rewrite rules, blocked services) that require special handling
   - Add error handling and retry mechanisms
   - Add monitoring and alerting for backup failures

3. **Documentation**:
   - Document how to manually trigger backup and restore jobs
   - Document how to troubleshoot common issues
   - Document how to rotate secrets

## Manual Operations

### Trigger Backup Manually
```bash
kubectl create job --from=cronjob/adguard-home-backup adguard-home-backup-manual -n adguard-home
```

### Trigger Restore Manually
```bash
kubectl patch job adguard-home-apply-config -n adguard-home -p '{"spec":{"suspend":false}}'
```

### Check Job Status
```bash
kubectl get jobs -n adguard-home
kubectl get pods -n adguard-home
```

### View Job Logs
```bash
kubectl logs -n adguard-home <pod-name>
```

## Troubleshooting DNS Services

### DNS over HTTPS (DoH)
1. Verify certificate status:
   ```bash
   kubectl get certificate adguard-home-djasko-com -n adguard-home
   ```
2. Check IngressRouteTCP configuration:
   ```bash
   kubectl get ingressroutetcp adguard-home-tls -n adguard-home -o yaml
   ```
3. Test DoH functionality:
   ```bash
   curl -H "accept: application/dns-json" "https://dns-adg.djasko.com/dns-query?name=google.com&type=A" -k
   ```

### DNS over TLS (DoT)
1. Verify Traefik configuration:
   ```bash
   kubectl get deployment traefik -n kube-system -o yaml
   ```
2. Check Traefik service:
   ```bash
   kubectl get svc traefik -n kube-system
   ```
3. Test DoT connectivity:
   ```bash
   echo | openssl s_client -connect dns-adg.djasko.com:853 -servername dns-adg.djasko.com
   ```

## Conclusion

Today we've successfully implemented a comprehensive backup and restore solution for AdGuard Home that:
- Automatically backs up configuration to Git on a daily basis
- Can restore configuration from Git when needed
- Properly handles sensitive information
- Uses sealed secrets for secure credential storage
- Integrates with cert-manager for TLS certificate management
- Supports initial setup of AdGuard Home
- Provides secure DNS services with DoH and DoT support

Tomorrow we'll focus on testing the restore functionality and handling any remaining edge cases.