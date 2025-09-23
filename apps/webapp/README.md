# Webapp for VPN Control

This webapp provides a simple interface to control the VPN instance (start/stop) and view its status.

## Components

- Frontend: Vue 3 + Vite application with Tailwind CSS
- Backend: Go application with Gin framework
- Kubernetes manifests for deployment

## Features

- Start/stop VPN instance
- View current instance status
- Basic authentication protection

## Deployment

The application is deployed on Kubernetes with the following components:

1. Frontend (Vue 3 + Vite) - served via Nginx
2. Backend (Go + Gin) - API server
3. Ingress resources for djasko.com and api.djasko.com
4. Certificates managed by cert-manager

## Prerequisites

- Kubernetes cluster with Traefik ingress controller
- cert-manager installed
- Sealed Secrets controller for managing secrets

## Required Secrets

The application requires the following secrets to be created:

1. `vpn-instance-config` - Contains the VPN instance ID
2. `webapp-auth` - Contains basic auth credentials

These can be created using the generate-sealed-secrets.sh script.