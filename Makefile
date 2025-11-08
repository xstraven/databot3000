.PHONY: help install test lint clean \
	terraform.init terraform.plan terraform.apply terraform.destroy terraform.show \
	workbench.up workbench.down workbench.status \
	cloud-run.up cloud-run.down cloud-run.status \
	state.export state.show \
	dev prod

# ============================================
# Help
# ============================================

help:
	@echo "Databot3000 Project - Available Commands"
	@echo "=========================================="
	@echo ""
	@echo "Setup & Dependencies:"
	@echo "  make install                   Install Python dependencies"
	@echo "  make lint                      Run linters (pre-commit)"
	@echo "  make test                      Run tests"
	@echo "  make clean                     Clean build artifacts"
	@echo ""
	@echo "Terraform - Development Environment:"
	@echo "  make dev                       Initialize dev environment"
	@echo "  make terraform.init            Initialize terraform"
	@echo "  make terraform.plan            Plan infrastructure changes"
	@echo "  make terraform.apply           Apply infrastructure changes"
	@echo "  make terraform.destroy         Destroy all infrastructure"
	@echo "  make terraform.show            Show current state"
	@echo ""
	@echo "Ephemeral Infrastructure:"
	@echo "  make workbench.up              Spin up Workbench instance"
	@echo "  make workbench.down            Destroy Workbench instance"
	@echo "  make workbench.status          Show Workbench status"
	@echo "  make cloud-run.up              Deploy Cloud Run service"
	@echo "  make cloud-run.down            Destroy Cloud Run service"
	@echo "  make cloud-run.status          Show Cloud Run status"
	@echo ""
	@echo "Terraform State:"
	@echo "  make state.export              Export terraform state as JSON"
	@echo "  make state.show                Show current terraform state"
	@echo ""

# ============================================
# Python Setup & Testing
# ============================================

install:
	@echo "Installing Python dependencies..."
	uv sync

test:
	@echo "Running tests..."
	pytest tests/ -v

lint:
	@echo "Running linters..."
	pre-commit run --all-files

clean:
	@echo "Cleaning build artifacts..."
	find . -type d -name __pycache__ -exec rm -rf {} + 2>/dev/null || true
	find . -type f -name "*.pyc" -delete
	rm -rf .pytest_cache dist build *.egg-info .coverage htmlcov

# ============================================
# Terraform - Generic Commands
# ============================================

TF_DIR := terraform/environments/dev
TF_VARS := terraform.tfvars

terraform.init:
	@echo "Initializing Terraform..."
	cd $(TF_DIR) && terraform init

terraform.plan:
	@echo "Planning Terraform changes..."
	cd $(TF_DIR) && terraform plan

terraform.apply:
	@echo "Applying Terraform changes..."
	cd $(TF_DIR) && terraform apply

terraform.destroy:
	@echo "Destroying Terraform infrastructure..."
	cd $(TF_DIR) && terraform destroy

terraform.show:
	@echo "Showing Terraform state..."
	cd $(TF_DIR) && terraform show

# ============================================
# Development Environment Setup
# ============================================

dev: terraform.init
	@echo "Development environment initialized"
	@echo ""
	@echo "Next steps:"
	@echo "1. Edit $(TF_DIR)/$(TF_VARS) with your project details"
	@echo "2. Run: make terraform.plan"
	@echo "3. Run: make terraform.apply"
	@echo ""

prod:
	@echo "Production environment setup"
	@echo ""
	@echo "Initialize production:"
	@echo "1. Edit terraform/environments/prod/$(TF_VARS) with your project details"
	@echo "2. Run: cd terraform/environments/prod && terraform init"
	@echo "3. Run: make terraform.plan"
	@echo "4. Run: make terraform.apply"
	@echo ""

# ============================================
# Ephemeral Infrastructure Management
# ============================================

# Workbench instance targets
workbench.up:
	@echo "Spinning up Workbench instance..."
	cd $(TF_DIR) && terraform apply -target=module.workbench_dev -auto-approve

workbench.down:
	@echo "Destroying Workbench instance..."
	cd $(TF_DIR) && terraform destroy -target=module.workbench_dev -auto-approve

workbench.status:
	@echo "Workbench instance status:"
	cd $(TF_DIR) && terraform show -json | grep -A 20 "workbench_dev" || echo "Not found"

# Cloud Run targets
cloud-run.up:
	@echo "Deploying Cloud Run service..."
	cd $(TF_DIR) && terraform apply -target=module.cloud_run -auto-approve

cloud-run.down:
	@echo "Destroying Cloud Run service..."
	cd $(TF_DIR) && terraform destroy -target=module.cloud_run -auto-approve

cloud-run.status:
	@echo "Cloud Run service status:"
	cd $(TF_DIR) && terraform show -json | grep -A 20 "cloud_run" || echo "Not found"

# ============================================
# State Management
# ============================================

state.export:
	@echo "Exporting Terraform state to state.json..."
	cd $(TF_DIR) && terraform state pull > state.json
	@echo "State exported to $(TF_DIR)/state.json"

state.show:
	@echo "Current Terraform state:"
	cd $(TF_DIR) && terraform state list

# ============================================
# Build & Deployment
# ============================================

build:
	@echo "Building Python package..."
	python -m build

docker.build:
	@echo "Building Docker image..."
	docker build -t databot3000:latest .

docker.run:
	@echo "Running Docker container..."
	docker run -it databot3000:latest

# ============================================
# Development Utilities
# ============================================

.DEFAULT_GOAL := help

# Print Makefile variable for debugging
print-%:
	@echo $* = $($*)

