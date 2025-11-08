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
}

variable "enable_workload_identity" {
  description = "Enable Workload Identity for keyless authentication"
  type        = bool
  default     = false
}

variable "kubernetes_namespace" {
  description = "Kubernetes namespace for Workload Identity"
  type        = string
  default     = ""
}

variable "kubernetes_service_account" {
  description = "Kubernetes service account name for Workload Identity"
  type        = string
  default     = ""
}
