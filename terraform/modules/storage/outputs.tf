output "bucket_name" {
  description = "Name of the created bucket"
  value       = google_storage_bucket.bucket.name
}

output "bucket_id" {
  description = "ID of the created bucket"
  value       = google_storage_bucket.bucket.id
}

output "bucket_url" {
  description = "URL of the created bucket"
  value       = "gs://${google_storage_bucket.bucket.name}"
}

output "bucket_self_link" {
  description = "Self link of the created bucket"
  value       = google_storage_bucket.bucket.self_link
}
