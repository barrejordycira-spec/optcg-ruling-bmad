terraform {
  required_providers {
    railway = {
      source  = "terraform-community-providers/railway"
      version = "~> 0.6.2"
    }
  }
}

provider "railway" {
  api_token = var.railway_api_token
}

resource "railway_project" "main" {
  name = var.railway_project_name
}

resource "railway_service" "postgres" {
  project_id = railway_project.main.id
  source     = "postgres"
  name       = "postgres"
}

resource "railway_service" "redis" {
  project_id = railway_project.main.id
  source     = "redis"
  name       = "redis"
}

resource "railway_service" "app" {
  project_id = railway_project.main.id
  name       = "optcg-ruling-app"
}
