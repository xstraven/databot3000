# Production environment variables

variable "project_id" {
  description = "GCP Project ID"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "prod"
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
  description = "Email for notifications"
  type        = string
}

variable "billing_account_id" {
  description = "Billing account ID"
  type        = string
  sensitive   = true
  default     = ""
}

variable "common_labels" {
  description = "Common labels for all resources"
  type        = map(string)
  default = {
    managed_by = "terraform"
    project    = "databot3000"
  }
}

variable "enable_workload_identity" {
  description = "Enable Workload Identity for keyless auth"
  type        = bool
  default     = false
}

variable "workload_identity_member" {
  description = "IAM member string for workload identity binding (required when enable_workload_identity=true)"
  type        = string
  default     = null
  nullable    = true
}

variable "prod_data_retention_period" {
  description = "Retention period in seconds for the production data bucket (0 disables retention policy)"
  type        = number
  default     = 0
}

variable "archive_retention_period" {
  description = "Retention period in seconds for the archive bucket (0 disables retention policy)"
  type        = number
  default     = 0
}

variable "prod_data_kms_key_name" {
  description = "Optional CMEK key for production data bucket encryption"
  type        = string
  default     = null
  nullable    = true
}

variable "archive_kms_key_name" {
  description = "Optional CMEK key for archive bucket encryption"
  type        = string
  default     = null
  nullable    = true
}
