# Databot3000

[He belongs to the cloud now](https://www.youtube.com/watch?v=-HUh9Sg7_eg)

## What is this?

Databot3000 is a personal infrastructure management system for AI projects on Google Cloud Platform (GCP). It combines:

- **Terraform Infrastructure** - Modular, reusable IaC for GCP resources
- **Python Utilities** - Zero-config access to infrastructure from Python
- **Makefile Automation** - Simple commands for common operations

Use it to spin up ephemeral resources (VMs, Workbenches) for development and manage persistent storage buckets for data.

### Key Features

✨ **Easy to Use**: `from databot import storage; bucket = storage('dev')`
🚀 **Modular Infrastructure**: Reusable Terraform modules for storage, compute, networking
⚡ **Quick Iteration**: Spin up/down ephemeral resources with `make` commands
🔐 **Secure by Default**: Auto-generated service accounts, per-environment isolation
📦 **State-Driven**: Python discovers infrastructure from Terraform state automatically

### Quick Start

```bash
# 1. Setup
make install
make dev

# 2. Edit terraform configuration
cd terraform/environments/dev
cp terraform.tfvars.example terraform.tfvars
# ... edit with your GCP project details ...

# 3. Deploy infrastructure
make terraform.apply

# 4. Use from Python
python -c "
from databot import storage
bucket = storage('dev')
bucket.upload_json({'hello': 'world'}, 'test.json')
"
```

### Use Cases

1. **Spin up ephemeral workbenches** - `make workbench.up` / `make workbench.down`
2. **Manage storage buckets** - Upload/download files from Python
3. **Discover infrastructure** - Automatically find buckets, service accounts, etc.
4. **Cost optimization** - Easily destroy resources to avoid recurring costs

## Documentation

- **[IMPLEMENTATION_SUMMARY.md](IMPLEMENTATION_SUMMARY.md)** - Overview of the rework and architecture
- **[terraform/README.md](terraform/README.md)** - Terraform infrastructure guide
- **[src/databot/README.md](src/databot/README.md)** - Python package API and usage

## Project Structure

```
databot3000/
├── terraform/                 # Infrastructure-as-Code
│   ├── modules/              # Reusable Terraform modules
│   └── environments/          # Dev and prod configurations
├── src/databot/              # Python package
│   ├── storage/              # Cloud Storage utilities
│   ├── auth/                 # Authentication helpers
│   └── core/                 # Core state management
├── tests/                    # Test suite
├── Makefile                  # Automation commands
├── pyproject.toml            # Python configuration
└── README.md                 # This file
```

## Makefile Commands

### Setup & Testing

```bash
make install                   # Install dependencies
make test                      # Run tests
make lint                      # Run linters
make clean                     # Clean artifacts
```

### Infrastructure Management

```bash
make dev                       # Initialize dev environment
make terraform.plan            # Preview changes
make terraform.apply           # Deploy infrastructure
make terraform.destroy         # Destroy all resources
```

### Ephemeral Resources

```bash
make workbench.up              # Spin up Workbench
make workbench.down            # Destroy Workbench
make workbench.status          # Show status
```

### State Operations

```bash
make state.export              # Export state as JSON
make state.show                # List resources
```

## Python API

### Storage Bucket Access

```python
from databot import storage

# Discover and connect to dev bucket
bucket = storage('dev')

# List files
files = bucket.list_files()

# Upload
bucket.upload_file('local.txt', 'remote.txt')

# Download
bucket.download_file('remote.txt', 'local.txt')

# JSON operations
bucket.upload_json({'key': 'value'}, 'data.json')
data = bucket.download_json('data.json')
```

### Infrastructure Discovery

```python
from databot import DatabotConfig, StateLoader

# High-level config
config = DatabotConfig(environment='dev')
buckets = config.get_bucket_names()
sa_email = config.get_service_account_email()

# Low-level state access
loader = StateLoader('terraform.tfstate')
outputs = loader.get_outputs()
```

## Environment Configuration

### Development (`terraform/environments/dev/`)

- Ephemeral resources (easily destroyed)
- Auto-generated service accounts with keys
- Storage buckets with 90-day auto-delete
- Vertex AI Workbench (STOPPED by default for cost savings)

### Production (`terraform/environments/prod/`)

- Persistent resources (safe from accidental deletion)
- Service accounts (no keys created)
- Versioned storage buckets
- Archive bucket with auto-archival to cold storage

## Requirements

- **Terraform** >= 1.0
- **Python** >= 3.11
- **Google Cloud Project** with billing enabled
- **gcloud CLI** for authentication

## Getting Started

1. **Clone and setup**
   ```bash
   git clone <repo>
   cd databot3000
   make install
   ```

2. **Configure GCP credentials**
   ```bash
   gcloud auth application-default login
   gcloud config set project YOUR_PROJECT_ID
   ```

3. **Initialize development environment**
   ```bash
   make dev
   cd terraform/environments/dev
   cp terraform.tfvars.example terraform.tfvars
   # Edit terraform.tfvars with your details
   ```

4. **Deploy infrastructure**
   ```bash
   make terraform.plan
   make terraform.apply
   ```

5. **Use from Python**
   ```python
   from databot import storage
   bucket = storage('dev')
   # Use bucket...
   ```

## Troubleshooting

### State file not found

```bash
cd terraform/environments/dev
terraform apply
```

### Permission denied

```bash
gcloud auth application-default login
```

### Workbench creation timeout

```bash
gcloud services enable notebooks.googleapis.com
```

For more help, see [terraform/README.md](terraform/README.md#troubleshooting) or [src/databot/README.md](src/databot/README.md#troubleshooting).

## Architecture

The project uses a **state-driven architecture**:

1. **Terraform** provisions GCP resources and outputs configuration
2. **State files** contain infrastructure metadata
3. **Python package** reads state files to discover resources
4. **User code** accesses infrastructure through simple Python APIs

No manual configuration needed - the package automatically discovers what's available!

## Roadmap

- ✅ Storage bucket management
- ✅ Service account generation
- ✅ Ephemeral workbench support
- 📋 Vertex AI compute module
- 📋 Modal Labs integration
- 📋 Monitoring and logging
- 📋 Async support

## Future Work

See [IMPLEMENTATION_SUMMARY.md](IMPLEMENTATION_SUMMARY.md#future-enhancements) for planned features and next steps.

## Contributing

When adding features:

1. Create Terraform modules in `terraform/modules/`
2. Add Python utilities in `src/databot/`
3. Update documentation
4. Add tests and run `make test`
5. Update `IMPLEMENTATION_SUMMARY.md`

## References

- [Terraform AWS Docs](https://www.terraform.io/docs)
- [Google Cloud Terraform Provider](https://registry.terraform.io/providers/hashicorp/google/latest/docs)
- [GCP Best Practices](https://cloud.google.com/docs/terraform/best-practices)

---

**Version**: 0.1.0
**Status**: Active Development
**Last Updated**: November 2024