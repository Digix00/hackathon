# Firebase Authentication（Identity Platform）設定
resource "google_identity_platform_config" "auth" {
  project = var.project_id

  sign_in {
    allow_duplicate_emails = false

    anonymous {
      enabled = true
    }

    email {
      enabled           = true
      password_required = true
    }
  }

  depends_on = [google_project_service.apis]
}
