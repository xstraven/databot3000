# Development environment variables

variable "project_id" {
  description = "GCP Project ID"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"
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

# Workbench specific variables
variable "workbench_enable_gpu" {
  description = "Enable GPU on Workbench instance"
  type        = bool
  default     = false
}

variable "workbench_gpu_type" {
  description = "Type of GPU (NVIDIA_TESLA_T4, NVIDIA_TESLA_K80, etc.)"
  type        = string
  default     = "NVIDIA_TESLA_T4"
}

variable "workbench_gpu_count" {
  description = "Number of GPUs"
  type        = number
  default     = 1
}

variable "workbench_desired_state" {
  description = "Desired state of Workbench (ACTIVE or STOPPED)"
  type        = string
  default     = "STOPPED"
}

variable "create_service_account_key" {
  description = "Whether to create a service account key (not recommended for production)"
  type        = bool
  default     = false
}
