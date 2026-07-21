# ═══════════════════════════════════════════════════════════════
# 󰡨 DOCKER - Interactive local package preview
# ═══════════════════════════════════════════════════════════════

DOCKER_ENV ?= arch
DOCKER_ENVS := arch ubuntu fedora

ifeq ($(filter $(DOCKER_ENV),$(DOCKER_ENVS)),)
$(error Unsupported DOCKER_ENV: $(DOCKER_ENV). Supported values: $(DOCKER_ENVS))
endif

DOCKER_IMAGE_arch := git-setup:local
DOCKER_IMAGE_ubuntu := git-setup:ubuntu-local
DOCKER_IMAGE_fedora := git-setup:fedora-local
DOCKER_ENV_LABEL_arch := Arch Linux
DOCKER_ENV_LABEL_ubuntu := Ubuntu
DOCKER_ENV_LABEL_fedora := Fedora
DOCKERFILE_arch := Dockerfile
DOCKERFILE_ubuntu := docker/ubuntu.Dockerfile
DOCKERFILE_fedora := docker/fedora.Dockerfile
DOCKER_IMAGE ?= $(DOCKER_IMAGE_$(DOCKER_ENV))
DOCKER_ENV_LABEL := $(DOCKER_ENV_LABEL_$(DOCKER_ENV))
DOCKERFILE := $(DOCKERFILE_$(DOCKER_ENV))
DOCKER_TEST_IMAGES := git-setup:local git-setup:ubuntu-local git-setup:fedora-local

.PHONY: help-docker docker-build docker-run docker-clean docker-clean-all

help-docker: ## Show Docker targets
	@printf "\n"
	@printf "$(CYAN)Docker targets$(NC)\n"
	@printf "$(CYAN)────────────────────────────────────────────────────────────────────────────────$(NC)\n"
	@printf "  make docker-build DOCKER_ENV=arch|ubuntu|fedora\n"
	@printf "                              Build the selected local image\n"
	@printf "  make docker-run DOCKER_ENV=arch|ubuntu|fedora\n"
	@printf "                              Start the selected interactive, ephemeral container\n"
	@printf "  make docker-clean DOCKER_ENV=arch|ubuntu|fedora\n"
	@printf "                              Remove the selected local image\n"
	@printf "  make docker-clean-all      Remove all local git-setup test images\n"
	@printf "\n"

docker-build: ## Build the local Docker image
	@command -v docker > /dev/null || { printf "$(RED)Docker is not installed$(NC)\n"; exit 1; }
	@docker build --file "$(DOCKERFILE)" --tag "$(DOCKER_IMAGE)" .

docker-run: ## Run git-setup interactively in an ephemeral container
	@command -v docker > /dev/null || { printf "$(RED)Docker is not installed$(NC)\n"; exit 1; }
	@$(MAKE) --no-print-directory docker-build
	@printf "\n"
	@printf "$(CYAN)󰡨  git-setup · ephemeral Docker trial$(NC)\n"
	@printf "$(CYAN)────────────────────────────────────────────────────────────────────────────────$(NC)\n"
	@printf "  $(DIM)Isolated container — your local home directory is not mounted.$(NC)\n"
	@printf "  $(DIM)Files, SSH keys, and GPG keys created inside are removed when you exit.$(NC)\n"
	@printf "\n"
	@printf "  $(BLUE)▸$(NC) Starting git-setup in $(CYAN)$(DOCKER_ENV_LABEL)$(NC)...\n"
	@printf "  $(BLUE)▸$(NC) Use your saved GitHub token only if you want to test the full setup.\n"
	@printf "\n"
	@printf "$(YELLOW)  Note: GitHub actions are external.$(NC)\n"
	@printf "$(YELLOW)  If you authenticate and complete setup, public keys may still be added to GitHub.$(NC)\n"
	@printf "\n"
	@docker run --rm -it --env GIT_SETUP_DOCKER_TRIAL=1 "$(DOCKER_IMAGE)"; status=$$?; \
		printf "\n"; \
		printf "  $(GREEN)✓$(NC) Ephemeral container removed. Local host unchanged.\n"; \
		printf "\n"; \
		exit $$status

docker-clean: ## Remove the local Docker image
	@command -v docker > /dev/null || { printf "$(RED)Docker is not installed$(NC)\n"; exit 1; }
	@case " $(DOCKER_TEST_IMAGES) " in \
		*" $(DOCKER_IMAGE) "*) ;; \
		*) printf "$(RED)Refusing to remove unmanaged Docker image: $(DOCKER_IMAGE)$(NC)\n"; exit 1;; \
	esac
	@if docker image inspect "$(DOCKER_IMAGE)" > /dev/null 2>&1; then \
		docker image rm "$(DOCKER_IMAGE)"; \
	else \
		printf "$(GREEN)No local Docker image to remove$(NC)\n"; \
	fi

docker-clean-all: ## Remove all local Docker test images
	@command -v docker > /dev/null || { printf "$(RED)Docker is not installed$(NC)\n"; exit 1; }
	@for image in $(DOCKER_TEST_IMAGES); do \
		if docker image inspect "$$image" > /dev/null 2>&1; then \
			docker image rm "$$image"; \
		else \
			printf "$(GREEN)No local Docker image to remove: $$image$(NC)\n"; \
		fi; \
	done
