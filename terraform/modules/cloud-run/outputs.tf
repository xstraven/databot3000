output "service_name" {
  description = "Name of the Cloud Run service"
  value       = google_cloud_run_service.service.name
}

output "service_id" {
  description = "ID of the Cloud Run service"
  value       = google_cloud_run_service.service.id
}

output "service_url" {
  description = "URL of the Cloud Run service"
  value       = google_cloud_run_service.service.status[0].url
}

output "revision_name" {
  description = "Name of the active revision"
  value       = google_cloud_run_service.service.status[0].latest_created_revision_name
}
