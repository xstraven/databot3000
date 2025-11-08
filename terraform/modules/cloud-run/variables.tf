variable "project_id" {
  description = "GCP Project ID"
  type        = string
}

variable "service_name" {
  description = "Name of the Cloud Run service"
  type        = string
}

variable "region" {
  description = "Region for the Cloud Run service"
  type        = string
}

variable "container_image" {
  description = "Container image URI (e.g., gcr.io/project/image:tag)"
  type        = string
}

variable "environment_variables" {
  description = "Environment variables to pass to the container"
  type        = map(string)
  default     = {}
}

variable "cpu" {
  description = "CPU allocation (e.g., '1', '2')"
  type        = string
  default     = "1"
}

variable "memory" {
  description = "Memory allocation (e.g., '512Mi', '1Gi')"
  type        = string
  default     = "512Mi"
}

variable "service_account_email" {
  description = "Email of the service account to use"
  type        = string
}

variable "timeout_seconds" {
  description = "Request timeout in seconds"
  type        = number
  default     = 300
}

variable "labels" {
  description = "Labels to apply to the service"
  type        = map(string)
  default     = {}
}

variable "allow_public_access" {
  description = "Whether to allow public access to the service"
  type        = bool
  default     = false
}

variable "authorized_service_accounts" {
  description = "Map of service account members authorized to invoke the service"
  type        = map(string)
  default     = {}
}

variable "vpc_connector" {
  description = "VPC Connector to use for the service"
  type        = string
  default     = ""
}
