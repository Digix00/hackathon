.PHONY: run-dev stop-dev logs restart-dev db-shell tidy fmt clean reset-db test test-integration

# ==============================================================================
# Docker Compose Commands
# ==============================================================================

# バックエンド環境をビルドしてバックグラウンドで起動
# マイグレーションはサーバー起動時に自動実行される
run-dev:
	docker compose up --build -d

# 環境の停止（コンテナの削除）
stop-dev:
	docker compose down

# 全コンテナのログを表示（Ctrl+Cで終了）
logs:
	docker compose logs -f

# 環境の停止と再起動
restart-dev:
	docker compose down
	docker compose up --build -d

# ボリューム（DBデータ等）を含めて環境を完全に削除
clean:
	docker compose down -v

# DBを完全リセットして再起動（マイグレーション + シード自動実行）
# 動作確認環境を初期状態に戻したいときに使う
reset-db:
	docker compose down -v
	docker compose up --build -d

# ==============================================================================
# Utility Commands
# ==============================================================================

# Postgresデータベースのシェルに入る
db-shell:
	docker compose exec postgres psql -U postgres -d hackathon

# Goパッケージの依存関係を整理
tidy:
	go mod tidy

# Goコードのフォーマット
fmt:
	go fmt ./...

# ユニット/通常テストを実行
test:
	go test ./...

# PostgreSQL コンテナを使う統合テストを実行（Docker 起動後に実行）
# 必要に応じて PG_TEST_DATABASE_URL を上書き可能
test-integration:
	go test -tags=integration ./internal/handler -run PostgresIntegration
