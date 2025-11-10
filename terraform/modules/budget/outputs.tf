output "budget_id" {
  description = "Identifier of the created billing budget"
  value       = google_billing_budget.project_budget.id
}

output "notification_channel_id" {
  description = "Notification channel used for budget alerts"
  value       = google_monitoring_notification_channel.budget_email.name
}
