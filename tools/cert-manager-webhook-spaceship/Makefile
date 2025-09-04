# Makefile for cert-manager-webhook-spaceship

IMAGE_NAME = damianjaskolski95/cert-manager-webhook-spaceship
IMAGE_TAG = latest
NAMESPACE = cert-manager

.PHONY: build push deploy secret clean test help

build:
	docker build -t $(IMAGE_NAME):$(IMAGE_TAG) .

push:
	docker push $(IMAGE_NAME):$(IMAGE_TAG)

deploy:
	kubectl apply -f deploy/webhook.yaml
	kubectl rollout status deployment/cert-manager-webhook-spaceship -n $(NAMESPACE)

secret:
	./scripts/create-secret.sh

install: build push deploy secret

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
	@echo "  push    - Push the Docker image to registry"
	@echo "  deploy  - Deploy the webhook to Kubernetes"
	@echo "  secret  - Create the API credentials secret"
	@echo "  install - Build, push, deploy and create secret"
	@echo "  uninstall - Uninstall all resources"
	@echo "  clean   - Remove the Docker image"
	@echo "  test    - Run tests"
	@echo "  help    - Show this help message"