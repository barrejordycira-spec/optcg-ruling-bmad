output "railway_project_id" {
  value = railway_project.main.id
}

output "railway_app_service_id" {
  value = railway_service.app.id
}

output "railway_app_domain" {
  value = railway_service_domain.app.domain
}
