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

# ── PostgreSQL (with pgvector) ────────────────────────────────────────────────
resource "random_password" "postgres" {
  length  = 24
  special = false # avoid chars that need URL-encoding in a connection string
}

# NOTE on volumes: this community provider has a bug where a `volume` nested block
# triggers "Provider produced inconsistent result after apply" (returns null volume),
# failing the apply. So volumes are NOT managed here — attach a persistent volume to
# the postgres service via the Railway dashboard (Service → Settings → Volumes,
# mount path `/var/lib/postgresql/data`). PGDATA below already points at a subdir so it
# works whether or not a volume is mounted.
resource "railway_service" "postgres" {
  project_id   = railway_project.main.id
  name         = "postgres"
  source_image = "pgvector/pgvector:pg18"
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
# Redis is a cache (Story 2.2) — ephemeral is acceptable; no volume needed here.
# (Same provider volume bug as postgres above; attach via dashboard if persistence
# is ever required.)
resource "railway_service" "redis" {
  project_id   = railway_project.main.id
  name         = "redis"
  source_image = "redis:8.2.1"
}
