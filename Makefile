# Variables
UV ?= uv
SHELL = /bin/bash

# Default target
.DEFAULT_GOAL := help

.PHONY: help
help: ## Show the help messages for all targets
	@echo "Usage: make <target>"
	@echo ""
	@echo "Targets:"
	@grep -E '^[a-zA-Z_-]+:.*## .*$$' Makefile | \
	awk 'BEGIN {FS = ":.*## "}; {printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2}'

.PHONY: install
install: ## Install Python dependencies
	$(UV) sync --locked

.PHONY: format
format: ## Format Terraform configuration files
	@if command -v terraform >/dev/null 2>&1; then \
		terraform fmt -recursive; \
	fi

.PHONY: test
test: ## Run the tests
	$(UV) run pytest

.PHONY: setup-hooks
setup-hooks: ## Install Git hooks (pre-commit and pre-push)
	$(UV) run pre-commit install --hook-type pre-commit
	$(UV) run pre-commit install --hook-type pre-push
	$(UV) run pre-commit install

.PHONY: test-hooks
test-hooks: ## Run Git hooks manually on all files
	$(UV) run pre-commit run --all-files --show-diff-on-failure
