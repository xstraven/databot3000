terraform {
  required_version = ">= 1.0"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 6.0"
    }
  }

  # Uncomment and configure for remote state (Cloud Storage backend)
  # backend "gcs" {
  #   bucket  = "your-terraform-state-bucket"
  #   prefix  = "terraform/state"
  #   encryption_key = "your-encryption-key"
  # }

  # Local backend is used by default
  # backend "local" {
  #   path = "terraform.tfstate"
  # }
}
