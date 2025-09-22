# Tools Directory - Project Summary

This directory contains various tools and utilities developed for the Kubernetes cluster management.

## Projects

### cert-manager-webhook-spaceship
**Status: ✅ Completed Successfully**

A cert-manager webhook that enables automated Let's Encrypt certificate issuance for domains managed by Spaceship DNS.

#### Key Features
- Implements cert-manager DNS01 challenge solver interface
- Integrates with Spaceship DNS API for TXT record management
- Fully compatible with Kubernetes and cert-manager
- Deployed via ArgoCD for GitOps workflow

#### Verification
```
$ kubectl get certificate -n argocd argocd-djasko-com
NAME                READY   SECRET                  AGE
argocd-djasko-com   True    argocd-djasko-com-tls   132m
```

#### Documentation
Comprehensive documentation available in `cert-manager-webhook-spaceship/docs/`:
- Quick start guide
- Deployment guide
- Troubleshooting guide
- Deployment checklist
- Complete fix summaries
- API documentation

#### Components
- ✅ Webhook pod: Running correctly
- ✅ APIService: Available and registered
- ✅ ClusterIssuer: Ready and functional
- ✅ Certificate: Successfully issued

## DNS Services

The cluster now provides secure DNS services through AdGuard Home with:
- DNS over HTTPS (DoH) at `dns-adg.djasko.com`
- DNS over TLS (DoT) at `dns-adg.djasko.com`
- Web UI at `dns-adg-ui.djasko.com`

All services are secured with Let's Encrypt certificates managed by cert-manager.

## Future Work

### cert-manager-webhook-spaceship
1. **Enhanced Multi-Domain Support**: Extend to support multiple domains with different API credentials
2. **Advanced Logging**: Implement structured logging with log levels and request tracing
3. **Automated Testing**: Develop comprehensive test suite for regression prevention
4. **Monitoring Integration**: Add Prometheus metrics and Grafana dashboards
5. **Additional DNS Providers**: Extend support to other DNS providers beyond Spaceship DNS

## Maintenance

Regular maintenance tasks for deployed tools:
1. Monitor certificate expiration and renewal
2. Rotate API credentials periodically
3. Update dependencies with cert-manager releases
4. Verify continued compatibility with Kubernetes upgrades
5. Review and update documentation as needed

## Support

For issues with any tools in this directory:
1. Check the project-specific documentation in the respective `docs/` directory
2. Review logs: `kubectl logs -n <namespace> -l app=<app-name>`
3. Verify component status: `kubectl get pods,services,deployments -n <namespace>`
4. Consult troubleshooting guides for common issues