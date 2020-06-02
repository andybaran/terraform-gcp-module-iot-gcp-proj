output "project_name" {
  value = google_project.project.name
}

output "project_id" {
  value = google_project.project.id
}

output "short_project_id" {
  value = google_project.project.short_project_id
}

output "service_account" {
  value = google_service_account.admin_service_account.account_id
}
