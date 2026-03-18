# バックエンド技術スタック

## 基本構成

| 項目 | 採用技術 |
|---|---|
| 言語 | Go |
| フレームワーク | Echo |
| API 設計 | REST (JSON) |
| DB | Cloud SQL（PostgreSQL） |

## アーキテクチャ

Clean Architecture に基づく層構成。依存の方向は常に外側から内側（domain）へ。

```
[handler] → [usecase] → [domain] ← [infra]
                ↑
           port/ でインターフェースを定義し
           infra/ が実装を提供（依存性逆転）
```

- `domain` は外部のいかなるパッケージにも依存しない
- `usecase/port/` が外部サービス（通知・音楽API・タスクキュー）のインターフェースを定義し、`infra/` がその実装を提供することで依存を逆転させる
- アプリ固有コードはすべて `internal/` に置き、外部からの import を防ぐ

## ディレクトリ構成

```
.
├── cmd/
│   ├── server/                    # API サーバーのエントリーポイント
│   │   ├── Dockerfile
│   │   └── main.go
│   └── worker/                    # バックグラウンドワーカーのエントリーポイント
│       ├── Dockerfile
│       └── main.go
│
├── internal/
│   │
│   ├── handler/                   # HTTP 層
│   │   ├── middleware/
│   │   │   └── auth.go            # Firebase Auth 検証ミドルウェア
│   │   ├── schema/
│   │   │   ├── request/           # リクエストボディの構造体・バリデーション
│   │   │   └── response/          # レスポンスボディの構造体
│   │   ├── router.go              # ルーティング定義
│   │   ├── di.go                  # 依存注入（DI）
│   │   ├── user.go
│   │   ├── exchange.go
│   │   └── lyric.go               # 歌詞チェーン・生成楽曲 API
│   │
│   ├── usecase/                   # ユースケース（ビジネスフロー）
│   │   ├── port/                  # 外部依存のインターフェース定義
│   │   │   ├── notification.go    # APNs / FCM
│   │   │   ├── music.go           # Spotify / Apple Music
│   │   │   ├── lyria.go           # Lyria 楽曲生成 API
│   │   │   └── gemini.go          # Gemini 歌詞分析・モデレーション
│   │   ├── dto/                   # ユースケース間のデータ転送オブジェクト
│   │   ├── user.go
│   │   ├── exchange.go
│   │   ├── lyric.go               # 歌詞チェーン機能
│   │   ├── ble_token.go
│   │   └── worker.go
│   │
│   ├── domain/
│   │   ├── entity/                # ドメインエンティティ
│   │   ├── vo/                    # 値オブジェクト（性別・ステータス等の型）
│   │   ├── repository/            # DB リポジトリのインターフェース定義
│   │   ├── query/                 # クエリオプション型
│   │   └── errs/                  # ドメインエラー定義
│   │
│   └── infra/
│       ├── rdb/                   # Cloud SQL（PostgreSQL）関連を集約
│       │   ├── model/             # DB レコードの構造体
│       │   ├── converter/         # entity ↔ model の変換
│       │   ├── client.go          # DB クライアント初期化
│       │   ├── user.go
│       │   ├── exchange.go
│       │   └── lyric.go           # 歌詞チェーン・生成楽曲リポジトリ
│       ├── auth/                  # Firebase Auth 検証 + JWT 生成
│       ├── notification/          # APNs / FCM の実装（port/notification.go を実装）
│       ├── music/                 # Spotify / Apple Music の実装（port/music.go を実装）
│       ├── lyria/                 # Lyria 楽曲生成の実装（port/lyria.go を実装）
│       ├── gemini/                # Gemini 歌詞分析の実装（port/gemini.go を実装）
│       └── storage/               # Cloud Storage（生成楽曲保存）
│
├── config/
│   └── config.go                  # 環境変数読み込み
│
└── logger/
    └── logger.go                  # 構造化ログ設定（zap）
```

## API ドキュメント自動生成（swaggo）

