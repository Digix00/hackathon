resource "random_password" "db" {
  length  = 32
  special = false
}

resource "google_sql_database_instance" "main" {
  name             = "${var.project_id}-db"
  database_version = "POSTGRES_16"
  region           = var.region

  deletion_protection = false

  settings {
    tier              = "db-f1-micro"
    availability_type = "ZONAL"
    disk_size         = 10
    disk_autoresize   = false

    backup_configuration {
      enabled = false
    }

    ip_configuration {
      ipv4_enabled = true
    }
  }

  depends_on = [google_project_service.apis]
}

resource "google_sql_database" "app" {
  name     = "hackathon"
  instance = google_sql_database_instance.main.name
}

resource "google_sql_user" "app" {
  name     = "appuser"
  instance = google_sql_database_instance.main.name
  password = random_password.db.result
}

output "db_connection_name" {
  value       = google_sql_database_instance.main.connection_name
  description = "Cloud Run の cloud_sql_instances annotation に設定する値"
}

output "db_password" {
  value       = random_password.db.result
  sensitive   = true
  description = "PR #2 で gcloud secrets versions add db-password に投入する値"
}
