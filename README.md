# Databot3000

[He belongs to the cloud now](https://www.youtube.com/watch?v=-HUh9Sg7_eg)

> **Note**: This is my personal infrastructure management system, made public as a portfolio showcase. It demonstrates patterns for infrastructure-as-code, state-driven architecture, and zero-config service discovery.

## What is this?

A personal infrastructure management system for AI projects that combines:

- **Terraform Infrastructure** - Modular IaC for GCP, provisioning storage, compute, and networking resources
- **Python Utilities** - Zero-config access to infrastructure via state-driven discovery
- **Neon PostgreSQL** - Serverless database integration with async client
- **Makefile Automation** - Simple commands for managing ephemeral and persistent resources

### Key Features

✨ **Zero Configuration**: `from databot import storage; bucket = storage('dev')` - no manual config needed
🚀 **Modular Infrastructure**: Reusable Terraform modules for storage, service accounts, workbenches, and cloud run
⚡ **Ephemeral Resources**: Spin up/down expensive compute with `make workbench.up` / `make workbench.down`
🔐 **Secure by Default**: Key creation disabled by default, private Workbench networking, hardened production buckets
📦 **State-Driven Discovery**: Python automatically discovers infrastructure from Terraform state files

## Architecture

The project uses a **state-driven architecture** where infrastructure discovery happens automatically:

1. **Terraform** provisions GCP resources → writes `terraform.tfstate`
2. **State files** contain infrastructure metadata (bucket names, service accounts, etc.)
3. **Python package** reads state files at runtime to discover available resources
4. **User code** accesses infrastructure through simple APIs with zero manual configuration

This eliminates the need for configuration files or hard-coded resource names. The Python code always knows what infrastructure exists by reading Terraform's state.

## Project Structure

```
databot3000/
├── terraform/
│   ├── modules/              # Reusable Terraform modules
│   │   ├── gcp-apis/         # Enable GCP APIs
│   │   ├── storage/          # Cloud Storage buckets
│   │   ├── service-account/  # IAM service accounts
│   │   ├── workbench/        # Vertex AI Workbench (GPU instances)
│   │   └── cloud-run/        # Serverless containers
│   └── environments/
│       ├── dev/              # Ephemeral development resources
│       └── prod/             # Persistent production resources
├── src/databot/
│   ├── core/                 # State loader (reads terraform.tfstate)
│   ├── storage/              # GCS bucket interface
│   ├── neondb/               # Async PostgreSQL client
│   ├── auth/                 # Service account authentication
│   └── config.py             # Configuration discovery
└── tests/                    # Pytest test suite
```

## Quick Example

```python
# Storage: discovered from Terraform state
from databot import storage
bucket = storage('dev')
bucket.upload_json({'data': [1, 2, 3]}, 'results.json')

# Database: async PostgreSQL with Neon
from databot import neondb
async with neondb("myproject", "neondb") as db:
    users = await db.fetch("SELECT * FROM users WHERE active = $1", True)
```

## Makefile Commands

```bash
# Setup
make install                   # Install dependencies (uv)
make test                      # Run pytest suite

# Infrastructure (Dev)
make dev                       # Initialize dev environment
make terraform.plan-dev        # Preview dev infrastructure changes
make terraform.apply-dev       # Deploy dev infrastructure

# Infrastructure (Prod)
make terraform.init-prod STATE_BUCKET=your-terraform-state-bucket
make terraform.plan-prod
make terraform.apply-prod

# Ephemeral Resources (Dev cost optimization)
make workbench.up              # Spin up Vertex AI Workbench
make workbench.down            # Destroy Workbench to save $$$
```

## Environment Design

**Dev** (`terraform/environments/dev/`):
- Ephemeral resources (`force_destroy = true`)
- 90-day auto-delete on storage
- Workbench defaults to STOPPED state
- Service account keys disabled by default (explicit override required)
- Workbench defaults to private IP

**Prod** (`terraform/environments/prod/`):
- Persistent resources with deletion protection
- Versioned storage buckets
- Archive bucket with cold storage migration
- Public access prevention enforced on buckets
- Remote GCS Terraform backend required

## Technology Stack

- **Infrastructure**: Terraform >= 1.6, GCP (Cloud Storage, Vertex AI, Cloud Run)
- **Language**: Python >= 3.11, asyncpg for PostgreSQL
- **Database**: Neon serverless PostgreSQL
- **Tooling**: uv for dependency management, pytest for testing
- **Compute**: Modal Labs for ad-hoc serverless workloads (planned)

## API Examples

### Storage Discovery

```python
from databot import storage

# Automatically discovers bucket from terraform state
bucket = storage('dev')
bucket.upload_file('data.csv', 'datasets/data.csv')
files = bucket.list_files(prefix='datasets/')
```

### Database Access

```python
from databot import neondb

async with neondb("databot") as db:
    # Insert with parameterized queries
    await db.execute(
        "INSERT INTO logs (event, timestamp) VALUES ($1, $2)",
        "model_trained", datetime.now()
    )

    # Fetch with filters
    recent = await db.fetch(
        "SELECT * FROM logs WHERE timestamp > $1",
        datetime.now() - timedelta(days=7)
    )
```

### Infrastructure Discovery

```python
from databot import DatabotConfig, StateLoader

# High-level discovery
config = DatabotConfig(environment='dev')
buckets = config.get_bucket_names()
service_account = config.get_service_account_email()

# Low-level state access
loader = StateLoader('terraform/environments/dev/terraform.tfstate')
outputs = loader.get_outputs()
workbenches = loader.get_google_workbench_instances()
```

## Documentation

- **[CLAUDE.md](CLAUDE.md)** - Development guide for Claude Code
- **[terraform/README.md](terraform/README.md)** - Terraform modules and usage
- **[src/databot/README.md](src/databot/README.md)** - Python API reference

## Requirements

- Terraform >= 1.6
- Python >= 3.11
- Google Cloud Project with billing
- gcloud CLI for authentication

---

**Version**: 0.1.0
**Status**: Active Development
**Last Updated**: November 2025
