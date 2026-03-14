# hackathon 開発環境セットアップ

このリポジトリは Docker Compose で以下を起動します。

- Firebase Emulator（Auth）
- PostgreSQL（Cloud SQL 代替）
- Backend Server（Go + Echo）
- Worker（Go）

`server` / `worker` コンテナは Air によりホットリロードで起動します。

## 前提

- Docker Desktop が起動していること
- Windows の場合、API 接続確認は `localhost` ではなく `127.0.0.1` を推奨

## 起動方法

```powershell
cd backend
docker compose up --build -d
```

起動状態確認:

```powershell
docker compose ps
```

Air ログ確認（任意）:

```powershell
docker compose logs -f server
docker compose logs -f worker
```

## 確認手順

### 1) API ヘルスチェック

```powershell
curl.exe -v http://127.0.0.1:8000/healthz
```

期待値:

```json
{"status":"ok"}
```

### 2) PostgreSQL 接続確認

```powershell
curl.exe -v http://127.0.0.1:8000/healthz/postgres
```

期待値（例）:

```json
{"status":"ok","db":"postgres","result":1}
```

このエンドポイントは PostgreSQL に対して `Ping` と `SELECT 1` を実行します。

### 3) Emulator UI

- http://127.0.0.1:4000/

## 停止

```powershell
docker compose down
```

## 関連ファイル

- `backend/docker-compose.yml`
- `backend/firebase.json`
- `backend/.env.development`
- `backend/cmd/server/main.go`
