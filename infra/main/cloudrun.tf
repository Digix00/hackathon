locals {
  image_base = "${var.region}-docker.pkg.dev/${var.project_id}/${google_artifact_registry_repository.app.repository_id}"
}

# API サーバー
resource "google_cloud_run_v2_service" "server" {
  name     = "server"
  location = var.region

  template {
    service_account = google_service_account.cloudrun.email

    containers {
      image = "${local.image_base}/server:latest"

      resources {
        limits = {
          cpu    = "1"
          memory = "512Mi"
        }
      }

      volume_mounts {
        name       = "cloudsql"
        mount_path = "/cloudsql"
      }
    }

    volumes {
      name = "cloudsql"
      cloud_sql_instance {
        instances = [google_sql_database_instance.main.connection_name]
      }
    }

    scaling {
      min_instance_count = 0
      max_instance_count = 3
    }
  }

  # CI/CD がイメージを更新するため Terraform では image の変更を無視
  lifecycle {
    ignore_changes = [
      template[0].containers[0].image,
    ]
  }

  depends_on = [google_project_service.apis]
}

# 認証なしで外部からアクセスできるようにする（アプリ層で Firebase Auth が行う）
resource "google_cloud_run_v2_service_iam_member" "server_public" {
  project  = var.project_id
  location = google_cloud_run_v2_service.server.location
  name     = google_cloud_run_v2_service.server.name
  role     = "roles/run.invoker"
  member   = "allUsers"
}

# Outbox バッチワーカー
resource "google_cloud_run_v2_job" "worker" {
  name     = "worker"
  location = var.region

  template {
    template {
      service_account = google_service_account.cloudrun.email

      containers {
        image = "${local.image_base}/worker:latest"

        volume_mounts {
          name       = "cloudsql"
          mount_path = "/cloudsql"
        }
      }

      volumes {
        name = "cloudsql"
        cloud_sql_instance {
          instances = [google_sql_database_instance.main.connection_name]
        }
      }
    }
  }

  lifecycle {
    ignore_changes = [
      template[0].template[0].containers[0].image,
    ]
  }

  depends_on = [google_project_service.apis]
}

output "server_url" {
  value = google_cloud_run_v2_service.server.uri
}
