# Makefile for frontend

# Variables
REGISTRY = ghcr.io
USERNAME = damianjaskolski95
IMAGE = $(REGISTRY)/$(USERNAME)/adguard-home-backup
TAG ?= v1.0.0

# Build target
.PHONY: build

build:
	@echo "Building frontend Docker image..."
	docker build -t $(IMAGE):$(TAG) .

# Push target
.PHONY: push

push:
	@echo "Pushing frontend Docker image..."
	docker push $(IMAGE):$(TAG)

# All-in-one target
.PHONY: all

all: build push

# Clean target
.PHONY: clean

clean:
	@echo "Cleaning up..."
	rm -rf dist