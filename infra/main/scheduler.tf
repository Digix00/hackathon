resource "google_cloud_scheduler_job" "worker_kick" {
  name      = "worker-kick"
  region    = var.region
  schedule  = "*/10 * * * *"
  time_zone = "Asia/Tokyo"

  http_target {
    http_method = "POST"
    uri         = "${google_cloud_run_v2_service.worker.uri}/"

    oidc_token {
      service_account_email = google_service_account.scheduler.email
      audience              = google_cloud_run_v2_service.worker.uri
    }
  }

  depends_on = [google_project_service.apis]
}
