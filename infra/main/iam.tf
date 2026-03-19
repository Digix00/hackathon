# Cloud Run 用サービスアカウント
resource "google_service_account" "cloudrun" {
  account_id   = "cloudrun-sa"
  display_name = "Cloud Run Service Account"
}

resource "google_project_iam_member" "cloudrun_secret_accessor" {
  project = var.project_id
  role    = "roles/secretmanager.secretAccessor"
  member  = "serviceAccount:${google_service_account.cloudrun.email}"
}

resource "google_project_iam_member" "cloudrun_log_writer" {
  project = var.project_id
  role    = "roles/logging.logWriter"
  member  = "serviceAccount:${google_service_account.cloudrun.email}"
}

resource "google_project_iam_member" "cloudrun_cloudsql_client" {
  project = var.project_id
  role    = "roles/cloudsql.client"
  member  = "serviceAccount:${google_service_account.cloudrun.email}"
}

resource "google_project_iam_member" "cloudrun_firebase_auth_admin" {
  project = var.project_id
  role    = "roles/firebaseauth.admin"
  member  = "serviceAccount:${google_service_account.cloudrun.email}"
}

# Worker 用サービスアカウント
resource "google_service_account" "worker" {
  account_id   = "worker-sa"
  display_name = "Worker Service Account"
}

resource "google_project_iam_member" "worker_secret_accessor" {
  project = var.project_id
  role    = "roles/secretmanager.secretAccessor"
  member  = "serviceAccount:${google_service_account.worker.email}"
}

resource "google_project_iam_member" "worker_aiplatform_user" {
  project = var.project_id
  role    = "roles/aiplatform.user"
  member  = "serviceAccount:${google_service_account.worker.email}"
}

resource "google_project_iam_member" "worker_log_writer" {
  project = var.project_id
  role    = "roles/logging.logWriter"
  member  = "serviceAccount:${google_service_account.worker.email}"
}

resource "google_project_iam_member" "worker_cloudsql_client" {
  project = var.project_id
  role    = "roles/cloudsql.client"
  member  = "serviceAccount:${google_service_account.worker.email}"
}

# Cloud Scheduler 用サービスアカウント
resource "google_service_account" "scheduler" {
  account_id   = "scheduler-sa"
  display_name = "Cloud Scheduler Service Account"
}

# Scheduler SA に worker Service の invoker 権限を付与（サービス単位で限定）
resource "google_cloud_run_v2_service_iam_member" "scheduler_worker_invoker" {
  project  = var.project_id
  location = google_cloud_run_v2_service.worker.location
  name     = google_cloud_run_v2_service.worker.name
  role     = "roles/run.invoker"
  member   = "serviceAccount:${google_service_account.scheduler.email}"
}

# Terraform CI/CD SA に migrate Service の invoker 権限を付与（CI からマイグレーション実行用）
resource "google_cloud_run_v2_service_iam_member" "terraform_ci_migrate_invoker" {
  project  = var.project_id
  location = google_cloud_run_v2_service.migrate.location
  name     = google_cloud_run_v2_service.migrate.name
  role     = "roles/run.invoker"
  member   = "serviceAccount:${google_service_account.terraform_ci.email}"
}

# Terraform CI/CD 用サービスアカウント（GitHub Actions WIF）
resource "google_service_account" "terraform_ci" {
  account_id   = "terraform-ci-sa"
  display_name = "Terraform CI/CD Service Account"
}

locals {
  terraform_ci_roles = [
    "roles/run.admin",
    "roles/artifactregistry.admin",
    "roles/cloudsql.admin",
    "roles/cloudscheduler.admin",
    "roles/secretmanager.admin",
    "roles/iam.serviceAccountAdmin",
    "roles/iam.workloadIdentityPoolAdmin",
    "roles/resourcemanager.projectIamAdmin",
    "roles/serviceusage.serviceUsageAdmin",
    "roles/storage.admin",
    "roles/logging.admin",
    "roles/identitytoolkit.admin",
  ]
}

resource "google_project_iam_member" "terraform_ci_roles" {
  for_each = toset(local.terraform_ci_roles)

  project = var.project_id
  role    = each.value
  member  = "serviceAccount:${google_service_account.terraform_ci.email}"
}

# Workload Identity Pool
resource "google_iam_workload_identity_pool" "github" {
  workload_identity_pool_id = "github-pool"
  display_name              = "GitHub Actions Pool"
}

# Workload Identity Provider（GitHub Actions）
resource "google_iam_workload_identity_pool_provider" "github" {
  workload_identity_pool_id          = google_iam_workload_identity_pool.github.workload_identity_pool_id
  workload_identity_pool_provider_id = "github-provider"
  display_name                       = "GitHub Actions Provider"

  oidc {
    issuer_uri = "https://token.actions.githubusercontent.com"
  }

  attribute_mapping = {
    "google.subject"       = "assertion.sub"
    "attribute.repository" = "assertion.repository"
    "attribute.ref"        = "assertion.ref"
  }

  attribute_condition = "attribute.repository == \"${var.github_repo}\""
}

# WIF → Terraform CI/CD サービスアカウントの紐付け
resource "google_service_account_iam_member" "terraform_ci_wif" {
  service_account_id = google_service_account.terraform_ci.name
  role               = "roles/iam.workloadIdentityUser"
  member             = "principalSet://iam.googleapis.com/${google_iam_workload_identity_pool.github.name}/attribute.repository/${var.github_repo}"
}

# terraform_ci SA の自己 IDトークン発行権限
# WIF 経由で認証した状態から --impersonate-service-account で IDトークンを取得するために必要
resource "google_service_account_iam_member" "terraform_ci_token_creator_self" {
  service_account_id = google_service_account.terraform_ci.name
  role               = "roles/iam.serviceAccountTokenCreator"
  member             = "serviceAccount:${google_service_account.terraform_ci.email}"
}

# Terraform CI SA → cloudrun-sa / worker-sa の actAs 権限
# Cloud Run Service/Job 作成時に service_account を指定するには
# デプロイ主体が対象 SA に対して iam.serviceaccounts.actAs を持つ必要がある
resource "google_service_account_iam_member" "terraform_ci_actas_cloudrun" {
  service_account_id = google_service_account.cloudrun.name
  role               = "roles/iam.serviceAccountUser"
  member             = "serviceAccount:${google_service_account.terraform_ci.email}"
}

resource "google_service_account_iam_member" "terraform_ci_actas_worker" {
  service_account_id = google_service_account.worker.name
  role               = "roles/iam.serviceAccountUser"
  member             = "serviceAccount:${google_service_account.terraform_ci.email}"
}

resource "google_service_account_iam_member" "terraform_ci_actas_scheduler" {
  service_account_id = google_service_account.scheduler.name
  role               = "roles/iam.serviceAccountUser"
  member             = "serviceAccount:${google_service_account.terraform_ci.email}"
}

# GitHub Actions Secrets に登録する値の出力
output "wif_provider" {
  value       = google_iam_workload_identity_pool_provider.github.name
  description = "GitHub Secret GCP_WIF_PROVIDER に設定する値"
}

output "terraform_ci_sa_email" {
  value       = google_service_account.terraform_ci.email
  description = "GitHub Secret GCP_TERRAFORM_SA に設定する値"
}
