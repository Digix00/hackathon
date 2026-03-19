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
