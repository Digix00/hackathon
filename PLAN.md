# Terraform 実装計画

予算上限：$100/月以下

## 実装済みリソース（PR 作成前）

| ファイル | リソース |
|---|---|
| `apis.tf` | 13 API 有効化 |
| `artifact_registry.tf` | `google_artifact_registry_repository.app` + IAM binding |
| `iam.tf` | CloudRun SA / Scheduler SA / Terraform CI SA / WIF (GitHub OIDC) |
| `backend.tf` | GCS backend / provider 設定 |
| `variables.tf` | `project_id`, `region`, `github_repo` |

---

## デプロイフロー

PR をマージするだけで GitHub Actions が `terraform apply` を自動実行する。
**順序を守ってマージすること**（後の PR が前の PR のリソースを参照するため）。

```
PR#1 マージ → apply 自動実行
  └─→ PR#2 マージ → apply 自動実行
            └─→ PR#2 apply 完了後：外部シークレット4つを GCP Console から手動投入
                      └─→ PR#3 マージ → apply 自動実行
                                └─→ PR#4 マージ → apply 自動実行
                                          └─→ PR#5 マージ → apply 自動実行
```

---

## PR #1 — Cloud SQL ✅ 作成済み

**ファイル：** `cloudsql.tf`（新規）

| リソース | 設定 |
|---|---|
| `random_password.db` | 32文字英数字、Terraform が生成・State 管理 |
| `google_sql_database_instance.main` | PostgreSQL 16 / `db-f1-micro` / ZONAL / Public IP |
| `google_sql_database.app` | DB 名 `hackathon` |
| `google_sql_user.app` | ユーザー名 `appuser`、パスワードは `random_password.db.result` |

**コスト設計：**
- `db-f1-micro` で最小構成
- `disk_autoresize = false`、`disk_size = 10`（GB）で上限固定
- `backup_configuration.enabled = false`（バックアップ無効）
- `availability_type = "ZONAL"`（REGIONAL はコスト2倍のため不採用）

**接続方式：** Public IP + Cloud SQL Auth Proxy（VPC / Serverless VPC Access Connector 不要）

**出力：**
- `db_connection_name`：PR #4 の Cloud Run `cloud_sql_instances` annotation に使用
- `db_password`：sensitive=true（確認が必要な場合のみ `terraform output -raw db_password` で取得）

---

## PR #2 — Secret Manager + Worker SA

**ファイル：** `secret_manager.tf`（新規）、`iam.tf`（追記）、`apis.tf`（追記）

### secret_manager.tf

| リソース | 管理方法 | 備考 |
|---|---|---|
| `google_secret_manager_secret.db_password` + `secret_version` | Terraform 管理 | apply 時に `random_password.db.result` が自動登録される |
| `google_secret_manager_secret.spotify_client_id` | 箱のみ | apply 後に GCP Console から手動投入 |
| `google_secret_manager_secret.spotify_client_secret` | 箱のみ | 同上 |
| `google_secret_manager_secret.apple_music_key` | 箱のみ | 同上 |
| `google_secret_manager_secret.apns_key` | 箱のみ | 同上 |

### iam.tf 追記

| リソース | 権限 |
|---|---|
| `google_service_account.worker` | Worker SA 作成 |
| `worker_secret_accessor` | `roles/secretmanager.secretAccessor` |
| `worker_aiplatform_user` | `roles/aiplatform.user` |
| ~~`worker_storage_object_admin`~~ | ~~`roles/storage.objectAdmin`~~ → PR #3 でバケットレベル付与に変更（プロジェクトレベル付与はセキュリティリスクのため削除） |
| `worker_log_writer` | `roles/logging.logWriter` |
| `worker_cloudsql_client` | `roles/cloudsql.client` |

### apis.tf 追記

| 追加 API |
|---|
| `aiplatform.googleapis.com` |

**apply 後の手動作業（一度だけ）：**

GCP Console → Secret Manager → 対象シークレット → 「新しいバージョンを追加」から値を貼り付け。
ファイル系（`.p8`）もGUIからファイルアップロードで対応可能。

**依存：** PR #1 の apply 完了後にマージすること

---

## PR #3 — Cloud Storage

**ファイル：** `storage.tf`（新規）

### storage.tf

| リソース | 設定 |
|---|---|
| `google_storage_bucket.generated_songs` | `{project_id}-generated-songs` / STANDARD |
| `google_storage_bucket_iam_member.worker_writer` | Worker SA → `roles/storage.objectAdmin` |
| `google_storage_bucket_iam_member.cloudrun_reader` | CloudRun SA → `roles/storage.objectViewer` |

