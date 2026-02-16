# Terraform Infrastructure for Databot3000

This directory contains Terraform code for GCP infrastructure used by Databot3000.

## Layout

```text
terraform/
├── modules/
│   ├── budget/            # Billing budget + alert channel
│   ├── cloud-run/         # Cloud Run service module
│   ├── gcp-apis/          # API enablement module
│   ├── service-account/   # Service account + IAM bindings
│   ├── storage/           # GCS bucket + IAM bindings
│   └── workbench/         # Vertex AI Workbench instance
└── environments/
    ├── dev/               # Development environment
    ├── prod/              # Production environment
    └── shared/            # Shared provider/version constraints
```

## Prerequisites

1. Terraform `>= 1.6, < 2.0`
2. Google Cloud SDK (`gcloud`)
3. Authenticated ADC credentials

```bash
gcloud auth application-default login
gcloud config set project YOUR_PROJECT_ID
```

## Quick Start

### Development

```bash
cd terraform/environments/dev
cp terraform.tfvars.example terraform.tfvars
terraform init
terraform plan
terraform apply
```

### Production (remote state required)

`terraform/environments/prod/main.tf` is configured with a `gcs` backend block and requires a bucket during init.

```bash
cd terraform/environments/prod
cp terraform.tfvars.example terraform.tfvars
terraform init -reconfigure -backend-config="bucket=YOUR_TERRAFORM_STATE_BUCKET"
terraform plan
terraform apply
```

## Make Targets

From repo root:

```bash
# Dev
make terraform.init-dev
make terraform.plan-dev
make terraform.apply-dev
make terraform.destroy-dev

# Prod
make terraform.init-prod STATE_BUCKET=your-terraform-state-bucket
make terraform.plan-prod
make terraform.apply-prod
make terraform.destroy-prod CONFIRM_PROD_DESTROY=true

# Local checks
make terraform.check
```

## Security Defaults

- Service account key creation is disabled by default in all environments.
- A second explicit override is required before key creation is allowed.
- Production buckets enforce public access prevention.
- Workbench defaults to private IP (`disable_public_ip = true`).
- Production uses remote Terraform state (GCS backend).

## Module Notes

### `service-account`

- `create_key` controls key creation.
- `allow_key_creation` must also be `true` to permit key creation.
- `enable_workload_identity=true` requires `workload_identity_member`.

### `storage`

Supports additional hardening options:

- `public_access_prevention` (`inherited` or `enforced`)
- `retention_period` (seconds, `0` disables retention)
- `kms_key_name` (optional CMEK key)

### `cloud-run`

Supports optional VPC connector annotations:

- `vpc_connector`
- `vpc_egress` (`private-ranges-only` or `all-traffic`)
- `annotations` for additional template annotations

## CI Checks

GitHub Actions workflow `.github/workflows/terraform-checks.yml` runs:

1. `terraform fmt -check -recursive terraform`
2. `terraform init -backend=false` + `terraform validate` for dev/prod
3. `checkov -d terraform --quiet`
