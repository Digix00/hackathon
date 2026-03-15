resource "random_password" "db_password" {
  length  = 32
  special = false
}

resource "google_sql_database_instance" "main" {
  name             = "main"
  database_version = "POSTGRES_16"
  region           = var.region

  deletion_protection = false

  settings {
    tier              = "db-f1-micro" # 最安の共有コアインスタンス
    availability_type = "ZONAL"       # シングルゾーン（HA なし）

    disk_type       = "PD_HDD" # SSD より安価
    disk_size       = 10       # 最小値（GB）
    disk_autoresize = false    # 自動拡張を無効化してコスト管理

    backup_configuration {
      enabled = false # dev 環境はバックアップ不要
    }

    ip_configuration {
      ipv4_enabled = true
    }
  }

  depends_on = [google_project_service.apis]
}

resource "google_sql_database" "app" {
  name     = "app"
  instance = google_sql_database_instance.main.name
}

resource "google_sql_user" "app" {
  name     = "app"
  instance = google_sql_database_instance.main.name
  password = random_password.db_password.result
}

# DATABASE_URL を Secret Manager に保存
resource "google_secret_manager_secret_version" "database_url" {
  secret = google_secret_manager_secret.secrets["database-url"].id
  secret_data = join("", [
    "postgres://",
    google_sql_user.app.name,
    ":",
    random_password.db_password.result,
    "@/",
    google_sql_database.app.name,
    "?host=/cloudsql/",
    google_sql_database_instance.main.connection_name,
  ])
}

output "cloud_sql_connection_name" {
  value = google_sql_database_instance.main.connection_name
}
