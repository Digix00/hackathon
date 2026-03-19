# CI/CD 設計

## 全体フロー

```
PR 作成（feature/* → develop）
  ↓
[CI] lint / test / schema チェック / terraform plan
  ↓ approve & merge to develop
[CD] ビルド → dev 自動デプロイ → スキーマ生成・配布
  ↓ develop → main へ PR & merge
[CD] prod 自動デプロイ
```

## PR 時（CI）

| ジョブ | 内容 |
|---|---|
| `lint` | `go fmt` / `go vet` / `golangci-lint` |
| `test` | `go test ./...` |
| `schema-lint` | `spectral lint schema/openapi.yaml`（OpenAPI 仕様の構文・ルール検証） |
| `schema-diff` | `oasdiff breaking`（破壊的変更を検出 → 変更があれば CI をブロック） |
| `codegen-check` | コード生成を実行し、リポジトリ内の生成コードと差分がないか確認 |
| `terraform-plan` | `environments/dev` の `terraform plan` を実行し結果を PR コメントに投稿 |

## develop マージ時（CD）

### 1. ビルド・dev デプロイ

```
docker build → Artifact Registry プッシュ
    ↓
Cloud Run（dev）自動デプロイ
    ↓
terraform apply（environments/dev）
```

### 2. スキーマ生成・配布

スキーマに変更があった場合のみ実行。

```
oapi-codegen → Go 生成コードを自動コミット（同リポジトリ）
    ↓
swift-openapi-generator → iOS リポジトリに PR を自動作成
openapi-generator       → Android リポジトリに PR を自動作成
```

## main マージ時（CD）

`develop` → `main` への PR がマージされると自動的に prod デプロイが実行される。

```
terraform apply（infra/main）          ← infra/main/** 変更時
    ↓
docker build → Artifact Registry プッシュ
    ↓
Cloud Run（prod）デプロイ              ← backend/** 変更時
    ↓
migrate Job ビルド・プッシュ・実行     ← model/** / migrate.go 変更時
```

### ワークフロー一覧

| ワークフロー | トリガーパス | 内容 |
|---|---|---|
| `tf-apply.yml` | `infra/main/**` | Terraform apply（インフラ変更） |
| `deploy.yml` | `backend/**` | API・Worker イメージビルド & Cloud Run 更新 |
| `migrate.yml` | `backend/internal/infra/rdb/model/**`, `backend/cmd/migrate/**` | migrate イメージビルド & DB マイグレーション実行 |

## GCP 認証（Workload Identity Federation）

GitHub Actions から GCP への認証は、サービスアカウントキーファイルを使わず
**Workload Identity Federation** で行う。キーファイルを GitHub Secrets に保存しないため、
キーのローテーション管理が不要でセキュリティリスクが低い。

```yaml
# .github/workflows/deploy.yml（抜粋）
- uses: google-github-actions/auth@v2
  with:
    workload_identity_provider: projects/PROJECT_NUMBER/locations/global/workloadIdentityPools/POOL/providers/PROVIDER
    service_account: github-actions@ana-prod.iam.gserviceaccount.com
```

Terraform でプロバイダ・サービスアカウント・IAM バインディングを管理する。

## ブランチ戦略

| ブランチ | 役割 |
|---|---|
| `develop` | デフォルトブランチ。dev 環境への自動デプロイトリガー |
| `main` | prod 環境への自動デプロイトリガー。`develop` からのマージのみ受け付ける |
| `feature/*` | 機能開発。PR で `develop` にマージ |

## シークレット管理

アプリケーションが使用するシークレット（Spotify クライアントシークレット等）は
**GCP Secret Manager** で管理し、Cloud Run の起動時に環境変数として注入する。
GitHub Secrets には Workload Identity Federation の設定値のみ保持する。

```
GCP Secret Manager
  ├── spotify-client-secret
  ├── apple-music-key
  └── apns-key

↓ Cloud Run の環境変数として自動マウント
```

Terraform で Secret のリソース定義と Cloud Run へのマウント設定を管理する。
