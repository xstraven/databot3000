variable "project_id" {
  description = "GCP Project ID"
  type        = string
}

variable "bucket_name" {
  description = "Name of the Cloud Storage bucket"
  type        = string
}

variable "location" {
  description = "Location for the bucket (e.g., US, EU, us-central1)"
  type        = string
  default     = "US"
}

variable "storage_class" {
  description = "Storage class for the bucket (STANDARD, NEARLINE, COLDLINE, ARCHIVE)"
  type        = string
  default     = "STANDARD"
}

variable "force_destroy" {
  description = "Allow destruction of non-empty bucket"
  type        = bool
  default     = false
}

variable "public_access_prevention" {
  description = "Public access prevention mode (inherited or enforced)"
  type        = string
  default     = "inherited"

  validation {
    condition     = contains(["inherited", "enforced"], var.public_access_prevention)
    error_message = "public_access_prevention must be either \"inherited\" or \"enforced\"."
  }
}

variable "enable_versioning" {
  description = "Enable versioning on the bucket"
  type        = bool
  default     = false
}

variable "retention_period" {
  description = "Retention period in seconds (0 disables retention policy)"
  type        = number
  default     = 0

  validation {
    condition     = var.retention_period >= 0
    error_message = "retention_period must be greater than or equal to 0."
  }
}

variable "kms_key_name" {
  description = "Optional Cloud KMS key for bucket default encryption"
  type        = string
  default     = null
  nullable    = true
}

variable "lifecycle_rules" {
  description = "List of lifecycle rules for the bucket"
  type = list(object({
    age           = number
    action_type   = string
    storage_class = optional(string)
  }))
  default = []
}

variable "labels" {
  description = "Labels to apply to the bucket"
  type        = map(string)
  default     = {}
}

variable "service_account_roles" {
  description = "Map of service accounts and their roles"
  type = map(object({
    role   = string
    member = string
  }))
  default = {}
}
