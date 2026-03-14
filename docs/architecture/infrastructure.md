# インフラ技術スタック

Cloud SQL（PostgreSQL）を採用するため GCP をベースプラットフォームとする。
インフラは Terraform で IaC 管理し、環境ごとの差異をコードで表現する。

## GCP サービス構成

| サービス | 用途 | Terraform 管理 |
|---|---|---|
| Cloud SQL（PostgreSQL） | メイン DB | ✅ |
| Cloud Run | Backend API のホスティング | ✅ |
| Cloud Run Jobs | 通知バッチ処理（worker）、Lyria 生成ジョブ | ✅ |
| Cloud Scheduler | worker を定期キック（10〜20分間隔） | ✅ |
| **Vertex AI** | Gemini 1.5 Flash（歌詞分析）、Lyria（楽曲生成） | ✅ |
| Firebase Auth | 認証基盤（Apple / Google Sign-In） | 部分的（Firebase CLI 併用） |
| Firebase Cloud Messaging (FCM) | Android プッシュ通知 | Firebase Console |
| Artifact Registry | Docker イメージ管理 | ✅ |
| Cloud Storage | Terraform State 保存 / **生成楽曲保存** | ✅ |
| Cloud Logging / Alerting | ログ収集・Discord アラート | ✅ |
| IAM / Service Account | 各サービスの権限管理 | ✅ |

## IaC（Terraform）

### ディレクトリ構成

```
terraform/
├── environments/
│   ├── dev/
│   │   ├── main.tf           # モジュール呼び出し・プロバイダ設定
│   │   ├── variables.tf
│   │   ├── outputs.tf
│   │   └── terraform.tfvars  # 環境固有の値（GIT 管理下）
│   └── prod/
│       ├── main.tf
│       ├── variables.tf
│       ├── outputs.tf
│       └── terraform.tfvars
└── modules/
    ├── cloudrun/             # Cloud Run service（API）+ Cloud Run Jobs（worker）
    ├── cloudsql/             # Cloud SQL インスタンス・DB・ユーザー
    ├── scheduler/            # Cloud Scheduler ジョブ
    ├── registry/             # Artifact Registry リポジトリ
    ├── storage/              # Cloud Storage バケット（生成楽曲保存含む）
    ├── vertexai/             # Vertex AI API 有効化・IAM 設定
    ├── logging/              # Log-based Alert → Discord Webhook
    └── iam/                  # Service Account・IAM バインディング
```

### 環境分離方針

`environments/dev` と `environments/prod` の2環境。
各環境は独立した GCP プロジェクトを持ち、State も別バケットで管理する。

| 項目 | dev | prod |
|---|---|---|
| GCP プロジェクト | `ana-dev` | `ana-prod` |
| Terraform State | `gs://ana-dev-tfstate` | `gs://ana-prod-tfstate` |
| Cloud Run 最小インスタンス | 0 | 1 |
| Cloud Scheduler 間隔 | 手動実行 | 10〜20 分 |

### State 管理

Terraform の State は GCS バケットで管理（ローカル保存・Git コミット禁止）。

```hcl
# environments/prod/main.tf
terraform {
  backend "gcs" {
    bucket = "ana-prod-tfstate"
    prefix = "terraform/state"
  }
}
```

State バケット自体は初回のみ手動作成（bootstrap）し、以降は Terraform で管理する。

### プロバイダ設定

Firebase 関連リソース（`google_firebase_project` 等）は `google-beta` プロバイダが必要。

```hcl
terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
    google-beta = {
      source  = "hashicorp/google-beta"
      version = "~> 5.0"
    }
  }
}
```

### Terraform 管理外のリソース

| リソース | 管理方法 | 理由 |
|---|---|---|
| Firebase Auth プロバイダ設定 | Firebase Console / CLI | Terraform サポートが限定的 |
| FCM 設定 | Firebase Console | Terraform 非対応 |
| APNs 証明書 | Firebase Console | 同上 |

## CI/CD（GitHub Actions 連携）

```
PR 作成時
  ↓
terraform fmt / validate / plan
  ↓
plan 結果を PR コメントに自動投稿

main マージ時
  ↓
terraform apply（自動）
  ↓
docker build → Artifact Registry プッシュ
  ↓
Cloud Run 自動デプロイ
```

