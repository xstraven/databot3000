terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 4.0"
    }
  }
}

resource "google_service_account" "service_account" {
  account_id   = var.service_account_name
  display_name = var.display_name
  project      = var.project_id
}

# Create and manage service account keys (optional)
resource "google_service_account_key" "service_account_key" {
  count              = var.create_key ? 1 : 0
  service_account_id = google_service_account.service_account.name
  public_key_type    = "TYPE_X509_PEM_FILE"
}

# Bind roles to the service account
resource "google_project_iam_member" "service_account_roles" {
  for_each = var.roles

  project = var.project_id
  role    = each.value
  member  = "serviceAccount:${google_service_account.service_account.email}"
}

# Workload Identity (optional, for keyless auth)
resource "google_service_account_iam_member" "workload_identity" {
  count              = var.enable_workload_identity ? 1 : 0
  service_account_id = google_service_account.service_account.name
  role               = "roles/iam.workloadIdentityUser"
  member             = "serviceAccount:${var.project_id}.svc.id.goog[${var.kubernetes_namespace}/${var.kubernetes_service_account}]"
}
