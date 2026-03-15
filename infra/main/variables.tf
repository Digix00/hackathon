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
