.PHONY: help install test lint clean \
	terraform.init terraform.plan terraform.apply terraform.destroy terraform.show \
	terraform.init-dev terraform.plan-dev terraform.apply-dev terraform.destroy-dev terraform.show-dev \
	terraform.init-prod terraform.plan-prod terraform.apply-prod terraform.destroy-prod terraform.show-prod \
	terraform.check \
	workbench.up workbench.down workbench.status \
	state.export state.show state.export-dev state.show-dev state.export-prod state.show-prod \
	dev prod build docker.build docker.run

# ============================================
# Help
# ============================================

help:
	@echo "Databot3000 Project - Available Commands"
	@echo "=========================================="
	@echo ""
	@echo "Setup & Dependencies:"
	@echo "  make install                             Install Python dependencies"
	@echo "  make lint                                Run linters (pre-commit)"
	@echo "  make test                                Run tests"
	@echo "  make clean                               Clean build artifacts"
	@echo ""
	@echo "Terraform - Development Environment:"
	@echo "  make dev                                 Initialize dev environment"
	@echo "  make terraform.init-dev                  Initialize Terraform for dev"
	@echo "  make terraform.plan-dev                  Plan dev infrastructure changes"
	@echo "  make terraform.apply-dev                 Apply dev infrastructure changes"
	@echo "  make terraform.destroy-dev               Destroy dev infrastructure"
	@echo "  make terraform.show-dev                  Show dev state"
	@echo ""
	@echo "Terraform - Production Environment:"
	@echo "  make terraform.init-prod STATE_BUCKET=...  Initialize Terraform for prod (remote state)"
	@echo "  make terraform.plan-prod                 Plan prod infrastructure changes"
	@echo "  make terraform.apply-prod                Apply prod infrastructure changes"
	@echo "  make terraform.destroy-prod CONFIRM_PROD_DESTROY=true  Destroy prod infrastructure"
	@echo "  make terraform.show-prod                 Show prod state"
	@echo "  make terraform.check                     Run fmt and validate checks locally"
	@echo ""
	@echo "Ephemeral Infrastructure (Dev):"
	@echo "  make workbench.up                        Spin up Workbench instance"
	@echo "  make workbench.down                      Destroy Workbench instance"
	@echo "  make workbench.status                    Show Workbench status"
	@echo ""
	@echo "Terraform State:"
	@echo "  make state.export-dev                    Export dev terraform state as JSON"
	@echo "  make state.show-dev                      Show current dev terraform state"
	@echo "  make state.export-prod                   Export prod terraform state as JSON"
	@echo "  make state.show-prod                     Show current prod terraform state"
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
# Terraform - Environment Variables
# ============================================

TF_DEV_DIR := terraform/environments/dev
TF_PROD_DIR := terraform/environments/prod
STATE_BUCKET ?=
CONFIRM_PROD_DESTROY ?= false

# ============================================
# Terraform - Dev
# ============================================

terraform.init-dev:
	@echo "Initializing Terraform (dev)..."
	cd $(TF_DEV_DIR) && terraform init

terraform.plan-dev:
	@echo "Planning Terraform changes (dev)..."
	cd $(TF_DEV_DIR) && terraform plan

terraform.apply-dev:
	@echo "Applying Terraform changes (dev)..."
	cd $(TF_DEV_DIR) && terraform apply

terraform.destroy-dev:
	@echo "Destroying Terraform infrastructure (dev)..."
	cd $(TF_DEV_DIR) && terraform destroy

terraform.show-dev:
	@echo "Showing Terraform state (dev)..."
	cd $(TF_DEV_DIR) && terraform show

# ============================================
# Terraform - Prod
# ============================================

