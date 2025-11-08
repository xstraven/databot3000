# Terraform Infrastructure for Databot3000

This directory contains infrastructure-as-code for provisioning GCP resources needed for the databot3000 project.

## Directory Structure

```
terraform/
├── modules/                    # Reusable Terraform modules
│   ├── gcp-apis/              # Enable GCP APIs
│   ├── storage/               # Cloud Storage buckets
│   ├── service-account/       # IAM service accounts
│   ├── workbench/             # Vertex AI Workbench instances
│   └── cloud-run/             # Cloud Run services
├── environments/              # Environment-specific configurations
│   ├── dev/                   # Development environment
│   ├── prod/                  # Production environment
│   └── shared/                # Shared configuration (providers, common variables)
├── live/                      # (Legacy) Current production setup
├── archive/                   # (Archive) Deprecated infrastructure
└── README.md                  # This file
```

## Quick Start

### Prerequisites

1. Install [Terraform](https://www.terraform.io/downloads) (>= 1.0)
2. Install [Google Cloud SDK](https://cloud.google.com/sdk/docs/install)
3. Authenticate with GCP:
   ```bash
   gcloud auth application-default login
   gcloud config set project YOUR_PROJECT_ID
   ```

### Initialize Development Environment

```bash
cd terraform/environments/dev
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your values
terraform init
terraform plan
terraform apply
```

### Initialize Production Environment

```bash
cd terraform/environments/prod
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your values
terraform init
terraform plan
terraform apply
```

## Modules

### gcp-apis
Enables required Google Cloud APIs.

**Usage:**
```hcl
module "apis" {
  source = "../../modules/gcp-apis"

  project_id = var.project_id
  apis = [
    "storage-api.googleapis.com",
    "compute.googleapis.com",
  ]
}
```

**Key Variables:**
- `project_id` - GCP Project ID
- `apis` - List of API names to enable

---

### storage
Creates Cloud Storage buckets with optional versioning, lifecycle rules, and IAM bindings.

**Usage:**
```hcl
module "bucket" {
  source = "../../modules/storage"

  project_id    = var.project_id
  bucket_name   = "my-bucket"
  storage_class = "STANDARD"
  enable_versioning = true

  service_account_roles = {
    sa_name = {
      role   = "roles/storage.objectAdmin"
      member = "serviceAccount:sa@project.iam.gserviceaccount.com"
    }
  }
}
```

**Key Variables:**
- `bucket_name` - Name of the bucket
- `location` - Bucket location (US, EU, etc.)
- `storage_class` - STANDARD, NEARLINE, COLDLINE, ARCHIVE
- `enable_versioning` - Enable object versioning
- `lifecycle_rules` - Auto-delete or archive rules
- `force_destroy` - Allow deletion of non-empty buckets
- `service_account_roles` - IAM bindings for service accounts

---

### service-account
Creates GCP service accounts with IAM roles.

**Usage:**
```hcl
module "sa" {
  source = "../../modules/service-account"

  project_id           = var.project_id
  service_account_name = "my-sa"
  display_name         = "My Service Account"
  create_key           = false

  roles = [
    "roles/storage.objectAdmin",
    "roles/compute.instanceAdmin",
  ]
}
```

**Key Variables:**
- `service_account_name` - Service account ID
- `display_name` - Display name
- `roles` - List of IAM roles to bind
- `create_key` - Create a service account key (not recommended)
- `enable_workload_identity` - Enable for Workload Identity Federation

---

### workbench
Creates Vertex AI Workbench instances for interactive development.

**Usage:**
```hcl
module "workbench" {
  source = "../../modules/workbench"

  project_id         = var.project_id
  instance_name      = "my-workbench"
  zone               = "us-central1-a"
  enable_gpu         = true
  gpu_type           = "NVIDIA_TESLA_T4"
  service_account_email = "sa@project.iam.gserviceaccount.com"
  desired_state      = "STOPPED"  # ACTIVE or STOPPED
}
```

**Key Variables:**
- `instance_name` - Workbench instance name
- `zone` - GCP zone
- `cpu_machine_type` - Machine type for CPU (default: e2-medium)
- `gpu_machine_type` - Machine type for GPU (default: n1-standard-4)
- `enable_gpu` - Enable GPU attachment
- `gpu_type` - GPU model (NVIDIA_TESLA_T4, etc.)
- `service_account_email` - Service account to use
- `desired_state` - ACTIVE or STOPPED

---

### cloud-run
Creates Cloud Run services for serverless containers.

**Usage:**
```hcl
module "cloud_run" {
  source = "../../modules/cloud-run"

  project_id      = var.project_id
  service_name    = "my-service"
  region          = "us-central1"
  container_image = "gcr.io/project/image:tag"

  environment_variables = {
    VAR_NAME = "value"
  }

  service_account_email = "sa@project.iam.gserviceaccount.com"
  allow_public_access   = true
}
```

**Key Variables:**
- `service_name` - Cloud Run service name
- `region` - Service region
- `container_image` - Container image URI
- `environment_variables` - Environment variables
- `cpu` - CPU allocation (default: "1")
- `memory` - Memory allocation (default: "512Mi")
- `service_account_email` - Service account to use
- `allow_public_access` - Allow public access

---

## Environments

### Development Environment (`terraform/environments/dev`)

Includes:
- ✅ Service accounts (with key creation enabled)
- ✅ Development storage buckets (ephemeral, force_destroy=true)
- ✅ Vertex AI Workbench (ephemeral, can be destroyed)

Use this for:
- Development and testing
- Experimenting with new infrastructure

### Production Environment (`terraform/environments/prod`)

Includes:
- ✅ Service accounts (keys NOT created)
- ✅ Persistent storage buckets (versioning enabled)
- ✅ Archive bucket with auto-archival

Use this for:
- Stable, long-lived infrastructure
- Data that should not be accidentally deleted

---

## State Management

### Local State (Default)

Terraform stores state in `terraform.tfstate` files locally. This is fine for development but not recommended for production.

To use local state:
```bash
cd terraform/environments/dev
terraform init  # Initializes local backend
```

### Remote State (Recommended for Production)

To migrate to Cloud Storage backend:

1. Create a state bucket:
   ```bash
   gsutil mb gs://your-project-terraform-state
   ```

2. Uncomment and configure the backend in `environments/shared/versions.tf`:
   ```hcl
   terraform {
     backend "gcs" {
       bucket = "your-project-terraform-state"
       prefix = "terraform/prod"
     }
   }
   ```

3. Reinitialize:
   ```bash
   terraform init -migrate-state
   ```

---

## Lifecycle Management

### Using Make Commands

The `Makefile` at the project root provides convenient commands:

```bash
# Workbench lifecycle
make workbench.up      # Spin up workbench in dev
make workbench.down    # Destroy workbench
make workbench.status  # Show workbench status

# Terraform operations
make terraform.plan    # Plan infrastructure changes
make terraform.apply   # Apply changes
make terraform.destroy # Destroy infrastructure
```

### Manual Terraform Commands

```bash
cd terraform/environments/dev

# Plan changes
terraform plan

# Apply changes
terraform apply

# Destroy specific resource
terraform destroy -target=module.workbench_dev

# Export state as JSON (for databot package)
terraform state pull > state.json
```

---

## State Export for Python Package

The databot Python package reads Terraform state to discover infrastructure.

To export state:

```bash
cd terraform/environments/dev
terraform state pull > state.json
```

The `state.json` file will be used by the databot package to discover:
- Storage bucket names
- Service account emails
- Workbench instance names
- etc.

---

## Common Tasks

### Enable a New API

1. Add to `main.tf`:
   ```hcl
   module "apis" {
     apis = [
       # ... existing APIs ...
       "your-new-api.googleapis.com",
     ]
   }
   ```

2. Apply:
   ```bash
   terraform apply
   ```

### Create a New Storage Bucket

1. Add to `main.tf`:
   ```hcl
   module "bucket_new" {
     source = "../../modules/storage"

     project_id  = var.project_id
     bucket_name = "${var.project_id}-new-bucket"
     # ... other variables ...
   }
   ```

2. Plan and apply:
   ```bash
   terraform plan
   terraform apply
   ```

### Add a New Service Account Role

1. Edit the service account module:
   ```hcl
   roles = [
     "roles/storage.objectAdmin",
     "roles/compute.instanceAdmin",
     "roles/your-new-role",  # Add here
   ]
   ```

2. Apply:
   ```bash
   terraform apply
   ```

### Destroy All Infrastructure

⚠️ **WARNING**: This will delete all resources!

```bash
terraform destroy
```

To only destroy ephemeral resources (e.g., workbench):

```bash
terraform destroy -target=module.workbench_dev
```

---

## Troubleshooting

### API Not Enabled

Error: `Error 403: ... is not enabled on project`

**Solution:**
1. Add the API to the `apis` list in `main.tf`
2. Run `terraform apply`

### Permission Denied

Error: `Error 403: Permission 'compute.instances.get' denied`

**Solution:**
1. Ensure your GCP user has the required roles
2. Ask your GCP admin to grant you the necessary permissions
3. Run `gcloud auth application-default login` to refresh credentials

### State Lock Issues

Error: `Error acquiring the state lock`

**Solution:**
```bash
terraform force-unlock <LOCK_ID>
```

### Workbench Fails to Create

If the Workbench creation times out:

1. Check if Notebooks API is enabled:
   ```bash
   gcloud services list --enabled | grep notebooks
   ```

2. Enable it manually if needed:
   ```bash
   gcloud services enable notebooks.googleapis.com
   ```

---

## Migration from Legacy Infrastructure

The old `terraform/live/production` directory is being phased out. To migrate:

1. ✅ New modules are in `terraform/modules/`
2. ✅ New environments are in `terraform/environments/`
3. 📋 Review `terraform/live/production` for any custom configuration
4. 📋 Migrate custom resources to appropriate modules
5. ✅ Delete old `terraform/live/production` when fully migrated

---

## Additional Resources

- [Terraform Documentation](https://www.terraform.io/docs)
- [Google Provider Documentation](https://registry.terraform.io/providers/hashicorp/google/latest/docs)
- [GCP Best Practices](https://cloud.google.com/docs/terraform/best-practices)

---

## Contributing

When adding new modules:

1. Create module directory under `terraform/modules/`
2. Include `main.tf`, `variables.tf`, `outputs.tf`
3. Add a `versions.tf` with provider requirements
4. Document in this README
5. Test in dev environment before using in prod