# Phase 5: PoC後機能

通知、レート制限、タグ、短命トークン、オフライン対応、ログ解析の実装。

## 5.1 通知機能

### 5.1.1 通知基盤（Backend）

- [ ] **Backend** `internal/domain/entity/notification.go` 定義
- [ ] **Backend** `internal/domain/repository/notification.go` インターフェース定義
- [ ] **Backend** `internal/infra/rdb/notification.go` リポジトリ実装
- [ ] **Backend** Outbox パターン実装（確実な通知配信）

### 5.1.2 FCM / APNs 連携

- [ ] **Backend** `internal/infra/push/fcm.go` FCM クライアント実装
- [ ] **Backend** `internal/infra/push/apns.go` APNs クライアント実装
- [ ] **Backend** プッシュトークン登録 API 実装
- [ ] **Backend** 通知送信ユースケース実装

### 5.1.3 通知バッチ処理

- [ ] **Backend** `cmd/worker/notification.go` 通知ワーカー実装
- [ ] **Backend** 10〜20分間隔でのバッチ送信ロジック
- [ ] **Backend** 連投防止（同一ユーザーへの通知集約）
- [ ] **Infra** Cloud Scheduler 設定（10〜20分間隔）
- [ ] **Infra** Cloud Run Jobs 設定

### 5.1.4 通知バッジ表示

- [ ] **Backend** `GET /notifications/unread-count` - 未読通知数取得
- [ ] **Backend** すれ違い数をバッジに反映

### 5.1.5 iOS 通知

- [ ] **iOS** APNs 権限リクエスト
- [ ] **iOS** プッシュトークン取得・サーバー送信
- [ ] **iOS** 通知受信ハンドリング
- [ ] **iOS** 通知タップ時の画面遷移
- [ ] **iOS** バッジ数更新

### 5.1.6 Android 通知

- [ ] **Android** FCM 権限リクエスト
- [ ] **Android** プッシュトークン取得・サーバー送信
- [ ] **Android** 通知受信ハンドリング（FirebaseMessagingService）
- [ ] **Android** 通知タップ時の画面遷移
- [ ] **Android** 通知チャンネル設定

## 5.2 レート制限

### 5.2.1 レート制限実装（Backend）

- [ ] **Backend** `internal/handler/middleware/ratelimit.go` 実装
- [ ] **Backend** Token Bucket アルゴリズム実装
- [ ] **Backend** エンドポイント別レート設定
- [ ] **Backend** レート超過時の 429 レスポンス

### 5.2.2 レート制限ストレージ

- [ ] **Backend** Redis / Memorystore 導入（オプション）
- [ ] **Backend** インメモリキャッシュでのフォールバック

## 5.3 タグ機能

### 5.3.1 タグ基盤（Backend）

- [ ] **Backend** `internal/domain/entity/tag.go` 定義
- [ ] **Backend** `internal/domain/entity/user_tag.go` 定義
- [ ] **Backend** `internal/domain/repository/tag.go` インターフェース定義
- [ ] **Backend** `internal/infra/rdb/tag.go` リポジトリ実装

### 5.3.2 タグ API

- [ ] **Backend** `GET /tags` - タグ一覧取得（マスタ）
- [ ] **Backend** `POST /users/me/tags` - ユーザータグ設定
- [ ] **Backend** `GET /users/me/tags` - ユーザータグ取得
- [ ] **Backend** `DELETE /users/me/tags/:id` - ユーザータグ削除

### 5.3.3 タグ画面

- [ ] **iOS** タグ選択 UI（プロフィール編集）
- [ ] **iOS** タグ表示（すれ違い相手プロフィール）
- [ ] **Android** タグ選択 UI（プロフィール編集）
- [ ] **Android** タグ表示（すれ違い相手プロフィール）

## 5.4 短命トークン（セキュリティ強化）

### 5.4.1 BLE トークン毎日ローテーション

- [ ] **Backend** トークン有効期限を 24 時間に設定
- [ ] **Backend** 毎日 0:00 UTC に新トークン発行（自動）
- [ ] **Backend** 旧トークン→ユーザーマッピング保持（マッチング用）
- [ ] **iOS** アプリ起動時・バックグラウンド復帰時にトークン更新チェック
- [ ] **Android** アプリ起動時・バックグラウンド復帰時にトークン更新チェック

### 5.4.2 トークン追跡防止

- [ ] **Backend** トークン履歴の 30 日後自動削除
- [ ] **Backend** トークンと位置情報の分離保存

## 5.5 オフライン対応

### 5.5.1 オフラインキュー実装

- [ ] **iOS** すれ違いレコードのローカルキュー（Core Data）
- [ ] **iOS** ネットワーク復帰時の自動再送
- [ ] **iOS** 再送リトライ上限設定（5回）
- [ ] **iOS** 送信成功後のローカルレコード削除
- [ ] **Android** すれ違いレコードのローカルキュー（Room）
- [ ] **Android** ネットワーク復帰時の自動再送（WorkManager）
- [ ] **Android** 再送リトライ上限設定（5回）
- [ ] **Android** 送信成功後のローカルレコード削除

### 5.5.2 オフライン UI

- [ ] **iOS** オフライン状態表示
- [ ] **iOS** 未送信すれ違い数表示
- [ ] **Android** オフライン状態表示
- [ ] **Android** 未送信すれ違い数表示

## 5.6 ログ解析

### 5.6.1 クラッシュ解析

- [ ] **iOS** Firebase Crashlytics 導入
- [ ] **iOS** クラッシュレポート設定
- [ ] **Android** Firebase Crashlytics 導入
- [ ] **Android** クラッシュレポート設定

### 5.6.2 アナリティクス

- [ ] **iOS** Firebase Analytics 導入
- [ ] **iOS** カスタムイベント設計・実装
- [ ] **Android** Firebase Analytics 導入
- [ ] **Android** カスタムイベント設計・実装

### 5.6.3 Backend ログ解析

- [ ] **Infra** Cloud Logging でのログフィルタ設定
- [ ] **Infra** BigQuery エクスポート設定（オプション）
- [ ] **Infra** ダッシュボード作成（Cloud Monitoring）

## 5.7 Apple Music API 連携（オプション）

### 5.7.1 Apple Music 連携

- [ ] **Backend** `internal/infra/music/applemusic.go` 実装
- [ ] **Backend** Apple Music API 認証設定
- [ ] **Backend** 楽曲検索・詳細取得実装
- [ ] **iOS** MusicKit 連携
- [ ] **Android** Apple Music API 直接呼び出し

## 完了条件

- [ ] すれ違い時にプッシュ通知が届く
- [ ] 通知バッチ処理が 10〜20 分間隔で動作する
- [ ] レート制限が適用される
- [ ] タグの設定・表示ができる
- [ ] BLE トークンが毎日ローテーションされる
- [ ] オフライン時のすれ違いが後から送信される
- [ ] クラッシュログが Firebase Crashlytics に送信される
