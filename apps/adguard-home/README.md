# AdGuard Home Backup and Restore Solution

This project provides a complete backup and restore solution for AdGuard Home running in Kubernetes.

## Features

- **Automatic Daily Backups**: Configuration is automatically backed up to a Git repository every day
- **Manual Restore**: Configuration can be manually restored from Git when needed
- **Secure**: Sensitive information is properly handled and stored using sealed secrets
- **Complete Coverage**: All AdGuard Home configuration endpoints are backed up
- **Easy Deployment**: Deployed using Kubernetes manifests and Kustomize

## Components

- **Backup CronJob**: Runs daily to backup AdGuard Home configuration
- **Apply Job**: Can be manually triggered to restore configuration from Git
- **Custom Docker Image**: Contains all necessary tools (curl, git, jq)
- **Sealed Secrets**: Securely stores sensitive information (Git credentials, admin password)
- **ConfigMaps**: Contains backup and apply scripts

## Prerequisites

- Kubernetes cluster with cert-manager installed
- Sealed Secrets controller installed
- Git repository for storing configuration backups
- GitHub Personal Access Token with appropriate permissions

## Deployment

```bash
kubectl apply -k /home/ubuntu/project/apps/adguard-home/prd
```

## Configuration

The solution uses sealed secrets for sensitive information:

- `adguard-home-git-token`: Git repository URL, username, and token
- `adguard-home-admin-password`: AdGuard Home admin password
- `ghcr-secret`: GHCR credentials for pulling custom Docker image

## Usage

### Trigger Backup Manually

```bash
kubectl create job --from=cronjob/adguard-home-backup adguard-home-backup-manual -n adguard-home
```

### Trigger Restore Manually

```bash
kubectl patch job adguard-home-apply-config -n adguard-home -p '{"spec":{"suspend":false}}'
```

## Security

- Sensitive information (password hashes) is removed from backups
- Git credentials are stored as sealed secrets
- AdGuard Home admin password is stored as a sealed secret
- All API calls use proper authentication

## Troubleshooting

### Check Job Status

```bash
kubectl get jobs -n adguard-home
kubectl get pods -n adguard-home
```

### View Job Logs

```bash
kubectl logs -n adguard-home <pod-name>
```

### Common Issues

1. **Bad Gateway Error**: Usually caused by incorrect port mapping - ensure service forwards port 80 to container port 80
2. **Authentication Issues**: Verify that admin password is correctly set in sealed secrets
3. **Git Operations Failures**: Check that Git credentials are correctly set in sealed secrets
4. **Configuration Not Backed Up**: Verify that all configuration endpoints are accessible via API

## Contributing

Feel free to submit issues and pull requests to improve this solution.

## License

This project is licensed under the MIT License.