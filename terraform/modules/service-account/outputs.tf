output "service_account_email" {
  description = "Email address of the service account"
  value       = google_service_account.service_account.email
}

output "service_account_id" {
  description = "ID of the service account"
  value       = google_service_account.service_account.id
}

output "service_account_name" {
  description = "Name of the service account"
  value       = google_service_account.service_account.name
}
