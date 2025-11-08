# Development environment configuration

terraform {
  required_version = ">= 1.0"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 6.0"
    }
  }
}

provider "google" {
  project             = var.project_id
  region              = var.region
  billing_project     = var.project_id
  user_project_override = true
}

# ============================================
# Enable required APIs
# ============================================

module "apis" {
  source = "../../modules/gcp-apis"

  project_id = var.project_id
  apis = [
    "cloudbuild.googleapis.com",
    "compute.googleapis.com",
    "storage-api.googleapis.com",
    "cloudresourcemanager.googleapis.com",
    "notebooks.googleapis.com",        # For Vertex AI Workbench
    "run.googleapis.com",              # For Cloud Run
    "redis.googleapis.com",            # For Redis (future)
  ]
}

# ============================================
# Service Accounts
# ============================================

module "sa_dev_databot" {
  source = "../../modules/service-account"

  project_id               = var.project_id
  service_account_name     = "dev-databot"
  display_name             = "Development Databot Service Account"
  create_key               = var.create_service_account_key
  enable_workload_identity = false

  roles = [
    "roles/storage.objectAdmin",       # Full access to storage
    "roles/compute.instanceAdmin",     # Instance management
  ]
}

# ============================================
# Storage Buckets
# ============================================

module "bucket_dev_data" {
  source = "../../modules/storage"

  project_id   = var.project_id
  bucket_name  = "${var.project_id}-dev-data"
  location     = "US"
  storage_class = "STANDARD"
  force_destroy = true                 # Ephemeral dev bucket

  enable_versioning = false

  lifecycle_rules = [
    {
      age           = 90
      action_type   = "Delete"
      storage_class = null
    }
  ]

  service_account_roles = {
    dev_databot = {
      role   = "roles/storage.objectAdmin"
      member = "serviceAccount:${module.sa_dev_databot.service_account_email}"
    }
  }

  labels = merge(var.common_labels, {
    environment = "dev"
    bucket_type = "data"
  })
}

# ============================================
# Vertex AI Workbench (Ephemeral)
# ============================================

module "workbench_dev" {
  source = "../../modules/workbench"

  project_id       = var.project_id
  instance_name    = "dev-databot-workbench"
  zone             = var.zone
  cpu_machine_type = "e2-medium"
  gpu_machine_type = "n1-standard-4"

  enable_gpu              = var.workbench_enable_gpu
  gpu_type                = var.workbench_gpu_type
  gpu_count               = var.workbench_gpu_count
  service_account_email   = module.sa_dev_databot.service_account_email
  desired_state           = var.workbench_desired_state
  disable_public_ip       = false

  labels = merge(var.common_labels, {
    environment = "dev"
    type        = "workbench"
  })
}

# ============================================
# Outputs
# ============================================

output "service_account_email" {
  description = "Email of the development service account"
  value       = module.sa_dev_databot.service_account_email
}

output "dev_data_bucket" {
  description = "Development data bucket name"
  value       = module.bucket_dev_data.bucket_name
}

output "workbench_instance_name" {
  description = "Workbench instance name"
  value       = module.workbench_dev.instance_name
}

output "enabled_apis" {
  description = "List of enabled APIs"
  value       = module.apis.enabled_apis
}