terraform.init-prod:
	@if [ -z "$(STATE_BUCKET)" ]; then \
		echo "STATE_BUCKET is required. Example: make terraform.init-prod STATE_BUCKET=my-terraform-state-bucket"; \
		exit 1; \
	fi
	@echo "Initializing Terraform (prod) with remote state bucket $(STATE_BUCKET)..."
	cd $(TF_PROD_DIR) && terraform init -reconfigure -backend-config="bucket=$(STATE_BUCKET)"

terraform.plan-prod:
	@echo "Planning Terraform changes (prod)..."
	cd $(TF_PROD_DIR) && terraform plan

terraform.apply-prod:
	@echo "Applying Terraform changes (prod)..."
	cd $(TF_PROD_DIR) && terraform apply

terraform.destroy-prod:
	@if [ "$(CONFIRM_PROD_DESTROY)" != "true" ]; then \
		echo "Refusing to destroy prod. Re-run with CONFIRM_PROD_DESTROY=true"; \
		exit 1; \
	fi
	@echo "Destroying Terraform infrastructure (prod)..."
	cd $(TF_PROD_DIR) && terraform destroy

terraform.show-prod:
	@echo "Showing Terraform state (prod)..."
	cd $(TF_PROD_DIR) && terraform show

terraform.check:
	@echo "Checking Terraform formatting..."
	terraform fmt -check -recursive terraform
	@echo "Validating Terraform (dev)..."
	cd $(TF_DEV_DIR) && terraform init -backend=false && terraform validate
	@echo "Validating Terraform (prod)..."
	cd $(TF_PROD_DIR) && terraform init -backend=false && terraform validate

# Legacy aliases default to dev
terraform.init: terraform.init-dev
terraform.plan: terraform.plan-dev
terraform.apply: terraform.apply-dev
terraform.destroy: terraform.destroy-dev
terraform.show: terraform.show-dev

# ============================================
# Development Environment Setup
# ============================================

dev: terraform.init-dev
	@echo "Development environment initialized"
	@echo ""
	@echo "Next steps:"
	@echo "1. Edit $(TF_DEV_DIR)/terraform.tfvars with your project details"
	@echo "2. Run: make terraform.plan-dev"
	@echo "3. Run: make terraform.apply-dev"
	@echo ""

prod:
	@echo "Production environment setup"
	@echo ""
	@echo "Initialize production:"
	@echo "1. Edit $(TF_PROD_DIR)/terraform.tfvars with your project details"
	@echo "2. Run: make terraform.init-prod STATE_BUCKET=your-terraform-state-bucket"
	@echo "3. Run: make terraform.plan-prod"
	@echo "4. Run: make terraform.apply-prod"
	@echo ""

# ============================================
# Ephemeral Infrastructure Management (Dev)
# ============================================

workbench.up:
	@echo "Spinning up Workbench instance..."
	cd $(TF_DEV_DIR) && terraform apply -target=module.workbench_dev -auto-approve

workbench.down:
	@echo "Destroying Workbench instance..."
	cd $(TF_DEV_DIR) && terraform destroy -target=module.workbench_dev -auto-approve

workbench.status:
	@echo "Workbench instance status:"
	cd $(TF_DEV_DIR) && terraform show -json | grep -A 20 "workbench_dev" || echo "Not found"

# ============================================
# State Management
# ============================================

state.export-dev:
	@echo "Exporting dev Terraform state to state.json..."
	cd $(TF_DEV_DIR) && terraform state pull > state.json
	@echo "State exported to $(TF_DEV_DIR)/state.json"

state.show-dev:
	@echo "Current dev Terraform state:"
	cd $(TF_DEV_DIR) && terraform state list

state.export-prod:
	@echo "Exporting prod Terraform state to state.json..."
	cd $(TF_PROD_DIR) && terraform state pull > state.json
	@echo "State exported to $(TF_PROD_DIR)/state.json"

state.show-prod:
	@echo "Current prod Terraform state:"
	cd $(TF_PROD_DIR) && terraform state list

# Legacy aliases default to dev
state.export: state.export-dev
state.show: state.show-dev

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