バックエンドは [swaggo](https://github.com/swaggo/swag) を使って OpenAPI 2.0 ドキュメントを自動生成する。

### 生成コマンド

```bash
make generate-docs
```

`docs/` 配下の `docs.go` / `swagger.json` / `swagger.yaml` が更新される。**生成後の差分も PR に含めること。**

> `make generate-docs` を実行すると `docs/` の変更を `air` が検知して開発サーバーが自動リビルドされる。

Swagger UI は development / test 環境のみ `http://localhost:8000/swagger/index.html` で確認できる。

### 新しいエンドポイントを追加するときの必須手順

**新しいエンドポイントを追加した場合は必ず、ハンドラー関数の直前に swaggo アノテーションを付ける。**
アノテーションが欠けると `make generate-docs` でそのエンドポイントが生成ドキュメントから消え、クライアント SDK の自動生成に影響する。

#### アノテーションテンプレート

```go
// handlerFunc godoc
// @Summary      エンドポイントの一行説明
// @Description  詳細説明
// @Tags         グループ名（users / settings / push-tokens / health など）
// @Accept       json                        ← リクエストボディがある場合のみ
// @Produce      json
// @Security     BearerAuth                  ← 認証が必要なエンドポイントのみ
// @Param        body  body  pkg.ReqStruct  true  "説明"   ← リクエストボディ
// @Param        id    path  string         true  "説明"   ← パスパラメータ
// @Success      200   {object}  pkg.ResStruct
// @Failure      400   {object}  errorResponse
// @Failure      401   {object}  errorResponse
// @Failure      404   {object}  errorResponse
// @Failure      500   {object}  errorResponse
// @Router       /api/v1/your-path/{id} [method]
func (h *handler) handlerFunc(c echo.Context) error {
```

#### 重要なルール

| 項目 | ルール |
|---|---|
| `@Router` のパス | **`/api/v1/...` のフルパスで書く**（`@BasePath` が `/` のため） |
| `healthz` など認証不要なエンドポイント | `@Security BearerAuth` を省く・`/healthz` のパスをそのまま使う |
| レスポンス型 | `internal/handler/schema/response/` の構造体を参照する |
| リクエスト型 | `internal/handler/schema/request/` の構造体を参照する |
| エラーレスポンス型 | `errorResponse`（`internal/handler/error_mapper.go` で定義済み） |
| 204 No Content | `// @Success 204` のみ（`{object}` 不要） |

### swaggo 設定概要

| 設定項目 | 値 |
|---|---|
| 基準ファイル | `cmd/server/main.go`（`@title`, `@BasePath` 等を定義） |
| `@BasePath` | `/`（`@Router` には `/api/v1/...` フルパスを書く） |
| 認証方式 | `BearerAuth`（`Authorization: Bearer <Firebase ID Token>`） |

---

## 主要ライブラリ

| ライブラリ | 用途 |
|---|---|
| `github.com/labstack/echo/v4` | HTTP フレームワーク |
| `github.com/jackc/pgx/v5` | PostgreSQL クライアント（Cloud SQL） |
| `firebase.google.com/go/v4` | Firebase Admin SDK（Auth 含む） |
| `github.com/golang-jwt/jwt/v5` | JWT 生成・検証 |
| `github.com/go-playground/validator/v10` | リクエストバリデーション |
| `go.uber.org/zap` | 構造化ログ |
| `github.com/kelseyhightower/envconfig` | 環境変数バインド |
| `google.golang.org/api` | GCP クライアント共通ライブラリ |
| `cloud.google.com/go/vertexai` | Vertex AI SDK（Gemini） |
| `cloud.google.com/go/aiplatform` | Vertex AI SDK（Lyria） |
| `cloud.google.com/go/storage` | Cloud Storage クライアント |
| `https://github.com/guregu/null` | nil フィールドハンドリング |

## 認証フロー

1. クライアントが Apple / Google でサインイン → Firebase ID トークン取得
2. ID トークンを Bearer ヘッダに付けて Backend へ送信
3. `internal/handler/middleware/auth.go` が Firebase Admin SDK で検証 → UID をコンテキストに格納
4. 以降のハンドラは UID をコンテキストから取り出して処理

## 定期実行交換処理

BLE 交換イベントの書き込みと通知送信を非同期に分離する設計。

```
BLE 交換成立
    ↓
交換レコード + Outbox レコードを Cloud SQL にアトミック書き込み（トランザクション）
    ↓
[cmd/worker] が Outbox を定期スキャン・集約して APNs / FCM に通知送信
```

- Cloud Scheduler が worker を 10〜20 分間隔でキック（Cloud Run Jobs）
- 通知の集約（まとめて「N人とすれ違いました」）は worker 内で制御
- 配信失敗時は Outbox レコードを pending に戻してリトライ（最大 3 回。超過後は failed に遷移し、アラートを発報）

## BLE 短命トークン設計

- BLE ID は発行時刻から 24 時間有効（`valid_to = issued_at + 24h`）
- worker のバッチ処理で期限切れトークンを定期削除（Cloud SQL の WHERE valid_to < NOW()）
- クライアントは起動時またはトークン期限切れ時に新しい ID を取得

## レート制限

- Cloud SQL の UPSERT + SELECT FOR UPDATE で実装
- 1日の交換上限はしきい値を設定値として管理（3 / 5 / 10 / 50 / 100）
- 現在の実装では暫定値として 10 を使用（`dailyEncounterUserLimit = 10`）
- カウンタ超過時はドメインエラーとして `internal/domain/errs/` に定義

### ハッカソン暫定の割り切り（設計との差分）

- **SELECT FOR UPDATE 省略**: 実装は UPSERT のみでトランザクション内に収めている。ハッカソン期間中は厳密なロック手順を省略する。
- **日次カウントは送信側のみ**: `POST /encounters` を呼んだユーザーのみ日次カウントを増やす。相手側へのカウント適用は省略する。
- **冪等判定の基準時刻**: 5分以内の重複判定は `encountered_at`（クライアント時刻）を基準に行う。クライアント側が時刻をずらして重複を作成できるが、ハッカソン期間中は許容する。

## ログ方針

- `go.uber.org/zap` による構造化ログ（info / error）
- Cloud Logging（GCP）へ自動転送
- アラートは Cloud Logging の Log-based Alert → Discord Webhook

## 歌詞チェーン処理（Lyric Chain）

すれ違い時に投稿された歌詞を集約し、Lyria で楽曲を自動生成する機能。
詳細は [lyric-chain.md](./lyric-chain.md) を参照。

### 処理フロー

```
すれ違い成立 → 歌詞投稿
    ↓
Gemini でコンテンツモデレーション
    ↓
LyricChain に追加（新規 or 既存）
    ↓
参加者数 >= 閾値（4〜8人）?
    ↓ Yes
Outbox に生成ジョブ追加
    ↓
[cmd/worker] が Lyria 生成処理を実行
    ├─ Gemini で歌詞分析（ムード・ジャンル推定）
    ├─ Lyria で楽曲生成
    └─ Cloud Storage にアップロード
    ↓
GeneratedSong レコード作成
    ↓
参加者全員への通知を Outbox に追加
```

### 追加エンティティ

| エンティティ | 説明 |
|---|---|
| LyricChain | 歌詞チェーン（4〜8人分の歌詞を保持） |
| LyricEntry | 個別の歌詞エントリ |
| GeneratedSong | Lyria で生成された楽曲 |

### 追加 API

| メソッド | パス | 説明 |
|---|---|---|
| POST | `/api/v1/lyrics` | 歌詞投稿 |
| GET | `/api/v1/lyrics/chains/{chain_id}` | チェーン詳細取得 |
| GET | `/api/v1/users/me/songs` | 自分が参加した生成楽曲一覧 |
