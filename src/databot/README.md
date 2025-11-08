# Databot Python Package

The `databot` package provides Python utilities for discovering and accessing infrastructure managed by Terraform.

## Overview

Databot discovers GCP resources (storage buckets, service accounts, workbenches, etc.) from Terraform state files and provides convenient Python interfaces to interact with them.

### Key Components

1. **StateLoader** - Reads and parses terraform.tfstate files
2. **DatabotConfig** - Configuration management and state discovery
3. **storage()** - Main entry point to access Cloud Storage buckets
4. **ServiceAccountAuth** - Handles Google Cloud authentication
5. **Bucket** - Wrapper around GCS bucket operations

## Installation

The package is installed with project dependencies:

```bash
make install
```

Or manually:

```bash
uv sync
```

## Quick Start

### Basic Storage Access

```python
from databot import storage

# Discover and connect to the dev bucket
bucket = storage('dev')

# List files
files = bucket.list_files()

# Upload a file
bucket.upload_file('local.txt', 'remote.txt')

# Download a file
bucket.download_file('remote.txt', 'local.txt')

# Upload JSON
bucket.upload_json({'key': 'value'}, 'data.json')

# Download JSON
data = bucket.download_json('data.json')
```

### Advanced: State Discovery

```python
from databot import StateLoader, DatabotConfig

# Load configuration for dev environment
config = DatabotConfig(environment='dev')

# Get all bucket names
buckets = config.get_bucket_names()

# Get service account email
sa_email = config.get_service_account_email()

# Load state directly
loader = StateLoader('terraform/environments/dev/terraform.tfstate')

# Get all outputs
outputs = loader.get_outputs()

# Get specific resources
workbenches = loader.get_google_workbench_instances()
```

## Architecture

### How It Works

1. **Terraform State Discovery**
   - Looks for `terraform.tfstate` in standard locations
   - Can be in current directory or `terraform/environments/{env}/`

2. **Configuration Loading**
   - `DatabotConfig` parses the state file
   - Extracts bucket names, service accounts, and other outputs

3. **Resource Access**
   - `storage()` function discovers the appropriate bucket
   - Automatically handles authentication
   - Returns a `Bucket` object for operations

### State File Format

Terraform state files are JSON with this structure:

```json
{
  "version": 4,
  "terraform_version": "1.0.0",
  "outputs": {
    "dev_data_bucket": {
      "value": "project-dev-data"
    },
    "service_account_email": {
      "value": "dev-databot@project.iam.gserviceaccount.com"
    }
  },
  "resources": [
    {
      "type": "google_storage_bucket",
      "instances": [...]
    }
  ]
}
```

## API Reference

### storage(environment: str = "dev") -> Bucket

Discover and access a storage bucket.

**Args:**
- `environment`: Environment name (dev, prod, staging)

**Returns:** `Bucket` object

**Raises:**
- `RuntimeError`: If state not found or no bucket configured
- `FileNotFoundError`: If local files don't exist

**Example:**
```python
bucket = storage('dev')
bucket.upload_file('data.csv', 's3://bucket/data.csv')
```

---

### Bucket Operations

#### list_files(prefix: str = "", recursive: bool = False) -> List[str]

List files in bucket.

```python
# List all files
all_files = bucket.list_files(recursive=True)

# List with prefix
csv_files = bucket.list_files(prefix="data/", recursive=True)

# List top-level only
top_level = bucket.list_files()
```

#### upload_file(local_path: str, remote_path: str) -> None

Upload a file.

```python
bucket.upload_file('local/data.csv', 'remote/data.csv')
```

#### download_file(remote_path: str, local_path: str) -> None

Download a file.

```python
bucket.download_file('remote/data.csv', 'local/data.csv')
```

#### upload_json(obj: dict, remote_path: str) -> None

Upload a Python dictionary as JSON.

```python
bucket.upload_json(
    {"timestamp": "2024-01-01", "value": 42},
    "results.json"
)
```

#### download_json(remote_path: str) -> dict

Download JSON file as dictionary.

```python
data = bucket.download_json('results.json')
print(data['value'])  # 42
```

#### delete_file(remote_path: str) -> None

Delete a file.

```python
bucket.delete_file('old_data.csv')
```

#### delete_prefix(prefix: str) -> int

Delete all files with a prefix.

```python
deleted_count = bucket.delete_prefix('temp/')
print(f"Deleted {deleted_count} files")
```

#### get_url(remote_path: str, expiration: int = 3600) -> str

Get a signed URL for sharing.

```python
url = bucket.get_url('report.pdf', expiration=7200)
# Share this URL for 2 hours
```

---

### DatabotConfig

Configuration management and state discovery.

