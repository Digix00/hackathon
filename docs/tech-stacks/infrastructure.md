# インフラ技術スタック

Firestore を採用するため GCP をベースプラットフォームとする。
インフラは Terraform で IaC 管理し、環境ごとの差異をコードで表現する。

## GCP サービス構成

| サービス | 用途 | Terraform 管理 |
|---|---|---|
| Cloud Firestore | メイン DB（ネイティブモード） | ✅ |
| Cloud Run | Backend API のホスティング | ✅ |
| Cloud Run Jobs | 通知バッチ処理（worker） | ✅ |
| Cloud Scheduler | worker を定期キック（10〜20分間隔） | ✅ |
| Firebase Auth | 認証基盤（Apple / Google Sign-In） | 部分的（Firebase CLI 併用） |
| Firebase Cloud Messaging (FCM) | Android プッシュ通知 | Firebase Console |
| Artifact Registry | Docker イメージ管理 | ✅ |
| Cloud Storage | Terraform State 保存 / プロフィール画像（MVP 後） | ✅ |
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
    ├── firestore/            # Firestore データベース・インデックス
    ├── scheduler/            # Cloud Scheduler ジョブ
    ├── registry/             # Artifact Registry リポジトリ
    ├── storage/              # Cloud Storage バケット
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

ローカル開発ではすべての GCP サービスをエミュレータに置き換え、
`docker compose up` 一発で開発環境が立ち上がる構成にする。

### コンテナ構成

```
┌─────────────────────────────────────────┐
│ docker-compose.yml                      │
│                                         │
│  ┌──────────────┐   ┌────────────────┐  │
│  │    server    │──▶│    firebase    │  │
│  │  (Echo API)  │   │    emulator    │  │
│  │    :8000     │   │  Firestore     │  │
│  └──────────────┘   │  :8080         │  │
│                     │  Auth  :9099   │  │
│  ┌──────────────┐   │  FCM   :4500   │  │
│  │    worker    │──▶│  UI    :4000   │  │
│  └──────────────┘   └────────────────┘  │
└─────────────────────────────────────────┘
```

### 各コンテナの詳細

| コンテナ名 | イメージ | ポート | 役割 |
|---|---|---|---|
| `server` | 自前 Dockerfile.dev（Air でホットリロード） | 8000 | Echo API サーバー |
| `worker` | 自前 `cmd/worker/Dockerfile` | - | Outbox ワーカー |
| `firebase-emulator` | `node:lts` + firebase-tools | 4000(UI) / 8080 / 9099 / 4500 | Firestore・Auth・FCM |

### エミュレータ対応表

| 本番サービス | 開発環境での代替 |
|---|---|
| Cloud Firestore | Firebase Emulator Suite（Firestore） |
| Firebase Auth | Firebase Emulator Suite（Auth） |
| FCM（Android通知） | Firebase Emulator Suite（FCM）※実端末には届かない |
| APNs（iOS通知） | 開発環境ではスキップ（環境変数フラグで無効化） |
| Cloud Scheduler | 開発環境では手動実行で代替 |

### 環境変数の切り替え

```
# .env.development（例）
FIRESTORE_EMULATOR_HOST=firebase-emulator:8080
FIREBASE_AUTH_EMULATOR_HOST=firebase-emulator:9099
FIREBASE_MESSAGING_EMULATOR_HOST=firebase-emulator:4500
```

## 監視・アラート

- Cloud Logging でエラーログをフィルタ
- Log-based Alert → Discord Webhook で通知

## TBD（未決定）

- Cloud Run のリージョン（asia-northeast1 推奨だが要確認）
- Firestore のセキュリティルール設計（クライアント直アクセスをどこまで許可するか）
- CDN（プロフィール画像配信が必要になった場合）
