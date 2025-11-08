variable "project_id" {
  description = "The GCP project ID"
  type        = string
}

variable "apis" {
  description = "List of Google Cloud APIs to enable"
  type        = list(string)
  default     = []
}