**依存：** PR #2 の apply 完了後 かつ 外部シークレット4つの手動投入完了後にマージすること

---

## PR #4 — Cloud Run Service & Job

**ファイル：** `cloudrun.tf`（新規）

| リソース | 設定 |
|---|---|
| `google_cloud_run_v2_service.api` | min=0 / max=2、Cloud SQL Auth Proxy 付き |
| `google_cloud_run_v2_service_iam_member.noauth` | `allUsers` → `roles/run.invoker`（パブリックアクセス） |
| `google_cloud_run_v2_job.worker` | cpu=1 / memory=512Mi |

**Secret Mount（Cloud Run Service の環境変数）：**

| 環境変数 | 参照先 |
|---|---|
| `SPOTIFY_CLIENT_ID` | `google_secret_manager_secret.spotify_client_id` |
| `SPOTIFY_CLIENT_SECRET` | `google_secret_manager_secret.spotify_client_secret` |
| `APPLE_MUSIC_KEY` | `google_secret_manager_secret.apple_music_key` |
| `APNS_KEY` | `google_secret_manager_secret.apns_key` |
| `DB_PASSWORD` | `google_secret_manager_secret.db_password` |

**Cloud SQL 接続：**
```hcl
annotations = {
  "run.googleapis.com/cloudsql-instances" = google_sql_database_instance.main.connection_name
}
```

**コスト設計：**
- `min_instance_count = 0` 必須（コールドスタート許容）
- `max_instance_count = 2` で上限固定

**依存：** PR #1 / #2 / #3 すべての apply 完了後にマージすること

---

## PR #5 — Cloud Scheduler

**ファイル：** `scheduler.tf`（新規）

| リソース | 設定 |
|---|---|
| `google_cloud_scheduler_job.worker_kick` | cron `*/10 * * * *`、Cloud Run Job の run エンドポイントを HTTP POST |

**依存：** PR #4 の apply 完了後にマージすること

---

## 予算見積もり（月額概算）

| サービス | 見積もり |
|---|---|
| Cloud SQL `db-f1-micro` | ~$10 |
| Cloud Run（min=0、低トラフィック） | ~$1 以下 |
| Cloud Run Jobs（10分間隔、短時間実行） | ~$1 以下 |
| Cloud Storage（生成楽曲、少量） | ~$1 以下 |
| Artifact Registry | ~$1 以下 |
| Cloud Scheduler | 無料枠内 |
| **合計** | **~$15 以下** |

Vertex AI (Lyria) はハッカソン期間中は `USE_MOCK_LYRIA=true` で制御し、実コストはほぼ発生しない想定。

---

## 環境変数・シークレットの設定状況

### Secret Manager（手動投入が必要なもの）

apply 後に GCP Console または `gcloud secrets versions add` で値を投入する。

| シークレット ID | 現在の状態 | 投入内容 |
|---|---|---|
| `spotify-client-id` | ⚠️ 未投入（ダミー or 空） | Spotify Developer Dashboard の Client ID |
| `spotify-client-secret` | ⚠️ 未投入（ダミー or 空） | Spotify Developer Dashboard の Client Secret |
| `apple-music-key` | ⚠️ 未投入（ダミー or 空） | Apple Music Key（.p8 ファイル内容） |
| `apns-key` | ⚠️ 未投入（ダミー or 空） | APNs Key（.p8 ファイル内容） |
| `music-state-secret` | ⚠️ 未投入 | 任意のランダム文字列（`openssl rand -base64 32`）|
| `music-token-encryption-key` | ⚠️ 未投入 | **64文字の16進数文字列**（`openssl rand -hex 32`）|
| `db-password` | ✅ Terraform 管理（自動投入済み） | — |

### Cloud Run 環境変数（Terraform 管理・今後修正が必要なもの）

| 環境変数 | 現在の状態 | 修正内容 |
|---|---|---|
| `SPOTIFY_REDIRECT_URL` | デフォルト値（localhost） | Cloud Run の URL に変更 |
| `APPLE_MUSIC_REDIRECT_URL` | デフォルト値（localhost） | Cloud Run の URL に変更 |
| `SPOTIFY_AUTHORIZE_URL` 等 | デフォルト値 | 本番 URL に問題なければそのまま |

`api_url` は `terraform output api_url` で取得できる。
