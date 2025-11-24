# RHEL DevOps Toolbox - Build Script
build:
	docker build -f docker/Dockerfile -t rhel-devops-toolbox:latest .

# Build with specific tag
build-tag:
	docker build -f docker/Dockerfile -t rhel-devops-toolbox:$(TAG) .

# Run container
run:
	docker run -it --rm \
		-v $(HOME)/.kube:/home/devops/.kube:ro \
		-v $(PWD)/workspace:/workspace \
		--name devops-toolbox \
		rhel-devops-toolbox:latest

# Run container with Docker socket
run-docker:
	docker run -it --rm \
		-v /var/run/docker.sock:/var/run/docker.sock:ro \
		-v $(HOME)/.kube:/home/devops/.kube:ro \
		-v $(PWD)/workspace:/workspace \
		--name devops-toolbox \
		rhel-devops-toolbox:latest

# Start with docker-compose
up:
	docker-compose -f docker/docker-compose.yml up -d

# Stop docker-compose
down:
	docker-compose -f docker/docker-compose.yml down

# View logs
logs:
	docker-compose -f docker/docker-compose.yml logs -f

# Start with monitoring stack
up-monitoring:
	docker-compose -f docker/docker-compose.yml --profile monitoring up -d

# Start with Harbor
up-harbor:
	docker-compose -f docker/docker-compose.yml --profile harbor up -d

# Start with ChartMuseum
up-chartmuseum:
	docker-compose -f docker/docker-compose.yml --profile chartmuseum up -d

# Shell into running container
shell:
	docker exec -it devops-toolbox /bin/bash

# Run tests
test:
	./scripts/test-all.sh

# Run doctor check
doctor:
	./scripts/doctor.sh

# Clean up
clean:
	docker-compose -f docker/docker-compose.yml down -v
	docker rmi rhel-devops-toolbox:latest || true

# Push to registry
push:
	docker tag rhel-devops-toolbox:latest $(REGISTRY)/rhel-devops-toolbox:latest
	docker push $(REGISTRY)/rhel-devops-toolbox:latest

.PHONY: build build-tag run run-docker up down logs up-monitoring up-harbor up-chartmuseum shell test doctor clean push