```python
config = DatabotConfig(environment='dev')

# Get outputs
outputs = config.get_outputs()

# Get specific output
bucket_name = config.get_output('dev_data_bucket')

# Get all buckets
buckets = config.get_bucket_names()

# Get service account
sa_email = config.get_service_account_email()
```

---

### StateLoader

Low-level state file parser.

```python
from databot import StateLoader

loader = StateLoader('terraform.tfstate')

# Get all outputs
outputs = loader.get_outputs()

# Get specific output
value = loader.get_output('my_output')

# Get resources by type
buckets = loader.get_resource_instances('google_storage_bucket')

# Get Google service accounts
accounts = loader.get_google_service_accounts()

# Get Workbench instances
workbenches = loader.get_google_workbench_instances()
```

---

### ServiceAccountAuth

Authentication handling.

```python
from databot import ServiceAccountAuth

# With key file
auth = ServiceAccountAuth(
    service_account_email='sa@project.iam.gserviceaccount.com',
    key_file='/path/to/key.json'
)

# From state
auth = ServiceAccountAuth.from_state('sa@project.iam.gserviceaccount.com')

# Get credentials
credentials = auth.get_credentials()
```

## Usage Patterns

### Pattern 1: Simple File Operations

```python
from databot import storage

bucket = storage('dev')
bucket.upload_file('report.csv', 'reports/report.csv')
```

### Pattern 2: Batch Operations

```python
from pathlib import Path
from databot import storage

bucket = storage('dev')

# Upload all CSV files
for csv_file in Path('.').glob('*.csv'):
    bucket.upload_file(str(csv_file), f'uploads/{csv_file.name}')
```

### Pattern 3: Data Pipeline

```python
from databot import storage
import json

bucket = storage('dev')

# Download input
input_data = bucket.download_json('input/config.json')

# Process
processed = process_data(input_data)

# Upload results
bucket.upload_json(processed, 'output/results.json')
```

### Pattern 4: Infrastructure Discovery

```python
from databot import DatabotConfig, StateLoader

config = DatabotConfig(environment='prod')

# Get all infrastructure info
buckets = config.get_bucket_names()
sa_email = config.get_service_account_email()

print(f"Service Account: {sa_email}")
print(f"Available Buckets: {buckets}")
```

## Environment Variables

The package respects these environment variables:

- `GOOGLE_APPLICATION_CREDENTIALS` - Path to service account key file
- `GOOGLE_CLOUD_PROJECT` - GCP project ID (optional)

Example:

```bash
export GOOGLE_APPLICATION_CREDENTIALS=/path/to/key.json
python my_script.py
```

## Troubleshooting

### "State file not found"

Make sure you've run Terraform:

```bash
cd terraform/environments/dev
terraform apply
```

The state file will be at:
- `terraform/environments/dev/terraform.tfstate` (default)
- `terraform/environments/prod/terraform.tfstate` (production)

### "No storage buckets found"

Check that your Terraform configuration includes storage buckets:

```bash
cd terraform/environments/dev
terraform state list  # Should show storage modules
terraform output      # Should show bucket names
```

### "Permission denied" errors

Ensure you have proper Google Cloud credentials:

```bash
gcloud auth application-default login
```

Or set `GOOGLE_APPLICATION_CREDENTIALS`:

```bash
export GOOGLE_APPLICATION_CREDENTIALS=/path/to/key.json
```

### "Cannot get access token"

The service account credentials may be invalid. Check:

```bash
# Verify credentials file
cat $GOOGLE_APPLICATION_CREDENTIALS | python -m json.tool

# Re-authenticate
gcloud auth application-default login
```

## Testing

Run tests:

```bash
make test
```

Run specific test:

```bash
pytest tests/test_app.py -v
```

With coverage:

```bash
pytest --cov=src/databot tests/
```

## API Standards

The package follows these standards:

- **Python**: 3.11+
- **Type hints**: Full type annotations for all public APIs
- **Logging**: Uses Python `logging` module
- **Exceptions**: Clear, descriptive exception messages
- **Documentation**: Docstrings for all public classes and methods

## Contributing

When adding new features:

1. Add type hints to all functions
2. Add docstrings with examples
3. Add unit tests
4. Update this README
5. Test with `make test`

## Future Enhancements

Planned features:

- **compute**: Manage Vertex AI Workbench instances
- **modal**: Integration with Modal Labs for ad-hoc compute
- **monitoring**: Access to GCP monitoring data
- **caching**: Cache discovered infrastructure state
- **async**: Async versions of bucket operations

## Related Documentation

- [Terraform Infrastructure README](../../terraform/README.md)
- [Main Project README](../../README.md)
- [Google Cloud Storage Documentation](https://cloud.google.com/storage/docs)
