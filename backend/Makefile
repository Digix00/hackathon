.PHONY: run-dev stop-dev logs restart-dev db-shell tidy fmt clean

# ==============================================================================
# Docker Compose Commands
# ==============================================================================

# バックエンド環境をビルドしてバックグラウンドで起動
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
