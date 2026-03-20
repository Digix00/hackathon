variable "project_id" {
  type = string
}

variable "region" {
  type    = string
  default = "asia-northeast1"
}

variable "github_repo" {
  type        = string
  description = "GitHub リポジトリ名（例: org/repo）。Workload Identity Federation に使用"
}

variable "server_image_tag" {
  type        = string
  description = "デプロイする server イメージのタグ（git SHA または latest）"
  default     = "latest"
}

variable "worker_image_tag" {
  type        = string
  description = "デプロイする worker イメージのタグ（git SHA または latest）"
  default     = "latest"
}

variable "migrate_image_tag" {
  type        = string
  description = "デプロイする migrate イメージのタグ（git SHA または latest）"
  default     = "latest"
}

variable "seed_demo_image_tag" {
  type        = string
  description = "デプロイする seed-demo イメージのタグ（git SHA または latest）"
  default     = "latest"
}

variable "api_domain" {
  type        = string
  description = "API サーバーのドメイン（Spotify OAuth リダイレクト URL に使用）。Cloud Run の URI から https:// を除いたドメイン部分。GitHub Variables の TF_API_DOMAIN から注入される"
  default     = ""
}

variable "seed_target_user_id" {
  type        = string
  description = "デモデータを紐づける対象ユーザーの DB 内 ID"
  default     = "88ca94e3-9c7f-4da8-85d1-74fe42119f53"
}
