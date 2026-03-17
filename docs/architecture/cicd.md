# CI/CD 設計

## 全体フロー

```
PR 作成
  ↓
[CI] lint / test / schema チェック / terraform plan
  ↓ approve & merge to main
[CD] ビルド → dev 自動デプロイ → スキーマ生成・配布
  ↓ 手動承認
[CD] prod デプロイ
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

## main マージ時（CD）

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

### 3. prod デプロイ（手動承認）

GitHub Actions の `environment: production` を使い、
指定したレビュアーの承認後に実行される。

```
手動承認
    ↓
terraform apply（environments/prod）
    ↓
Cloud Run（prod）デプロイ
```

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
| `main` | dev 環境への自動デプロイトリガー |
| `release/*` | prod デプロイ候補（手動承認後に prod 反映） |
| `feature/*` | 機能開発。PR で main にマージ |

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
