# Production environment configuration

terraform {
  required_version = ">= 1.6, < 2.0"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 7.0"
    }
  }

  # Production state is remote only.
  # Set the bucket during init:
  # terraform init -backend-config="bucket=YOUR_TERRAFORM_STATE_BUCKET"
  backend "gcs" {
    prefix = "terraform/prod"
  }
}

provider "google" {
  project               = var.project_id
  region                = var.region
  billing_project       = var.project_id
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
    "run.googleapis.com",
    "redis.googleapis.com",
    "monitoring.googleapis.com", # For monitoring
    "logging.googleapis.com",    # For logging
  ]
}

# ============================================
# Service Accounts
# ============================================

module "sa_prod_databot" {
  source = "../../modules/service-account"

  project_id               = var.project_id
  service_account_name     = "prod-databot"
  display_name             = "Production Databot Service Account"
  create_key               = false # Never create keys in production
  allow_key_creation       = false
  enable_workload_identity = var.enable_workload_identity
  workload_identity_member = var.workload_identity_member

  roles = [
    "roles/storage.objectAdmin",
  ]
}

# ============================================
# Persistent Storage Buckets
# ============================================

module "bucket_prod_data" {
  source = "../../modules/storage"

  project_id    = var.project_id
  bucket_name   = "${var.project_id}-prod-data"
  location      = "US"
  storage_class = "STANDARD"
  force_destroy = false # Prevent accidental deletion

  enable_versioning        = true # Keep version history
  public_access_prevention = "enforced"
  retention_period         = var.prod_data_retention_period
  kms_key_name             = var.prod_data_kms_key_name

  service_account_roles = {
    prod_databot = {
      role   = "roles/storage.objectAdmin"
      member = "serviceAccount:${module.sa_prod_databot.service_account_email}"
    }
  }

  labels = merge(var.common_labels, {
    environment = "prod"
    bucket_type = "data"
  })
}

module "bucket_archive" {
  source = "../../modules/storage"

  project_id               = var.project_id
  bucket_name              = "${var.project_id}-archive"
  location                 = "US"
  storage_class            = "COLDLINE"
  force_destroy            = false
  public_access_prevention = "enforced"
  retention_period         = var.archive_retention_period
  kms_key_name             = var.archive_kms_key_name

  lifecycle_rules = [
    {
      age           = 365
      action_type   = "SetStorageClass"
      storage_class = "ARCHIVE"
    }
  ]

  labels = merge(var.common_labels, {
    environment = "prod"
    bucket_type = "archive"
  })
}

# ============================================
# Outputs
# ============================================

output "service_account_email" {
  description = "Email of the production service account"
  value       = module.sa_prod_databot.service_account_email
}

output "prod_data_bucket" {
  description = "Production data bucket name"
  value       = module.bucket_prod_data.bucket_name
}

output "archive_bucket" {
  description = "Archive bucket name"
  value       = module.bucket_archive.bucket_name
}

output "enabled_apis" {
  description = "List of enabled APIs"
  value       = module.apis.enabled_apis
}
