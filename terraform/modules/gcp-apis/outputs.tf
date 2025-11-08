output "enabled_apis" {
  description = "List of enabled APIs"
  value       = [for api in google_project_service.apis : api.service]
}

output "enabled_apis_count" {
  description = "Number of enabled APIs"
  value       = length(google_project_service.apis)
}
