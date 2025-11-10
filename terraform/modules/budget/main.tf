locals {
  # API expects raw billing account ID, so strip any resource prefix a caller might include
  billing_account = replace(trimspace(var.billing_account_id), "billingAccounts/", "")

  threshold_steps = floor(var.budget_amount / var.notification_increment)

  raw_thresholds = [
    for step in range(1, local.threshold_steps + 1) :
    step * var.notification_increment / var.budget_amount
  ]

  truncated_thresholds = local.threshold_steps <= var.max_threshold_rules ? local.raw_thresholds : concat(
    slice(local.raw_thresholds, 0, var.max_threshold_rules - 1),
    [1]
  )

  threshold_percentages = distinct([for t in local.truncated_thresholds : min(t, 1)])
}

data "google_project" "selected" {
  project_id = var.project_id
}

resource "google_monitoring_notification_channel" "budget_email" {
  project      = var.project_id
  display_name = "${var.project_id}-${var.environment}-budget-email"
  type         = "email"

  labels = {
    email_address = var.user_email
  }

  # Optional labels that make it easier to manage resources
  user_labels = var.labels
}

resource "google_billing_budget" "project_budget" {
  billing_account = local.billing_account
  display_name    = "${var.project_id}-${var.environment}-budget"

  budget_filter {
    projects               = ["projects/${data.google_project.selected.number}"]
    credit_types_treatment = "INCLUDE_ALL_CREDITS"
  }

  amount {
    specified_amount {
      currency_code = var.currency_code
      units         = var.budget_amount
    }
  }

  dynamic "threshold_rules" {
    for_each = local.threshold_percentages
    content {
      threshold_percent = threshold_rules.value
    }
  }

  all_updates_rule {
    schema_version                   = "1.0"
    monitoring_notification_channels = [google_monitoring_notification_channel.budget_email.name]
  }
}
