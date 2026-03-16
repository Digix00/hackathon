.PHONY: run-dev stop-dev logs restart-dev db-shell tidy fmt clean reset-db \
        generate-docs generate-android generate-ios generate-code

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

# ==============================================================================
# Code Generation (全て Docker で完結。ホストへのツールインストール不要)
# ==============================================================================

# openapi-generator の Docker イメージ（クライアント生成に使用）
OPENAPI_GENERATOR_IMAGE := openapitools/openapi-generator-cli:v7.10.0

# 出力先（Makefile からの相対パス）
ANDROID_OUT := $(abspath ../android/app/src/main/java/com/digix00/musicswapping/generated)
IOS_OUT     := $(abspath ../ios/ios/Generated)

# Go アノテーションから swagger.json / docs パッケージを生成する
# server コンテナ内の swag を使うため、コンテナが起動していなくても動作するよう
# --no-deps で依存サービス（postgres / firebase-emulator）を起動しない
# --parseDependency: internal/ 配下の別パッケージ（schema 等）も解析対象にする
# --parseInternal:   internal パッケージのコメントも走査する
generate-docs:
	docker compose build server
	docker compose run --rm --no-deps server \
		swag init \
			--generalInfo cmd/server/main.go \
			--output docs \
			--parseDependency \
			--parseInternal
	@echo "==> docs/swagger.json を生成しました"

# swagger.json から Android (Kotlin + Retrofit2) クライアントを生成する
# openapitools/openapi-generator-cli の公式 Docker イメージを使用
# 出力先: android/app/src/main/java/com/digix00/musicswapping/generated/
generate-android: generate-docs
	@mkdir -p $(ANDROID_OUT)
	docker run --rm \
		-v $(CURDIR)/docs/swagger.json:/local/swagger.json \
		-v $(ANDROID_OUT):/local/out \
		$(OPENAPI_GENERATOR_IMAGE) generate \
			-i /local/swagger.json \
			-g kotlin \
			--library jvm-retrofit2 \
			--package-name com.digix00.musicswapping.generated \
			-o /local/out \
			--additional-properties=serializationLibrary=kotlinx_serialization,useCoroutines=true
	@echo "==> Android クライアントを生成しました → $(ANDROID_OUT)"

# swagger.json から iOS (Swift 5 + async/await) クライアントを生成する
# 出力先: ios/ios/Generated/
generate-ios: generate-docs
	@mkdir -p $(IOS_OUT)
	docker run --rm \
		-v $(CURDIR)/docs/swagger.json:/local/swagger.json \
		-v $(IOS_OUT):/local/out \
		$(OPENAPI_GENERATOR_IMAGE) generate \
			-i /local/swagger.json \
			-g swift5 \
			--package-name APIClient \
			-o /local/out \
			--additional-properties=responseAs=AsyncAwait,useSPMFileStructure=true
	@echo "==> iOS クライアントを生成しました → $(IOS_OUT)"

# swagger.json・Android クライアント・iOS クライアントをまとめて生成する
# generate-docs は generate-android / generate-ios の依存に含まれるが、
# 並列実行時の二重生成を避けるため先行して単独実行している
generate-code:
	$(MAKE) generate-docs
	$(MAKE) generate-android generate-ios
	@echo "==> 全コード生成が完了しました"
