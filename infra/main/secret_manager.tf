locals {
  secrets = [
    "spotify-client-id",
    "spotify-client-secret",
    "apple-music-key-id",
    "apple-music-team-id",
    "apple-music-private-key",
    "apns-key-id",
    "apns-team-id",
    "apns-private-key",
    "database-url",
  ]
}

resource "google_secret_manager_secret" "secrets" {
  for_each  = toset(local.secrets)
  secret_id = each.value

  replication {
    auto {}
  }

  depends_on = [google_project_service.apis]
}
