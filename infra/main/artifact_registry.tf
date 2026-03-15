resource "google_artifact_registry_repository" "app" {
  repository_id = "app"
  location      = var.region
  format        = "DOCKER"
  description   = "アプリケーション Docker イメージ"

  depends_on = [google_project_service.apis]
}

# Cloud Run SA に Artifact Registry の読み取り権限を付与
resource "google_artifact_registry_repository_iam_member" "cloudrun_reader" {
  location   = google_artifact_registry_repository.app.location
  repository = google_artifact_registry_repository.app.name
  role       = "roles/artifactregistry.reader"
  member     = "serviceAccount:${google_service_account.cloudrun.email}"
}

# Terraform CI/CD SA に Artifact Registry の書き込み権限を付与
resource "google_artifact_registry_repository_iam_member" "ci_writer" {
  location   = google_artifact_registry_repository.app.location
  repository = google_artifact_registry_repository.app.name
  role       = "roles/artifactregistry.writer"
  member     = "serviceAccount:${google_service_account.terraform_ci.email}"
}

output "artifact_registry_url" {
  value = "${var.region}-docker.pkg.dev/${var.project_id}/${google_artifact_registry_repository.app.repository_id}"
}
