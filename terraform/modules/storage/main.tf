terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 4.0"
    }
  }
}

resource "google_storage_bucket" "bucket" {
  name          = var.bucket_name
  project       = var.project_id
  location      = var.location
  storage_class = var.storage_class

  uniform_bucket_level_access = true
  force_destroy               = var.force_destroy

  dynamic "lifecycle_rule" {
    for_each = var.lifecycle_rules
    content {
      condition {
        age = lifecycle_rule.value.age
      }
      action {
        type          = lifecycle_rule.value.action_type
        storage_class = try(lifecycle_rule.value.storage_class, null)
      }
    }
  }

  dynamic "versioning" {
    for_each = var.enable_versioning ? [1] : []
    content {
      enabled = true
    }
  }

  labels = var.labels
}

# Bind service accounts to bucket with appropriate roles
resource "google_storage_bucket_iam_member" "bucket_access" {
  for_each = var.service_account_roles

  bucket = google_storage_bucket.bucket.name
  role   = each.value.role
  member = each.value.member
}
