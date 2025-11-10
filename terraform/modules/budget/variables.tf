variable "project_id" {
  description = "Target GCP project ID"
  type        = string
}

variable "environment" {
  description = "Environment name for labeling"
  type        = string
}

variable "billing_account_id" {
  description = "Billing account identifier"
  type        = string
  sensitive   = true
}

variable "user_email" {
  description = "Recipient email for budget alerts"
  type        = string
}

variable "budget_amount" {
  description = "Total budget amount in currency units"
  type        = number
  default     = 50

  validation {
    condition     = var.budget_amount > 0
    error_message = "Budget amount must be greater than zero."
  }
}

variable "notification_increment" {
  description = "Increment between notifications in currency units"
  type        = number
  default     = 10

  validation {
    condition     = var.notification_increment > 0 && var.budget_amount % var.notification_increment == 0
    error_message = "Notification increment must be greater than zero and divide evenly into the budget amount."
  }
}

variable "max_threshold_rules" {
  description = "Maximum number of threshold notifications to configure (API allows up to 4)."
  type        = number
  default     = 4

  validation {
    condition     = var.max_threshold_rules >= 1 && var.max_threshold_rules <= 4
    error_message = "The Budgets API only supports between 1 and 4 threshold notifications."
  }
}

variable "currency_code" {
  description = "ISO currency code for the budget"
  type        = string
  default     = "USD"
}

variable "labels" {
  description = "Optional labels for notification channel"
  type        = map(string)
  default     = {}
}
