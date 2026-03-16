# Backend Review Ready Notes

このブランチは**新規エンドポイント追加なし**で、既存スコープ（users / settings / push-tokens）の実装・削除要件強化・テスト整備をレビュー可能な状態に整理したものです。

## 1. レビュー対象（主変更）

- ルーティング/DI
  - `cmd/server/main.go`
  - `internal/handler/router.go`
- 認証/共通エラー
  - `internal/handler/middleware/auth.go`
  - `internal/handler/error_mapper.go`
- ユーザー系API
  - `internal/handler/user.go`
  - `internal/handler/settings.go`
  - `internal/handler/push_token.go`
- DTO
  - `internal/handler/schema/request/*`
  - `internal/handler/schema/response/*`
- テスト
  - `internal/handler/middleware/auth_test.go`
  - `internal/handler/error_mapper_test.go`
  - `internal/handler/router_test.go`
  - `internal/handler/router_postgres_integration_test.go` (build tag: integration)
- 実行導線
  - `Makefile` (`test`, `test-integration`)
  - `.github/workflows/backend-integration.yml`

## 2. 仕様整合で重点確認してほしい点

1. `DELETE /users/me` の関連データ削除範囲
   - encounter/comment/playlist/block/mute/report/track/outbox 等の削除
2. lyric の削除・保持ルール
   - 単独チェーン: 削除
   - 他ユーザー参加チェーン: 匿名ユーザー（`system/deleted-user`）へ `lyric_entries.user_id` を付け替え
3. 共通エラー形式
   - `{"error": {"code", "message", "details"}}` に統一

## 3. テスト証跡（最新）

- Unit/通常: PostgreSQL を使った API テスト（`go test ./...`）
- Integration(PostgreSQL): `make test-integration`
  - 実行結果: `ok hackathon/internal/handler`

## 4. 今回あえて触っていないもの

- 新規API実装（music-connections / tracks / notifications など）
- スキーマ生成ブランチ統合作業

## 5. レビュー観点メモ（設計判断）

- 未実装ルートは panic ではなく 501 + warning ログ運用
- PostgreSQL を単体/統合の両テストで利用し、DB 方言差異を排除
- 共有 lyric 匿名化の表示名は API設計書記載に合わせ `"削除済みユーザー"` を設定
