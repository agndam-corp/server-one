# Makefile for cert-manager-webhook-spaceship

IMAGE_NAME = cert-manager-webhook-spaceship
IMAGE_TAG = latest
NAMESPACE = cert-manager

.PHONY: build deploy secret clean test help

build:
	docker build -t $(IMAGE_NAME):$(IMAGE_TAG) .

push:
	docker save cert-manager-webhook-spaceship:latest > cert-manager-webhook-spaceship.tar
	sudo k3s ctr images import cert-manager-webhook-spaceship.tar

deploy:
	kubectl apply -f deploy/webhook.yaml
	kubectl rollout status deployment/cert-manager-webhook-spaceship -n $(NAMESPACE)

secret:
	./scripts/create-secret.sh

install: build push deploy

uninstall:
	kubectl delete -f deploy/

clean:
	docker rmi $(IMAGE_NAME):$(IMAGE_TAG) || true

test:
	go test -v ./...

.PHONY: help
help:
	@echo "Available targets:"
	@echo "  build   - Build the Docker image"
	@echo "  deploy  - Deploy the webhook to Kubernetes"
	@echo "  secret  - Create the API credentials secret"
	@echo "  install - Build, deploy and create secret"
	@echo "  uninstall - Uninstall all resources"
	@echo "  clean   - Remove the Docker image"
	@echo "  test    - Run tests"
	@echo "  help    - Show this help message"