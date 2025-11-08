# Databot3000 - Quick Start Guide

## 5-Minute Setup

### 1. Install Dependencies
```bash
make install
```

### 2. Initialize Development Environment
```bash
make dev
cd terraform/environments/dev
cp terraform.tfvars.example terraform.tfvars
```

Edit `terraform.tfvars` with your GCP details:
```hcl
project_id          = "your-gcp-project-id"
region              = "us-central1"
zone                = "us-central1-a"
user_email          = "your-email@example.com"
billing_account_id  = "your-billing-account-id"
```

### 3. Deploy Infrastructure
```bash
cd ../..  # Back to project root
make terraform.apply
```

### 4. Export State (for Python discovery)
```bash
make state.export
```

### 5. Test From Python
```bash
python << 'EOF'
from databot import storage

# Discover and access the dev bucket
bucket = storage('dev')

# Upload JSON
bucket.upload_json({"test": "data"}, "test.json")

# Download JSON
data = bucket.download_json("test.json")
print(f"Success! {data}")

# Cleanup
bucket.delete_file("test.json")
EOF
```

## Common Commands

### Manage Infrastructure
```bash
make terraform.plan        # Preview changes
make terraform.apply       # Deploy changes
make terraform.destroy     # Destroy all infrastructure
```

### Spin Up/Down Ephemeral Resources
```bash
make workbench.up         # Create Workbench (may take 5-10 mins)
make workbench.down       # Destroy Workbench
make workbench.status     # Check status
```

### Python Operations
```bash
# Upload files
python -c "
from databot import storage
bucket = storage('dev')
bucket.upload_file('data.csv', 'uploads/data.csv')
"

# Download files
python -c "
from databot import storage
bucket = storage('dev')
bucket.download_file('uploads/data.csv', 'data.csv')
"

# List files
python -c "
from databot import storage
bucket = storage('dev')
print(bucket.list_files())
"
```

### Testing & Development
```bash
make test              # Run tests
make lint              # Run linters
make clean             # Clean artifacts
```

## Python API Cheat Sheet

### Storage Bucket Operations
```python
from databot import storage

# Connect to bucket
bucket = storage('dev')  # or 'prod'

# List files
files = bucket.list_files()                    # All files
files = bucket.list_files(prefix='uploads/')   # With prefix
files = bucket.list_files(recursive=False)     # Top-level only

# Upload
bucket.upload_file('local.txt', 'remote.txt')
bucket.upload_data(b'raw bytes', 'file.bin')
bucket.upload_json({'key': 'value'}, 'data.json')

# Download
bucket.download_file('remote.txt', 'local.txt')
data = bucket.download_data('file.bin')
obj = bucket.download_json('data.json')

# Delete
bucket.delete_file('file.txt')
count = bucket.delete_prefix('temp/')  # Delete all with prefix

# Share
url = bucket.get_url('report.pdf', expiration=3600)
```

### Infrastructure Discovery
```python
from databot import DatabotConfig, StateLoader

# High-level access
config = DatabotConfig(environment='dev')
buckets = config.get_bucket_names()
sa_email = config.get_service_account_email()

# Low-level access
loader = StateLoader('terraform/environments/dev/terraform.tfstate')
outputs = loader.get_outputs()
resources = loader.get_resources()
```

## Troubleshooting

### "State file not found"
```bash
cd terraform/environments/dev
terraform apply
```

### "Permission denied"
```bash
gcloud auth application-default login
```

### "Workbench creation timeout"
```bash
gcloud services enable notebooks.googleapis.com
```

### "Module not found" for databot
```bash
make install
```

## Documentation Links

- **[README.md](README.md)** - Project overview and architecture
- **[IMPLEMENTATION_SUMMARY.md](IMPLEMENTATION_SUMMARY.md)** - Detailed rework documentation
- **[terraform/README.md](terraform/README.md)** - Terraform infrastructure guide
- **[src/databot/README.md](src/databot/README.md)** - Python API reference

## Environment Variables

```bash
# Required for GCP authentication
export GOOGLE_APPLICATION_CREDENTIALS=/path/to/key.json

# Optional
export GOOGLE_CLOUD_PROJECT=your-project-id
```

## Next Steps

1. **Deploy infrastructure**: `make terraform.apply`
2. **Start using buckets**: `from databot import storage; bucket = storage('dev')`
3. **Spin up workbench**: `make workbench.up`
4. **Monitor costs**: Check GCP Console Billing

## Tips & Tricks

### Save costs on Workbench
```bash
# Workbench defaults to STOPPED state
# To start it, edit terraform.tfvars:
# workbench_desired_state = "ACTIVE"

make terraform.apply
# ... do your work ...

# Then set back to STOPPED and destroy
make terraform.apply
make workbench.down
```

### Batch upload files
```python
from pathlib import Path
from databot import storage

bucket = storage('dev')

# Upload all CSV files
for csv_file in Path('.').glob('*.csv'):
    bucket.upload_file(str(csv_file), f'uploads/{csv_file.name}')
    print(f"Uploaded {csv_file.name}")
```

### Data pipeline
```python
from databot import storage
import json

bucket = storage('dev')

# Download config
config = bucket.download_json('config.json')

# Process (your logic here)
results = process_data(config['input'])

# Upload results
bucket.upload_json(results, 'output.json')
print("Pipeline complete!")
```

## Support

- Check [terraform/README.md](terraform/README.md#troubleshooting) for Terraform issues
- Check [src/databot/README.md](src/databot/README.md#troubleshooting) for Python issues
- See [IMPLEMENTATION_SUMMARY.md](IMPLEMENTATION_SUMMARY.md) for architecture details

---

**Version**: 0.1.0
**Last Updated**: November 2024
