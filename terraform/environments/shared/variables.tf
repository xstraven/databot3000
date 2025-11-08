# Common variables shared across all environments
# Override these in environment-specific .tfvars files

variable "project_id" {
  description = "GCP Project ID"
  type        = string
}

variable "environment" {
  description = "Environment name (dev, prod, staging, etc.)"
  type        = string
  validation {
    condition     = contains(["dev", "prod", "staging"], var.environment)
    error_message = "Environment must be 'dev', 'prod', or 'staging'."
  }
}

variable "region" {
  description = "GCP region"
  type        = string
  default     = "us-central1"
}

variable "zone" {
  description = "GCP zone"
  type        = string
  default     = "us-central1-a"
}

variable "user_email" {
  description = "Email for billing and budget notifications"
  type        = string
}

variable "billing_account_id" {
  description = "GCP Billing Account ID"
  type        = string
  sensitive   = true
}

variable "common_labels" {
  description = "Common labels to apply to all resources"
  type        = map(string)
  default = {
    managed_by = "terraform"
    project    = "databot3000"
  }
}
