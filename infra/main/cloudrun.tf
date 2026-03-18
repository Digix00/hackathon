locals {
  image_server = "${var.region}-docker.pkg.dev/${var.project_id}/${google_artifact_registry_repository.app.repository_id}/server:latest"
  image_worker = "${var.region}-docker.pkg.dev/${var.project_id}/${google_artifact_registry_repository.app.repository_id}/worker:latest"
}

# Cloud Run Service（API サーバー）
resource "google_cloud_run_v2_service" "api" {
  name     = "api"
  location = var.region

  deletion_protection = false

  template {
    service_account = google_service_account.cloudrun.email

    volumes {
      name = "cloudsql"
      cloud_sql_instance {
        instances = [google_sql_database_instance.main.connection_name]
      }
    }

    scaling {
      min_instance_count = 0
      max_instance_count = 2
    }

    containers {
      image = local.image_server

      env {
        name  = "DB_HOST"
        value = "/cloudsql/${google_sql_database_instance.main.connection_name}"
      }

      env {
        name  = "DB_USER"
        value = google_sql_user.app.name
      }

      env {
        name  = "DB_NAME"
        value = google_sql_database.app.name
      }

      env {
        name = "DB_PASSWORD"
        value_source {
          secret_key_ref {
            secret  = google_secret_manager_secret.db_password.secret_id
            version = "latest"
          }
        }
      }

      env {
        name = "SPOTIFY_CLIENT_ID"
        value_source {
          secret_key_ref {
            secret  = google_secret_manager_secret.spotify_client_id.secret_id
            version = "latest"
          }
        }
      }

      env {
        name = "SPOTIFY_CLIENT_SECRET"
        value_source {
          secret_key_ref {
            secret  = google_secret_manager_secret.spotify_client_secret.secret_id
            version = "latest"
          }
        }
      }

      env {
        name = "APPLE_MUSIC_KEY"
        value_source {
          secret_key_ref {
            secret  = google_secret_manager_secret.apple_music_key.secret_id
            version = "latest"
          }
        }
      }

      env {
        name = "APNS_KEY"
        value_source {
          secret_key_ref {
            secret  = google_secret_manager_secret.apns_key.secret_id
            version = "latest"
          }
        }
      }

      volume_mounts {
        name       = "cloudsql"
        mount_path = "/cloudsql"
      }
    }
  }

  depends_on = [
    google_project_service.apis,
    google_secret_manager_secret_version.db_password,
  ]
}

# Cloud Run Service をパブリックアクセス可能にする
resource "google_cloud_run_v2_service_iam_member" "noauth" {
  project  = var.project_id
  location = google_cloud_run_v2_service.api.location
  name     = google_cloud_run_v2_service.api.name
  role     = "roles/run.invoker"
  member   = "allUsers"
}

# Cloud Run Job（Worker）
resource "google_cloud_run_v2_job" "worker" {
  name     = "worker"
  location = var.region

  deletion_protection = false

  template {
    template {
      service_account = google_service_account.worker.email

      volumes {
        name = "cloudsql"
        cloud_sql_instance {
          instances = [google_sql_database_instance.main.connection_name]
        }
      }

      containers {
        image = local.image_worker

        resources {
          limits = {
            cpu    = "1"
            memory = "512Mi"
          }
        }

        env {
          name  = "DB_HOST"
          value = "/cloudsql/${google_sql_database_instance.main.connection_name}"
        }

        env {
          name  = "DB_USER"
          value = google_sql_user.app.name
        }

        env {
          name  = "DB_NAME"
          value = google_sql_database.app.name
        }

        env {
          name = "DB_PASSWORD"
          value_source {
            secret_key_ref {
              secret  = google_secret_manager_secret.db_password.secret_id
              version = "latest"
            }
          }
        }

        volume_mounts {
          name       = "cloudsql"
          mount_path = "/cloudsql"
        }
      }
    }
  }

  depends_on = [
    google_project_service.apis,
    google_secret_manager_secret_version.db_password,
  ]
}

output "api_url" {
  value       = google_cloud_run_v2_service.api.uri
  description = "Cloud Run Service の URL"
}
