variable "project_id" {
  description = "GCP Project ID"
  type        = string
}

variable "service_account_name" {
  description = "Name of the service account"
  type        = string
}

variable "display_name" {
  description = "Display name for the service account"
  type        = string
}

variable "roles" {
  description = "List of IAM roles to bind to the service account"
  type        = set(string)
  default     = []
}

variable "create_key" {
  description = "Whether to create a service account key (not recommended for production)"
  type        = bool
  default     = false

  validation {
    condition     = !var.create_key || var.allow_key_creation
    error_message = "Service account key creation is disabled by default. Set allow_key_creation=true for an explicit temporary exception."
  }
}

variable "allow_key_creation" {
  description = "Explicit override to allow service account key creation"
  type        = bool
  default     = false
}

variable "enable_workload_identity" {
  description = "Enable Workload Identity for keyless authentication"
  type        = bool
  default     = false

  validation {
    condition     = !var.enable_workload_identity || (var.workload_identity_member != null && trimspace(var.workload_identity_member) != "")
    error_message = "workload_identity_member must be set when enable_workload_identity=true."
  }
}

variable "workload_identity_member" {
  description = "IAM member string authorized for workload identity (for example serviceAccount:PROJECT_ID.svc.id.goog[NAMESPACE/KSA])"
  type        = string
  default     = null
  nullable    = true
}
