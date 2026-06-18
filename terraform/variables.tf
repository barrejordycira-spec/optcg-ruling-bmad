variable "railway_api_token" {
  type      = string
  sensitive = true
}

variable "railway_project_name" {
  type    = string
  default = "optcg-ruling"
}

variable "github_repo" {
  type        = string
  default     = "barrejordycira-spec/optcg-ruling-bmad"
  description = "GitHub repo (owner/name) the app service deploys from."
}

variable "sentry_dsn" {
  type        = string
  sensitive   = true
  default     = ""
  description = "Sentry DSN injected into the app service for error reporting."
}
