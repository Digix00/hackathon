resource "google_storage_bucket" "generated_songs" {
  name          = "${var.project_id}-generated-songs"
  location      = var.region
  storage_class = "STANDARD"

  uniform_bucket_level_access = true

  depends_on = [google_project_service.apis]
}

# Worker SA → 生成楽曲バケットへの書き込み権限（バケットレベル）
resource "google_storage_bucket_iam_member" "worker_writer" {
  bucket = google_storage_bucket.generated_songs.name
  role   = "roles/storage.objectAdmin"
  member = "serviceAccount:${google_service_account.worker.email}"
}

# Cloud Run SA → 生成楽曲バケットへの読み取り権限（バケットレベル）
resource "google_storage_bucket_iam_member" "cloudrun_reader" {
  bucket = google_storage_bucket.generated_songs.name
  role   = "roles/storage.objectViewer"
  member = "serviceAccount:${google_service_account.cloudrun.email}"
}

# 生成楽曲の公開読み取り（クライアントから直接取得するため）
# バケットへの書き込みは backend/internal/infra/storage/client.go の UploadSong が songs/ プレフィックスのみに限定している
# allUsers への IAM Condition は GCP が許可しないため、バケット全体を公開読み取りにする（songs/ 以外のオブジェクトは存在しない）
resource "google_storage_bucket_iam_member" "public_reader" {
  bucket = google_storage_bucket.generated_songs.name
  role   = "roles/storage.objectViewer"
  member = "allUsers"
}
