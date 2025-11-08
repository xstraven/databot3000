variable "project_id" {
  description = "GCP Project ID"
  type        = string
}

variable "instance_name" {
  description = "Name of the Vertex AI Workbench instance"
  type        = string
}

variable "zone" {
  description = "Zone for the Workbench instance"
  type        = string
}

variable "cpu_machine_type" {
  description = "Machine type for CPU-only instances"
  type        = string
  default     = "e2-medium"
}

variable "gpu_machine_type" {
  description = "Machine type for GPU instances"
  type        = string
  default     = "n1-standard-4"
}

variable "enable_gpu" {
  description = "Whether to attach a GPU to the instance"
  type        = bool
  default     = false
}

variable "gpu_type" {
  description = "Type of GPU to attach"
  type        = string
  default     = "NVIDIA_TESLA_T4"
}

variable "gpu_count" {
  description = "Number of GPUs to attach"
  type        = number
  default     = 1
}

variable "service_account_email" {
  description = "Email of the service account to use"
  type        = string
}

variable "metadata" {
  description = "Metadata to attach to the instance"
  type        = map(string)
  default     = {}
}

variable "disable_public_ip" {
  description = "Whether to disable public IP"
  type        = bool
  default     = false
}

variable "desired_state" {
  description = "Desired state of the instance (ACTIVE or STOPPED)"
  type        = string
  default     = "STOPPED"
}

variable "labels" {
  description = "Labels to apply to the instance"
  type        = map(string)
  default     = {}
}
