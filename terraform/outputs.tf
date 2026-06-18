output "railway_project_id" {
  value = railway_project.main.id
}

output "railway_app_service_id" {
  value = railway_service.app.id
}

output "railway_app_domain" {
  value = railway_service_domain.app.domain
}

output "railway_postgres_service_id" {
  value = railway_service.postgres.id
}

output "railway_redis_service_id" {
  value = railway_service.redis.id
}

output "postgres_password" {
  value     = random_password.postgres.result
  sensitive = true
}
