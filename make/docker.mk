# ═══════════════════════════════════════════════════════════════
# 󰡨 DOCKER - Interactive local package preview
# ═══════════════════════════════════════════════════════════════

DOCKER_IMAGE ?= git-setup:local

.PHONY: help-docker docker-build docker-run docker-clean

help-docker: ## Show Docker targets
	@printf "\n"
	@printf "$(CYAN)Docker targets$(NC)\n"
	@printf "$(CYAN)────────────────────────────────────────────────────────────────────────────────$(NC)\n"
	@printf "  make docker-build          Build $(DOCKER_IMAGE)\n"
	@printf "  make docker-run            Start the interactive, ephemeral container\n"
	@printf "  make docker-clean          Remove the local image\n"
	@printf "\n"

docker-build: ## Build the local Docker image
	@command -v docker > /dev/null || { printf "$(RED)Docker is not installed$(NC)\n"; exit 1; }
	@docker build --tag "$(DOCKER_IMAGE)" .

docker-run: ## Run git-setup interactively in an ephemeral container
	@command -v docker > /dev/null || { printf "$(RED)Docker is not installed$(NC)\n"; exit 1; }
	@if ! docker image inspect "$(DOCKER_IMAGE)" > /dev/null 2>&1; then \
		$(MAKE) --no-print-directory docker-build; \
	fi
	@docker run --rm -it "$(DOCKER_IMAGE)"

docker-clean: ## Remove the local Docker image
	@command -v docker > /dev/null || { printf "$(RED)Docker is not installed$(NC)\n"; exit 1; }
	@if docker image inspect "$(DOCKER_IMAGE)" > /dev/null 2>&1; then \
		docker image rm "$(DOCKER_IMAGE)"; \
	else \
		printf "$(GREEN)No local Docker image to remove$(NC)\n"; \
	fi
