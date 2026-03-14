# Phase 1: インフラ・認証基盤

ログ収集、認証、データベース基盤の構築。

## 1.1 インフラ基盤構築

### 1.1.1 GCP プロジェクト初期セットアップ

- [ ] **Infra** GCP プロジェクト作成（dev / prod）
- [ ] **Infra** Terraform State 用 GCS バケット作成（bootstrap）
- [ ] **Infra** IAM / Service Account 初期設定

### 1.1.2 Terraform モジュール実装

- [ ] **Infra** `modules/iam/` - Service Account・IAM バインディング
- [ ] **Infra** `modules/registry/` - Artifact Registry リポジトリ
- [ ] **Infra** `modules/cloudrun/` - Cloud Run service（API）
- [ ] **Infra** `modules/storage/` - Cloud Storage バケット（State / 画像）
- [ ] **Infra** `modules/logging/` - Log-based Alert → Discord Webhook

### 1.1.3 データベース構築

- [ ] **Infra** `modules/cloudsql/` - Cloud SQL（PostgreSQL）インスタンス
- [ ] **Backend** Cloud SQL 接続設定（`internal/infra/rdb/client.go`）
- [ ] **Backend** マイグレーション基盤導入（golang-migrate など）

### 1.1.4 開発環境構築

- [ ] **Backend** `docker-compose.yml` 作成
- [ ] **Backend** `cmd/server/Dockerfile` 作成
- [ ] **Backend** PostgreSQL コンテナ設定（Cloud SQL 代替）
- [ ] **Backend** Firebase Auth Emulator コンテナ設定
- [ ] **Backend** ホットリロード設定（Air）

## 1.2 ログ基盤構築

### 1.2.1 構造化ログ実装

- [ ] **Backend** `logger/logger.go` 実装（zap）
- [ ] **Backend** リクエストログミドルウェア実装
- [ ] **Backend** エラーログフォーマット統一

### 1.2.2 ログ収集・アラート

- [ ] **Infra** Cloud Logging 設定
- [ ] **Infra** Log-based Alert 作成（error レベル）
- [ ] **Infra** Discord Webhook 連携設定

## 1.3 認証基盤構築

### 1.3.1 Firebase Auth セットアップ

- [ ] **Infra** Firebase プロジェクト作成
- [ ] **Infra** Sign in with Apple 設定
- [ ] **Infra** Google Sign-In 設定

### 1.3.2 Backend 認証実装

- [ ] **Backend** Firebase Admin SDK 導入
- [ ] **Backend** `internal/infra/auth/firebase.go` 実装
- [ ] **Backend** `internal/handler/middleware/auth.go` 実装
- [ ] **Backend** 認証エラーハンドリング実装

### 1.3.3 iOS 認証実装

- [ ] **iOS** Sign in with Apple 実装
- [ ] **iOS** Firebase Auth 連携
- [ ] **iOS** ID トークン取得・保持
- [ ] **iOS** トークンリフレッシュ処理

### 1.3.4 Android 認証実装

- [ ] **Android** Google Sign-In 実装
- [ ] **Android** Firebase Auth 連携
- [ ] **Android** ID トークン取得・保持
- [ ] **Android** トークンリフレッシュ処理

## 1.4 ユーザー管理基盤

### 1.4.1 ユーザー CRUD

- [ ] **Backend** `internal/domain/entity/user.go` 定義
- [ ] **Backend** `internal/domain/repository/user.go` インターフェース定義
- [ ] **Backend** `internal/infra/rdb/user.go` リポジトリ実装
- [ ] **Backend** `internal/usecase/user.go` ユースケース実装
- [ ] **Backend** `internal/handler/user.go` ハンドラ実装

### 1.4.2 ユーザー API

- [ ] **Backend** `POST /users` - ユーザー登録
- [ ] **Backend** `GET /users/me` - 自分の情報取得
- [ ] **Backend** `PATCH /users/me` - プロフィール更新
- [ ] **Backend** `DELETE /users/me` - アカウント削除（論理削除）

### 1.4.3 プロフィール画面（MVP）

- [ ] **iOS** プロフィール表示画面
- [ ] **iOS** プロフィール編集画面
- [ ] **Android** プロフィール表示画面
- [ ] **Android** プロフィール編集画面

## 1.5 CI/CD 構築

### 1.5.1 GitHub Actions

- [ ] **Infra** Backend テスト・ビルドワークフロー
- [ ] **Infra** Terraform plan/apply ワークフロー
- [ ] **Infra** Docker イメージビルド・プッシュ
- [ ] **Infra** Cloud Run 自動デプロイ
- [ ] **Infra** PR コメントへの plan 結果投稿

## 完了条件

- [ ] dev 環境で API サーバーが起動し、ログが Cloud Logging に出力される
- [ ] iOS / Android から Sign in with Apple / Google でログインできる
- [ ] ユーザー登録・取得・更新・削除が動作する
