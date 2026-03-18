# DB パスワード（Terraform が生成した値を格納 → secret_version まで Terraform 管理）
resource "google_secret_manager_secret" "db_password" {
  secret_id = "db-password"

  replication {
    auto {}
  }

  depends_on = [google_project_service.apis]
}

resource "google_secret_manager_secret_version" "db_password" {
  secret      = google_secret_manager_secret.db_password.id
  secret_data = random_password.db.result
}

# 以下は「箱」のみ定義。値は開発者が terraform apply 後に手動投入
# gcloud secrets versions add <secret_id> --data-file=-

resource "google_secret_manager_secret" "spotify_client_id" {
  secret_id = "spotify-client-id"

  replication {
    auto {}
  }

  depends_on = [google_project_service.apis]
}

resource "google_secret_manager_secret" "spotify_client_secret" {
  secret_id = "spotify-client-secret"

  replication {
    auto {}
  }

  depends_on = [google_project_service.apis]
}

resource "google_secret_manager_secret" "apple_music_key" {
  secret_id = "apple-music-key"

  replication {
    auto {}
  }

  depends_on = [google_project_service.apis]
}

resource "google_secret_manager_secret" "apns_key" {
  secret_id = "apns-key"

  replication {
    auto {}
  }

  depends_on = [google_project_service.apis]
}

resource "google_secret_manager_secret" "music_state_secret" {
  secret_id = "music-state-secret"

  replication {
    auto {}
  }

  depends_on = [google_project_service.apis]
}

resource "google_secret_manager_secret" "music_token_encryption_key" {
  secret_id = "music-token-encryption-key"

  replication {
    auto {}
  }

  depends_on = [google_project_service.apis]
}