- `environments/dev` は main マージで自動 apply
- `environments/prod` は GitHub Actions の手動承認ステップを挟む

## 開発環境（Docker）

ローカル開発では GCP 依存を最小化し、
`docker compose up` 一発で開発環境が立ち上がる構成にする。

### コンテナ構成

```
┌─────────────────────────────────────────┐
│ docker-compose.yml                      │
│                                         │
│  ┌──────────────┐      ┌──────────────┐  │
│  │    server    │ ───▶ │   postgres   │  │
│  │  (Echo API)  │      │    :5432     │  │
│  │    :8000     │      └──────────────┘  │
│  └──────────────┘                         │
│          │                                │
│          └───────────┐                    │
│                      ▼                    │
│               ┌──────────────┐            │
│               │   firebase   │            │
│               │   emulator   │            │
│               │ Auth :9099   │            │
│               │ UI   :4000   │            │
│               └──────────────┘            │
│                                            │
│  ┌──────────────┐      ┌──────────────┐   │
│  │    worker    │ ───▶ │   postgres   │   │
│  └──────────────┘      └──────────────┘   │
└─────────────────────────────────────────┘
```

### 各コンテナの詳細

| コンテナ名 | イメージ | ポート | 役割 |
|---|---|---|---|
| `server` | 自前 Dockerfile.dev（Air でホットリロード） | 8000 | Echo API サーバー |
| `worker` | 自前 `cmd/worker/Dockerfile` | - | Outbox ワーカー |
| `postgres` | `postgres:16-alpine` | 5432 | ローカル DB（Cloud SQL 代替） |
| `firebase-emulator` | `node:lts` + firebase-tools | 4000(UI) / 9099 | Auth Emulator |

### エミュレータ対応表

| 本番サービス | 開発環境での代替 |
|---|---|
| Cloud SQL（PostgreSQL） | Docker Compose の PostgreSQL コンテナ |
| Firebase Auth | Firebase Emulator Suite（Auth） |
| FCM（Android通知） | 開発環境では送信をスキップ or モック化 |
| APNs（iOS通知） | 開発環境ではスキップ（環境変数フラグで無効化） |
| Cloud Scheduler | 開発環境では手動実行で代替 |
| Vertex AI（Gemini） | モック実装（固定レスポンス返却） |
| Vertex AI（Lyria） | モック実装（サンプル音声ファイル返却） |
| Cloud Storage | ローカルファイルシステム or MinIO |

### 環境変数の切り替え

```
# .env.development（例）
FIREBASE_AUTH_EMULATOR_HOST=firebase-emulator:9099
DATABASE_URL=postgres://postgres:postgres@postgres:5432/hackathon?sslmode=disable

# Vertex AI（開発環境ではモック使用）
VERTEX_AI_PROJECT_ID=ana-dev
VERTEX_AI_LOCATION=us-central1
USE_MOCK_LYRIA=true
USE_MOCK_GEMINI=true
```

## 監視・アラート

- Cloud Logging でエラーログをフィルタ
- Log-based Alert → Discord Webhook で通知

## Vertex AI 設定

### API 有効化

```hcl
# modules/vertexai/main.tf
resource "google_project_service" "vertexai" {
  service = "aiplatform.googleapis.com"
}
```

### IAM 設定

```hcl
# Worker サービスアカウントに Vertex AI 権限付与
resource "google_project_iam_member" "worker_vertexai" {
  project = var.project_id
  role    = "roles/aiplatform.user"
  member  = "serviceAccount:${google_service_account.worker.email}"
}
```

### 生成楽曲保存バケット

```hcl
resource "google_storage_bucket" "generated_songs" {
  name     = "${var.project_id}-generated-songs"
  location = var.region

  uniform_bucket_level_access = true

  # temp/ 配下は1日で自動削除
  lifecycle_rule {
    condition {
      age = 1
      matches_prefix = ["temp/"]
    }
    action {
      type = "Delete"
    }
  }
}
```

## TBD（未決定）

- Cloud Run のリージョン（asia-northeast1 推奨だが要確認）
- Vertex AI のリージョン（Lyria は us-central1 のみ対応の可能性）
- CDN（生成楽曲配信の場合は検討）
