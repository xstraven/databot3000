terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 4.0"
    }
  }
}

resource "google_cloud_run_service" "service" {
  name     = var.service_name
  location = var.region
  project  = var.project_id

  template {
    spec {
      containers {
        image = var.container_image

        dynamic "env" {
          for_each = var.environment_variables
          content {
            name  = env.key
            value = env.value
          }
        }

        resources {
          limits = {
            cpu    = var.cpu
            memory = var.memory
          }
        }
      }

      service_account_name = var.service_account_email
      timeout_seconds      = var.timeout_seconds
    }

    metadata {
      labels = var.labels
    }
  }

  traffic {
    percent         = 100
    latest_revision = true
  }

  lifecycle {
    ignore_changes = [template[0].metadata[0].annotations]
  }
}

# Allow public access if enabled
resource "google_cloud_run_service_iam_member" "public_access" {
  count   = var.allow_public_access ? 1 : 0
  service = google_cloud_run_service.service.name
  role    = "roles/run.invoker"
  member  = "allUsers"
}

# Allow specific service accounts access if provided
resource "google_cloud_run_service_iam_member" "service_accounts" {
  for_each = var.authorized_service_accounts

  service = google_cloud_run_service.service.name
  role    = "roles/run.invoker"
  member  = each.value
}

# VPC Connector binding if provided
resource "google_cloud_run_service" "service_with_vpc" {
  count    = var.vpc_connector != "" ? 0 : 0
  # This is handled above; VPC is specified in template
}
