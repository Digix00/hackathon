# バックエンド開発環境セットアップ

Docker Compose で以下を起動します。

- Firebase Emulator（Auth）
- PostgreSQL（Cloud SQL 代替）
- Backend Server（Go + Echo）
- Worker（Go）

`server` / `worker` コンテナは Air によりホットリロードで起動します。

## 前提

- Docker Desktop が起動していること
- Windows の場合、API 接続確認は `localhost` ではなく `127.0.0.1` を推奨

## 起動方法

```bash
make run-dev

起動状態確認:

```bash
docker compose ps
```

ログ確認（全コンテナのログを追従表示）:

```bash
make logs
```

個別コンテナのログ:

```bash
docker compose logs -f server
docker compose logs -f worker
```

## 開発用便利コマンド (Makefile)

`backend/Makefile` に頻繁に使うコマンドを定義しています。`backend` ディレクトリで実行してください。

- `make run-dev` : バックエンド環境のビルドとバックグラウンド起動
- `make stop-dev` : 環境の停止とコンテナ削除
- `make restart-dev` : 環境の再起動
- `make logs` : 全コンテナのログを追従して表示
- `make clean` : ボリューム（DB等）を含めて環境を完全に削除
- `make init-db` : ローカルDBにマイグレーションとシードデータを投入
- `make db-shell` : PostgreSQLコンテナ内のDBクライアント(`psql`)を起動
- `make tidy` : Goの依存パッケージ整理 (`go mod tidy`)
- `make fmt` : Goコードのフォーマット (`go fmt ./...`)

## 確認手順

### 1) API ヘルスチェック

```bash
curl -v http://127.0.0.1:8000/healthz
```

期待値:

```json
{"status":"ok"}
```

### 2) PostgreSQL 接続確認

```bash
curl -v http://127.0.0.1:8000/healthz/postgres
```

期待値（例）:

```json
{"status":"ok","db":"postgres","result":1}
```

このエンドポイントは PostgreSQL に対して `Ping` と `SELECT 1` を実行します。

### 3) Emulator UI

- http://127.0.0.1:4000/

### 4) デモデータ

開発環境では起動時にデモユーザー・トラック・encounter などのデモデータを自動で投入します。

- デモユーザー UID: `demo-user-1` / `demo-user-2` / `demo-user-3`
- デモ encounter: 2件（`demo-user-1` 視点で `demo-user-2` / `demo-user-3` が表示されます）
- デモトラック: 3件
- デモプレイリスト: 2件
- デモコメント: 2件（`demo-user-1` と `demo-user-2` のやり取り）
- デモ通知: 2件（`demo-user-1` 宛て）

iOS から動作確認する場合は `ios/README.md` の Firebase Auth Emulator 手順を参照してください。

### 5) 開発用認証バイパス（DEV_AUTH_TOKEN）

開発中のみ Firebase 検証をスキップできるトークンを利用できます（`GO_ENV=development` のみ有効）。

- `Authorization: Bearer <DEV_AUTH_TOKEN>` を送ると Firebase 検証を行わず通過します
- `DEV_AUTH_UID` を指定すると固定 UID で動作します（未指定なら `dev-user`）

設定例:

```
DEV_AUTH_TOKEN=dev-auth-token
DEV_AUTH_UID=demo-user-1
```

無効化したい場合は `.env.development` から `DEV_AUTH_TOKEN`, `DEV_AUTH_UID` を削除し、
`../docs/architecture/backend.md` の「削除手順」に従ってコード側を削除してください。

## 停止

```bash
make stop-dev
```

DBデータ等を完全に消去したい場合:

```bash
make clean
```

## 関連ファイル

- `Makefile` - 開発用コマンド定義
- `docker-compose.yml`
- `firebase.json`
- `.env.development`
- `cmd/server/main.go`
