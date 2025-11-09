# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Databot3000 is a personal infrastructure management system for AI projects on Google Cloud Platform (GCP). It follows a **state-driven architecture** where Terraform provisions infrastructure and Python code automatically discovers resources from Terraform state files—no manual configuration required.

### Core Philosophy

- Infrastructure resources are defined in Terraform modules
- Terraform state files are the source of truth
- Python package reads state files to discover resources at runtime
- Users interact with infrastructure through simple Python APIs

## Development Commands

### MCP servers
The following mcp servers are configured and should be used accordingly:
- context7 for access to up-tp-date documentation on software packages as well as gcloud - use this before resorting to a websearch
- neon as a serverless postgres provider

### Setup & Testing

```bash
make install          # Install dependencies with uv
make test            # Run pytest test suite
make lint            # Run pre-commit linters
make clean           # Clean build artifacts
pytest tests/test_app.py -v  # Run specific test file
```

### Terraform Operations

The default working directory is `terraform/environments/dev/`:

```bash
make dev                  # Initialize dev environment (terraform init)
make terraform.plan       # Plan infrastructure changes
make terraform.apply      # Apply infrastructure changes
make terraform.destroy    # Destroy all infrastructure
make state.export         # Export state as JSON
make state.show          # List terraform state resources
```

### Ephemeral Resources

```bash
make workbench.up         # Spin up Vertex AI Workbench
make workbench.down       # Destroy Workbench (saves cost)
make workbench.status     # Check Workbench status
make cloud-run.up         # Deploy Cloud Run service
make cloud-run.down       # Destroy Cloud Run service
```

## Architecture

### Directory Structure

```
databot3000/
├── terraform/
│   ├── modules/           # Reusable Terraform modules
│   │   ├── gcp-apis/     # Enable GCP APIs
│   │   ├── storage/      # Cloud Storage buckets
│   │   ├── service-account/  # IAM service accounts
│   │   ├── workbench/    # Vertex AI Workbench instances
│   │   └── cloud-run/    # Cloud Run services
│   └── environments/
│       ├── dev/          # Development environment config
│       └── prod/         # Production environment config
├── src/databot/
│   ├── core/             # State loader (reads terraform.tfstate)
│   ├── storage/          # Storage bucket interface
│   ├── auth/             # Service account authentication
│   └── config.py         # Configuration management
└── tests/                # Test suite
```

### State-Driven Discovery Flow

1. **Terraform** creates GCP resources and writes `terraform.tfstate`
2. **StateLoader** (`src/databot/core/state_loader.py`) parses the state file
3. **DatabotConfig** (`src/databot/config.py`) discovers infrastructure from state
4. **storage()** function (`src/databot/storage/__init__.py`) returns bucket object
5. User code interacts with discovered resources through Python APIs

### Key Python Components

**StateLoader** - Low-level state file parser
- Reads `terraform.tfstate` JSON files
- Provides methods like `get_outputs()`, `get_google_storage_buckets()`, `get_google_service_accounts()`
- Caches parsed data for performance

**DatabotConfig** - High-level configuration management
- Auto-discovers state files in standard locations
- Searches: `terraform/environments/{env}/terraform.tfstate`, current directory, `terraform/live/production/`
- Extracts environment-specific configuration

**storage(environment)** - Main entry point
- Discovers bucket for given environment from Terraform state
- Returns authenticated `Bucket` object
- Matches bucket by environment name in output keys

**Bucket** - Storage operations wrapper
- Methods: `list_files()`, `upload_file()`, `download_file()`, `upload_json()`, `download_json()`
- Uses Google Cloud Storage client libraries
- Handles authentication via application default credentials

### Terraform Module Pattern

All modules follow this structure:
- `main.tf` - Resource definitions
- `variables.tf` - Input variables
- `outputs.tf` - Output values (consumed by Python)
- `versions.tf` - Provider requirements

Modules are **composition-based**: environments compose modules in their `main.tf` rather than using inheritance.

## Development Environment Setup

### Dev vs Prod Environments

**Dev** (`terraform/environments/dev/`)
- Ephemeral resources (`force_destroy = true` on buckets)
- Service accounts with key creation enabled
- 90-day auto-delete lifecycle on storage
- Workbench defaults to STOPPED state for cost savings
- Resources can be destroyed freely with `make workbench.down`

**Prod** (`terraform/environments/prod/`)
- Persistent resources (deletion protection)
- Versioned storage buckets
- Service accounts without keys (use Workload Identity)
- Archive bucket with cold storage migration

### Working with Terraform State

The Python package expects Terraform state at specific paths:
- `terraform/environments/dev/terraform.tfstate` for dev
- `terraform/environments/prod/terraform.tfstate` for prod

To make infrastructure discoverable, ensure Terraform outputs include:
```hcl
output "dev_data_bucket" {
  value = module.bucket_dev_data.bucket_name
}

output "service_account_email" {
  value = module.sa_dev_databot.service_account_email
}
```

The Python code discovers resources by:
1. Looking for outputs containing "bucket" in the key name
2. Matching environment name to bucket output keys
3. Falling back to first available bucket if no match

## Common Patterns

### Adding a New Terraform Module

1. Create directory in `terraform/modules/{module_name}/`
2. Add `main.tf`, `variables.tf`, `outputs.tf`, `versions.tf`
3. Use module in environment: `module "name" { source = "../../modules/{module_name}" }`
4. Add outputs to environment `main.tf` so Python can discover resources
5. Test in dev environment first

### Adding Infrastructure Discovery to Python

1. Add parsing logic to `StateLoader` in `src/databot/core/state_loader.py`
2. Add convenience method to `DatabotConfig` in `src/databot/config.py`
3. Create wrapper class (like `Bucket`) in appropriate module
4. Add entry point function (like `storage()`) for discovery
5. Update `src/databot/__init__.py` exports

### Working with Ephemeral Resources

Workbenches and Cloud Run services are designed to be spun up/down:
```bash
make workbench.up     # Creates Workbench (10+ min)
# Do development work
make workbench.down   # Destroys to avoid charges
```

Use targeted Terraform operations for partial updates:
```bash
cd terraform/environments/dev
terraform apply -target=module.workbench_dev -auto-approve
terraform destroy -target=module.workbench_dev -auto-approve
```

## Authentication

Python code uses **Application Default Credentials**:
```bash
gcloud auth application-default login
```

In dev environment, service accounts can have JSON keys created. The keys are exported via Terraform outputs but **not recommended for production**.

Production should use Workload Identity Federation instead of service account keys.

## Testing Philosophy

- Tests in `tests/` directory using pytest
- Unit tests should mock Terraform state files (JSON fixtures)
- Integration tests can use actual GCP resources in dev environment
- Run tests with `make test` before committing

## Important Notes

- The Makefile defaults to `terraform/environments/dev/` for TF commands
- State files contain sensitive data—ensure `.gitignore` excludes `*.tfstate`
- Workbench GPU provisioning requires `notebooks.googleapis.com` API enabled
- Bucket names must be globally unique (use `${project_id}-` prefix)
- Python package requires `uv` for dependency management (not pip)
- State file discovery searches multiple paths—explicitly set `state_file` in `DatabotConfig()` if needed

## GCP-Specific Considerations

- Project IDs must be configured in `terraform/environments/{env}/terraform.tfvars`
- Most modules require APIs enabled via `gcp-apis` module first
- Service account creation requires `iam.googleapis.com` API
- Workbench instances take 10+ minutes to provision
- Cloud Run requires container images in GCR/Artifact Registry
- Regional resources default to `us-central1`
