terraform {
  required_providers {
    railway = {
      source  = "terraform-community-providers/railway"
      version = "~> 0.6.2"
    }
  }
}

provider "railway" {
  token = var.railway_api_token
}

resource "railway_project" "main" {
  name = var.railway_project_name
}

# NOTE: this provider can only deploy services from a docker image or a git repo
# (no `source = "postgres"` shorthand). Railway's managed Postgres/Redis database
# templates (with the pgvector plugin toggle in the dashboard) are not exposed as a
# Terraform resource by this community provider, so Postgres and Redis are added
# via the Railway dashboard's database templates instead. Terraform here manages
# the project and the app service only.
resource "railway_service" "app" {
  project_id         = railway_project.main.id
  name               = "optcg-ruling-app"
  source_repo        = var.github_repo
  source_repo_branch = "main"
}

resource "railway_service_domain" "app" {
  environment_id = railway_project.main.default_environment.id
  service_id     = railway_service.app.id
  subdomain      = var.railway_project_name
}
