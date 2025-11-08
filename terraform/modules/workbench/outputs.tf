output "instance_name" {
  description = "Name of the Workbench instance"
  value       = google_workbench_instance.instance.name
}

output "instance_id" {
  description = "ID of the Workbench instance"
  value       = google_workbench_instance.instance.id
}

output "instance_state" {
  description = "State of the Workbench instance"
  value       = google_workbench_instance.instance.state
}

output "proxy_uri" {
  description = "Proxy URI for accessing the Workbench instance"
  value       = try(google_workbench_instance.instance.proxy_uri, null)
}

output "create_time" {
  description = "Time when the instance was created"
  value       = google_workbench_instance.instance.create_time
}
