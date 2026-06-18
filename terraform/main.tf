terraform {
  required_providers {
    railway = {
      source  = "terraform-community-providers/railway"
      version = "~> 0.6.2"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }
}

provider "railway" {
  token = var.railway_api_token
}

resource "railway_project" "main" {
  name = var.railway_project_name
}

locals {
  environment_id = railway_project.main.default_environment.id
}

# ── App service ───────────────────────────────────────────────────────────────
# NOTE: this community provider deploys services from a docker image (`source_image`)
# or a git repo (`source_repo`) — there is no `source = "postgres"/"redis"` shorthand.
# The app builds from the GitHub repo (Dockerfile); Postgres/Redis run from public
# docker images below.
resource "railway_service" "app" {
  project_id         = railway_project.main.id
  name               = "optcg-ruling-app"
  source_repo        = var.github_repo
  source_repo_branch = "main"
}

resource "railway_service_domain" "app" {
  environment_id = local.environment_id
  service_id     = railway_service.app.id
  subdomain      = var.railway_project_name
}

resource "railway_variable" "app_sentry_dsn" {
  count          = var.sentry_dsn == "" ? 0 : 1
  environment_id = local.environment_id
  service_id     = railway_service.app.id
  name           = "SENTRY_DSN"
  value          = var.sentry_dsn
}

# ── PostgreSQL (with pgvector) ────────────────────────────────────────────────
resource "random_password" "postgres" {
  length  = 24
  special = false # avoid chars that need URL-encoding in a connection string
}

# NOTE on volumes: this community provider (0.6.2, latest) returns a null volume on
# create, so the first `terraform apply` errors with "Provider produced inconsistent
# result after apply" even though the volume IS created on Railway. Workaround: run
# `terraform apply` a second time — the refresh reconciles the already-created volume.
# PGDATA points at a subdir of the mount so initdb works (Railway volumes have a
# lost+found at the mount root).
resource "railway_service" "postgres" {
  project_id   = railway_project.main.id
  name         = "postgres"
  source_image = "pgvector/pgvector:pg18"

  volume = {
    name       = "postgres-data"
    mount_path = "/var/lib/postgresql/data"
  }
}

resource "railway_variable" "postgres_user" {
  environment_id = local.environment_id
  service_id     = railway_service.postgres.id
  name           = "POSTGRES_USER"
  value          = "optcg"
}

resource "railway_variable" "postgres_password" {
  environment_id = local.environment_id
  service_id     = railway_service.postgres.id
  name           = "POSTGRES_PASSWORD"
  value          = random_password.postgres.result
}

resource "railway_variable" "postgres_db" {
  environment_id = local.environment_id
  service_id     = railway_service.postgres.id
  name           = "POSTGRES_DB"
  value          = "optcg_ruling"
}

# Mount root holds a lost+found dir on Railway volumes; initdb refuses a non-empty
# data dir, so point PGDATA at a subdirectory of the mount.
resource "railway_variable" "postgres_pgdata" {
  environment_id = local.environment_id
  service_id     = railway_service.postgres.id
  name           = "PGDATA"
  value          = "/var/lib/postgresql/data/pgdata"
}

# ── Redis ─────────────────────────────────────────────────────────────────────
# Redis cache (Story 2.2) — intentionally ephemeral (no volume): cache data is
# reconstructible, and this provider + Railway's volume API cannot manage a redis
# volume cleanly (volumeDelete is async/non-effective, so volume names linger and
# collide on re-create). Postgres keeps its volume because its data must persist.
resource "railway_service" "redis" {
  project_id   = railway_project.main.id
  name         = "redis"
  source_image = "redis:8.2.1"
}
