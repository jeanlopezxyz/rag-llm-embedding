# Makefile
.PHONY: build push run test clean deploy logs

# Variables
REGISTRY ?= quay.io
NAMESPACE ?= ecosystem-appeng
IMAGE_NAME ?= event-embeddings-generator
TAG ?= 1.0.0
FULL_IMAGE = $(REGISTRY)/$(NAMESPACE)/$(IMAGE_NAME):$(TAG)

# Kubernetes
K8S_NAMESPACE ?= rag-llm
JOB_NAME ?= populate-events-embeddings

# Colores
GREEN := \033[0;32m
RED := \033[0;31m
NC := \033[0m

## Build: Construir la imagen Docker
build:
	@echo "$(GREEN)Building Docker image...$(NC)"
	podman build -t $(FULL_IMAGE) .
	@echo "$(GREEN)Build complete: $(FULL_IMAGE)$(NC)"

## Push: Subir imagen al registro
push: build
	@echo "$(GREEN)Pushing image to registry...$(NC)"
	podman push $(FULL_IMAGE)
	@echo "$(GREEN)Push complete$(NC)"

## Run: Ejecutar localmente con podman-compose
run:
	@echo "$(GREEN)Running locally with podman-compose...$(NC)"
	podman-compose up --build

## Test: Ejecutar tests
test:
	@echo "$(GREEN)Running tests...$(NC)"
	podman run --rm $(FULL_IMAGE) python -m pytest /app/tests/

## Deploy: Desplegar en Kubernetes
deploy:
	@echo "$(GREEN)Deploying to Kubernetes...$(NC)"
	kubectl apply -f k8s/secrets.yaml -n $(K8S_NAMESPACE)
	kubectl apply -f k8s/job.yaml -n $(K8S_NAMESPACE)
	@echo "$(GREEN)Deployment complete$(NC)"

## Logs: Ver logs del Job
logs:
	kubectl logs -f job/$(JOB_NAME) -n $(K8S_NAMESPACE)

## Clean: Limpiar recursos
clean:
	@echo "$(RED)Cleaning up resources...$(NC)"
	kubectl delete job $(JOB_NAME) -n $(K8S_NAMESPACE) --ignore-not-found=true
	podman-compose down -v
	@echo "$(GREEN)Cleanup complete$(NC)"

## Shell: Abrir shell en el contenedor
shell:
	podman run --rm -it --entrypoint /bin/bash $(FULL_IMAGE)

## Help: Mostrar ayuda
help:
	@echo "Available targets:"
	@grep -E '^##' Makefile | sed 's/## /  /'
