# cert-manager Webhook for Spaceship DNS - Documentation Index

## Overview

This document provides an index of all documentation for the cert-manager webhook for Spaceship DNS.

## Documentation Files

| Document | Description |
|----------|-------------|
| [README.md](../README.md) | Main project documentation with installation, usage, and API information |
| [QUICK_START.md](QUICK_START.md) | Quick start guide for deploying and using the webhook |
| [DEPLOYMENT_GUIDE.md](DEPLOYMENT_GUIDE.md) | Detailed deployment guide with configuration options |
| [TROUBLESHOOTING_GUIDE.md](TROUBLESHOOTING_GUIDE.md) | Comprehensive troubleshooting guide for common issues |
| [COMPLETE_FIX_SUMMARY.md](COMPLETE_FIX_SUMMARY.md) | ✅ **Complete summary of all fixes made to get the webhook working** |
| [FIXES_SUMMARY_OLD.md](FIXES_SUMMARY_OLD.md) | Previous summary of fixes (archived) |
| [APISERVICE_FIX_001.md](APISERVICE_FIX_001.md) | Fix for APIService configuration issues |
| [RBAC_FIX_001.md](RBAC_FIX_001.md) | Fix for cert-manager RBAC permissions |
| [RBAC_FIX_002.md](RBAC_FIX_002.md) | Fix for webhook RBAC permissions |
| [AUTHENTICATION_FIX_001.md](AUTHENTICATION_FIX_001.md) | Fix for Spaceship DNS API authentication and request format |

## Quick Links

- [Spaceship DNS API Documentation](https://docs.spaceship.dev/)
- [cert-manager Documentation](https://cert-manager.io/docs/)
- [ArgoCD Documentation](https://argo-cd.readthedocs.io/)

## Support

For issues, please check:

1. [GitHub Issues](https://github.com/your-org/your-repo/issues)
2. The troubleshooting guides in this directory
3. Webhook logs: `kubectl logs -n cert-manager -l app=cert-manager-webhook-spaceship`