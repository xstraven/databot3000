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

variable "enable_versioning" {
  description = "Enable versioning on the bucket"
  type        = bool
  default     = false
}

variable "lifecycle_rules" {
  description = "List of lifecycle rules for the bucket"
  type = list(object({
    age             = number
    action_type     = string
    storage_class   = optional(string)
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
