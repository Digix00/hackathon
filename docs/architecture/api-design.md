# API設計書

## 共通仕様

- ベースパスは `/api/v1` とする。
- 特に明記がない限り、すべてのエンドポイントは認証必須とし、`Authorization: Bearer <Firebase ID Token>` を付与する。
- 日時はすべて ISO 8601 形式（例: `2026-03-15T09:30:00Z`）で返す。
- 一覧取得 API の `cursor` は不透明なトークンであり、クライアントは解釈せずそのまま再送する。
- 一覧取得 API の `limit` は特に明記がない限り省略時 20、最大 50 とする。
- 一覧取得 API の並び順は特に明記がない限り `created_at` 降順（新しい順）とする。`occurred_at` を持つリソースは `occurred_at` 降順を優先する。
- 特に記載がない限り、レスポンスの `id` は UUID を想定する。
- ただしトラック系リソースの `id` / `track_id` / パスパラメータ `{id}` は例外として `<provider>:track:<external_id>` 形式の外部識別子を使用する（例: `spotify:track:123`）。DB スキーマでは `tracks.provider` と `tracks.external_id` の組み合わせに対応する。

### 共通エラー形式

失敗時のレスポンスボディは以下の形式に統一する。

```json
{
  "error": {
    "code": "BLE_TOKEN_NOT_FOUND",
    "message": "Active BLE token was not found.",
    "details": null
  }
}
```

- `code`: クライアントが分岐に使うアプリケーション固有のエラーコード
- `message`: ログ・デバッグ用途の説明文
- `details`: バリデーションエラー等の補足情報。不要な場合は `null`

代表例:

- **400 Bad Request**: リクエスト形式不正、許可されない enum 値
- **401 Unauthorized**: Firebase ID Token 不正、または未指定
- **404 Not Found**: 対象リソース未存在、またはアクセス不可を秘匿する場合
- **409 Conflict**: 重複投稿や、現在の状態では受け付けられない操作

## music-connections/auth

`provider` は `spotify` または `apple_music` を受け付ける。

### GET /music-connections/{provider}/authorize

指定した音楽サービスの OAuth 認可フローを開始する。
クライアントはレスポンスの `authorize_url` にユーザーをリダイレクトする。
`state` は CSRF トークンであり、クライアント側でセッション等に保存し、コールバック時に検証すること。
このエンドポイントは認証必須であり、サーバーは `Authorization` ヘッダーの Firebase ユーザーに対して連携開始情報を発行する。
`state` には CSRF 用 nonce に加え、連携開始時の Firebase ユーザーを特定するためのサーバー署名済みコンテキストを含める。

**Path Params**: `provider`（`spotify` | `apple_music`）

**Response (200)**

```json
{
  "authorize_url": "https://accounts.spotify.com/authorize?...",
  "state": "signed-context-and-csrf-token"
}
```

### GET /music-connections/{provider}/callback

指定した音楽サービスがユーザーを返すリダイレクト先。
サービスから `code`・`state` がクエリパラメータで付与される。
サーバーは `state` を検証し、`code` を使ってアクセストークンを取得し、`state` に含まれるサーバー署名済みユーザーコンテキストを用いて Firebase ユーザーと音楽サービスアカウントを紐付ける。
このエンドポイントでは `Authorization` ヘッダーは必須とせず、連携対象ユーザーの特定は `state` の検証結果だけで行う。
コールバック完了後は JSON を返さず、アプリが受け取れる Deep Link（例: `digix://music-connections/{provider}/callback?result=success`）へ **302 Found** でリダイレクトする。
失敗時は `result=error` と `error_code` を付与して同様にリダイレクトする。

**Path Params**: `provider`（`spotify` | `apple_music`）

**Query**: `code`（認可コード）, `state`（CSRF 検証用 nonce とサーバー署名済みユーザーコンテキストを含む値）

**Response (302 Found)**

- `Location: digix://music-connections/{provider}/callback?result=success`

## music-connections

`music_connections` テーブルに対応する、音楽サービス連携状態の参照・解除 API。
`GET /music-connections/{provider}/callback` 成功時は、対応する `provider` の連携情報を新規作成または更新（upsert）する。

### GET /users/me/music-connections

自分の音楽サービス連携一覧を取得する。

**Response (200)**

```json
{
  "music_connections": [
    {
      "provider": "spotify",
      "provider_user_id": "spotify_user_123",
      "provider_username": "spotify_display_name",
      "expires_at": "2026-03-16T09:30:00Z",
      "updated_at": "2026-03-15T09:30:00Z"
    }
  ]
}
```

### DELETE /users/me/music-connections/{provider}

指定したプロバイダ連携を解除する。
`provider` は `spotify` または `apple_music`。
連携レコードが存在しない場合は **404 Not Found** を返す。

**Response (204)**

レスポンスボディなし。

## tracks

このセクションで扱うトラック識別子（`id` / `track_id` / `{id}`）は、共通仕様の例外として `<provider>:track:<external_id>` 形式の外部識別子を用いる。

### GET /tracks/search

バックエンドが Spotify Web API にプロキシするトラック検索。
`cursor` はページングに使う不透明なトークンであり、前のレスポンスの `pagination.next_cursor` をそのまま渡す（数値オフセットではない）。
認証必須とし、検索には連携済み Spotify アカウントのアクセストークンを用いる。
本エンドポイントの並び順は Spotify 検索結果（関連度順等）に従い、共通仕様の既定ソート規則（`created_at` / `occurred_at` 降順）の対象外とする。

**Query**: `q`（検索キーワード、必須）, `limit`（省略時 20、最大 50）, `cursor`（次ページ取得用、省略可）

**Response (200)**

```json
{
  "tracks": [
    {
      "id": "spotify:track:123",
      "title": "Song A",
      "artist_name": "Artist A",
      "artwork_url": "https://...",
      "preview_url": "https://..."
    }
  ],
  "pagination": {
    "next_cursor": "abc",
    "has_more": true
  }
}
```

### GET /tracks/{id}

認証必須とし、連携済み Spotify アカウント経由でトラック詳細を取得する。

**Response (200)**

```json
{
  "track": {
    "id": "spotify:track:123",
    "title": "Song A",
    "artist_name": "Artist A",
    "artwork_url": "https://...",
    "preview_url": "https://...",
    "album_name": "Album A",
    "duration_ms": 225000
  }
}
```

## users

### POST /users

**Request**

```json
{
  "display_name": "mimura",
  "avatar_url": "https://example.com/avatar.png",
  "bio": "music lover"
}
```

**Response (201)**

```json
{
  "user": {
    "id": "uuid",
    "display_name": "mimura",
    "avatar_url": "https://example.com/avatar.png",
    "bio": "music lover",
    "created_at": "2026-03-15T09:30:00Z",
    "updated_at": "2026-03-15T09:30:00Z"
  }
}
```

### GET /users/me

**Response (200)**

```json
{
  "user": {
    "id": "uuid",
    "display_name": "mimura",
    "avatar_url": "https://example.com/avatar.png",
    "bio": "music lover",
    "created_at": "2026-03-15T09:30:00Z",
    "updated_at": "2026-03-15T09:30:00Z"
  }
}
```

### GET /users/{id}

他ユーザーの公開プロフィールを取得する。
`user_settings.profile_visible = false` の場合はプロフィールの非公開項目を `null` で返す。
`user_settings.track_visible = false` の場合は `shared_track` を `null` で返す。
ブロック関係にあるユーザーへのアクセスは **404 Not Found** とする。

**Response (200)**

```json
{
  "user": {
    "id": "uuid",
    "display_name": "kawada",
    "avatar_url": "https://example.com/avatar.png",
    "bio": "music lover",
    "birthplace": "東京都",
    "age_range": "20s",
    "encounter_count": 12,
    "shared_track": {
      "id": "spotify:track:123",
      "title": "Song A",
      "artist_name": "Artist A",
      "artwork_url": "https://...",
      "preview_url": "https://..."
    },
    "updated_at": "2026-03-15T10:00:00Z"
  }
}
```

### PATCH /users/me

**Request（全項目任意）**

```json
{
  "display_name": "mimura_new",
  "avatar_url": "https://example.com/new-avatar.png",
  "bio": "updated bio"
}
```

**Response (200)**

```json
{
  "user": {
    "id": "uuid",
    "display_name": "mimura_new",
    "avatar_url": "https://example.com/new-avatar.png",
    "bio": "updated bio",
    "created_at": "2026-03-15T09:30:00Z",
    "updated_at": "2026-03-15T10:00:00Z"
  }
}
```

### DELETE /users/me

アカウントを削除する。
Firebase Auth のアカウントも同時に削除する。
関連データのうち、エンカウント、コメント、プレイリスト、ブロック・ミュートリストはカスケード削除される。
歌詞エントリは単独参加のチェーンであれば削除し、他ユーザーが参加した歌詞チェーンに属するものは匿名化（`display_name: "削除済みユーザー"`）して保持する。
この操作は取り消せない。

**Response (204)**

レスポンスボディなし。

## user-settings

### GET /users/me/settings

ユーザー設定を取得する。
`detection_distance` は位置情報エンカウントの判定距離（メートル）で、許容範囲は 10〜100。

**Response (200)**

```json
{
  "settings": {
    "ble_enabled": true,
    "location_enabled": true,
    "detection_distance": 50,
    "schedule_enabled": false,
    "schedule_start_time": null,
    "schedule_end_time": null,
    "profile_visible": true,
    "track_visible": true,
    "notification_enabled": true,
    "encounter_notification_enabled": true,
    "batch_notification_enabled": true,
    "notification_frequency": "hourly",
    "comment_notification_enabled": true,
    "like_notification_enabled": true,
    "announcement_notification_enabled": true,
    "theme_mode": "system",
    "updated_at": "2026-03-15T09:30:00Z"
  }
}
```

### PATCH /users/me/settings

ユーザー設定を更新する。
`detection_distance` を更新する場合は 10〜100 の範囲のみ受け付ける。

**Request（全項目任意）**

```json
{
  "location_enabled": true,
  "detection_distance": 80,
  "notification_frequency": "daily",
  "theme_mode": "dark"
}
```

**Response (200)**

```json
{
  "settings": {
    "ble_enabled": true,
    "location_enabled": true,
    "detection_distance": 80,
    "schedule_enabled": false,
    "schedule_start_time": null,
    "schedule_end_time": null,
    "profile_visible": true,
    "track_visible": true,
    "notification_enabled": true,
    "encounter_notification_enabled": true,
    "batch_notification_enabled": true,
    "notification_frequency": "daily",
    "comment_notification_enabled": true,
    "like_notification_enabled": true,
    "announcement_notification_enabled": true,
    "theme_mode": "dark",
    "updated_at": "2026-03-15T10:00:00Z"
  }
}
```

## push-tokens

APNs / FCM など、端末へのプッシュ通知配信先トークンを管理する。
同一ユーザーの同一端末は `platform + device_id` を一意キーとして扱う。

### POST /users/me/push-tokens

端末通知トークンを登録する。
同一 `platform + device_id` が既に存在する場合は upsert として扱い、**200** で更新後状態を返す。
新規登録時は **201**。

**Request**

```json
{
  "platform": "ios",
  "device_id": "ios-device-001",
  "push_token": "apns-token-xxxxx",
  "app_version": "1.0.0"
}
```

**Response (201 / 重複時 200)**

```json
{
  "push_token": {
    "id": "uuid",
    "platform": "ios",
    "device_id": "ios-device-001",
    "enabled": true,
    "updated_at": "2026-03-15T10:30:00Z"
  }
}
```

### PATCH /users/me/push-tokens/{id}

登録済みの端末通知トークン設定を更新する。
`push_token` のローテーションや、一時停止（`enabled: false`）に利用する。

**Request（全項目任意）**

```json
{
  "push_token": "apns-token-yyyyy",
  "enabled": true,
  "app_version": "1.0.1"
}
```

**Response (200)**

```json
{
  "push_token": {
    "id": "uuid",
    "platform": "ios",
    "device_id": "ios-device-001",
    "enabled": true,
    "updated_at": "2026-03-15T11:00:00Z"
  }
}
```

### DELETE /users/me/push-tokens/{id}

指定した端末通知トークンを削除する。
ログアウトや端末解除時に利用する。

**Response (204)**

レスポンスボディなし。

## notifications

アプリ内通知センター向けの通知一覧・既読状態を管理する。

### GET /users/me/notifications

通知一覧を取得する。

**Query**: `limit`, `cursor`, `unread_only`（`true` のとき未読のみ）

**Response (200)**

```json
{
  "notifications": [
    {
      "id": "uuid",
      "type": "encounter_single",
      "title": "新しい音楽と出会いました",
      "body": "「Song A」- Artist A",
      "target": {
        "encounter_id": "uuid"
      },
      "is_read": false,
      "created_at": "2026-03-15T10:45:00Z"
    }
  ],
  "pagination": {
    "next_cursor": null,
    "has_more": false
  }
}
```

### PATCH /users/me/notifications/{id}/read

通知を既読化する。
既に既読の場合はべき等に処理し **200** を返す。

**Request**

リクエストボディなし。

**Response (200)**

```json
{
  "notification": {
    "id": "uuid",
    "is_read": true,
    "read_at": "2026-03-15T10:50:00Z"
  }
}
```

### GET /users/me/notifications/unread-count

未読件数を取得する。

**Response (200)**

```json
{
  "unread_count": 3
}
```

## ble-tokens

### POST /ble-tokens

自分の BLE アドバタイズ用トークンを新規発行する。
既存のトークンは無効化（ローテーション）される。
`expires_at` は発行日の翌日 00:00:00 UTC（日次ローテーション）。
アプリ起動時およびトークン期限切れ前に呼び出す。

**Request**

リクエストボディなし。

**Response (201)**

```json
{
  "ble_token": {
    "token": "b2f2f0fa-...",
    "expires_at": "2026-03-16T00:00:00Z"
  }
}
```

### GET /ble-tokens/current

現在有効な自分の BLE トークンを取得する。
未発行の場合は **404** を返し、自動発行は行わない。
新規発行が必要な場合は `POST /ble-tokens` を呼び出す。
404 時のレスポンスボディは共通エラー形式を返し、例として `code: "BLE_TOKEN_NOT_FOUND"` を利用する。

**Response (200)**

```json
{
  "ble_token": {
    "token": "b2f2f0fa-...",
    "expires_at": "2026-03-16T00:00:00Z"
  }
}
```

### GET /ble-tokens/{token}/user

BLE スキャンで受信したトークンからユーザー情報を引く。
トークンが期限切れ・存在しない場合は **404** を返す。
取得できる情報はプロフィールの公開フィールドのみ（ブロック済みユーザーからのリクエストは 404 扱い）。

**Response (200)**

```json
{
  "user": {
    "id": "uuid",
    "display_name": "kawada",
    "avatar_url": "https://example.com/avatar.png"
  }
}
```

## locations

### POST /locations

現在位置をサーバーに送信し、サーバーサイドでエンカウント判定を行う。
サーバーは最近位置を更新した他ユーザーと、双方の `user_settings.detection_distance` の小さい方を判定距離として比較する。
判定距離内に入っている場合、2ユーザーの組み合わせを表す単一の `type: "location"` エンカウントレコードを作成し、両ユーザーがそのレコードを参照できるようにする。
エンカウントが発生しない場合は `encounter_count: 0` / 空配列を返す。
同一ユーザーペアで短時間内（5 分以内）に重複エンカウントは作成しない。

- `accuracy_m`: GPS 精度（メートル）。サービスはこの値を参考に信頼性を評価できる。本フィールドは判定時のフィルタリングにのみ使用し、DB には永続化しない。
- `recorded_at`: クライアント側で記録した時刻（サーバー受信時刻との乖離が大きい場合は無視することがある）。

**Request**

```json
{
  "lat": 35.6812,
  "lng": 139.7671,
  "accuracy_m": 20,
  "recorded_at": "2026-03-15T09:30:00Z"
}
```

**Response (200)**

```json
{
  "encounter_count": 1,
  "encounters": [
    {
      "id": "uuid",
      "type": "location",
      "user": {
        "id": "uuid",
        "display_name": "other_user",
        "avatar_url": "https://..."
      },
      "occurred_at": "2026-03-15T09:30:00Z"
    }
  ]
}
```

## encounters

### POST /encounters

BLE スキャンで検出した相手のトークンをもとに、エンカウントを手動登録する。
サーバーはトークンをユーザーに解決し、送信者・受信者のペアを表す単一のエンカウントレコードを作成して両者に紐付ける。
同一トークンペアで 5 分以内の重複送信はべき等に処理する。初回作成時は **201**、重複時は **200** で既存レコードを返す。

- `target_ble_token`: 相手デバイスが BLE アドバタイズしているトークン（`/ble-tokens` で発行されたもの）。
- `type`: このエンドポイントでは `ble` 固定。クライアントは常に `ble` を送るものとし、他の値は **400** を返す。
- `rssi`: 受信信号強度（dBm）。距離推定・品質フィルタに使用。値の範囲は -100〜0 程度。本フィールドはエンカウント作成時のフィルタリングにのみ使用し、DB には永続化しない。
- `occurred_at`: BLE 検出時のクライアント側時刻。

**Request**

```json
{
  "target_ble_token": "b2f2f0fa-...",
  "type": "ble",
  "rssi": -58,
  "occurred_at": "2026-03-15T09:30:00Z"
}
```

**Response (201 / 重複時 200)**

```json
{
  "encounter": {
    "id": "uuid",
    "type": "ble",
    "user": {
      "id": "uuid",
      "display_name": "other_user",
      "avatar_url": "https://..."
    },
    "occurred_at": "2026-03-15T09:30:00Z"
  }
}
```

### GET /encounters

**Query**: `limit`, `cursor`

**Response (200)**

```json
{
  "encounters": [
    {
      "id": "uuid",
      "type": "ble",
      "user": {
        "id": "uuid",
        "display_name": "other_user",
        "avatar_url": "https://..."
      },
      "occurred_at": "2026-03-15T09:30:00Z"
    }
  ],
  "pagination": {
    "next_cursor": null,
    "has_more": false
  }
}
```

### GET /encounters/{id}

**Response (200)**

```json
{
  "encounter": {
    "id": "uuid",
    "type": "location",
    "user": {
      "id": "uuid",
      "display_name": "other_user",
      "avatar_url": "https://..."
    },
    "occurred_at": "2026-03-15T09:30:00Z",
    "tracks": [
      {
        "id": "spotify:track:123",
        "title": "Song A",
        "artist_name": "Artist A",
        "artwork_url": "https://...",
        "preview_url": "https://..."
      }
    ]
  }
}
```

## comments

### POST /encounters/{id}/comments

**Request**

```json
{
  "content": "この曲好きです！"
}
```

**Response (201)**

```json
{
  "comment": {
    "id": "uuid",
    "encounter_id": "uuid",
    "user": {
      "id": "uuid",
      "display_name": "mimura",
      "avatar_url": "https://..."
    },
    "content": "この曲好きです！",
    "created_at": "2026-03-15T10:45:00Z"
  }
}
```

### GET /encounters/{id}/comments

**Query**: `limit`, `cursor`

**Response (200)**

```json
{
  "comments": [
    {
      "id": "uuid",
      "encounter_id": "uuid",
      "user": {
        "id": "uuid",
        "display_name": "mimura",
        "avatar_url": "https://..."
      },
      "content": "この曲好きです！",
      "created_at": "2026-03-15T10:45:00Z"
    }
  ],
  "pagination": {
    "next_cursor": null,
    "has_more": false
  }
}
```

### DELETE /comments/{id}

**Response (204)**

レスポンスボディなし。

## users/me/tracks

### POST /users/me/tracks

自分のマイトラックに楽曲を追加する。
同一 `track_id` が既に登録済みの場合はべき等に処理し、**200** で既存レコードを返す。

**Request**

```json
{
  "track_id": "spotify:track:123"
}
```

**Response (201 / 重複時 200)**

```json
{
  "track": {
    "id": "spotify:track:123",
    "title": "Song A",
    "artist_name": "Artist A",
    "artwork_url": "https://...",
    "preview_url": "https://..."
  }
}
```

### GET /users/me/tracks

**Query**: `limit`, `cursor`

**Response (200)**

```json
{
  "tracks": [
    {
      "id": "spotify:track:123",
      "title": "Song A",
      "artist_name": "Artist A",
      "artwork_url": "https://...",
      "preview_url": "https://..."
    }
  ],
  "pagination": {
    "next_cursor": null,
    "has_more": false
  }
}
```

### DELETE /users/me/tracks/{id}

**Response (204)**

レスポンスボディなし。

## users/me/shared-track

現在シェア中の曲（単一）を管理する。

### GET /users/me/shared-track

現在シェア中の曲を取得する。
未設定の場合は `shared_track: null` を返す。

**Response (200)**

```json
{
  "shared_track": {
    "id": "spotify:track:123",
    "title": "Song A",
    "artist_name": "Artist A",
    "artwork_url": "https://...",
    "preview_url": "https://...",
    "updated_at": "2026-03-15T10:00:00Z"
  }
}
```

### PUT /users/me/shared-track

現在シェア中の曲を新規設定または更新する。
同一 `track_id` が既に設定済みの場合はべき等に処理し **200** を返す。
初回設定時は **201**。

**Request**

```json
{
  "track_id": "spotify:track:123"
}
```

**Response (201 / 重複時 200)**

```json
{
  "shared_track": {
    "id": "spotify:track:123",
    "title": "Song A",
    "artist_name": "Artist A",
    "artwork_url": "https://...",
    "preview_url": "https://...",
    "updated_at": "2026-03-15T10:05:00Z"
  }
}
```

### DELETE /users/me/shared-track

現在シェア中の曲を解除する。

**Response (204)**

レスポンスボディなし。

## lyrics, songs

### POST /lyrics

エンカウントをきっかけに歌詞チェーンへ1行を投稿する。
チェーンはエンカウントと 1 対 1 ではなく、利用可能な `pending` チェーンへ自動割り当てされる。
割り当て可能なチェーンが存在しない場合はこのリクエストで新規チェーンを作成する。
同一チェーンに対して1ユーザーが投稿できる歌詞は1件のみ（重複投稿は 409 Conflict）。
`participant_count` が `threshold` に達すると、サーバーが非同期で Lyria による楽曲生成ジョブをキューに積む（`status: "generating"` へ遷移）。

- `encounter_id`: この歌詞を紐付けるエンカウントの ID。
- `content`: 投稿歌詞本文（最大 100 文字）。
- `sequence_num`（レスポンス）: チェーン内での順序。投稿順に1始まりで採番される。
- `chain.status` の遷移: `pending`（参加者不足）→ `generating`（Lyria 生成中）→ `completed`（楽曲完成）。生成失敗時は `failed` に遷移する。
- `chain.threshold`: 楽曲生成に必要な参加人数。現在は固定値 4。

**Request**

```json
{
  "encounter_id": "uuid",
  "content": "今日も空は青かった"
}
```

**Response (201)**

```json
{
  "lyric_entry": {
    "id": "uuid",
    "chain_id": "uuid",
    "sequence_num": 3,
    "content": "今日も空は青かった",
    "created_at": "2026-03-15T09:30:00Z"
  },
  "chain": {
    "id": "uuid",
    "participant_count": 3,
    "threshold": 4,
    "status": "pending"
  }
}
```

### GET /lyrics/chains/{chain_id}

チェーンの詳細と全歌詞エントリを取得する。
`chain.status` が `completed` の場合のみ `song` フィールドが含まれる。
`generating` 中はポーリング（推奨間隔: 5 秒）またはプッシュ通知で完了を検知する。
`audio_url` は Cloud Storage の署名付き URL であり、有効期限は 1 時間。
削除済みユーザーのエントリは `user.display_name` を `"削除済みユーザー"`、`user.avatar_url` を `null` として返す。

**Response (200)**

```json
{
  "chain": {
    "id": "uuid",
    "status": "completed",
    "participant_count": 4,
    "threshold": 4,
    "created_at": "2026-03-15T09:00:00Z",
    "completed_at": "2026-03-15T09:45:00Z"
  },
  "entries": [
    {
      "sequence_num": 1,
      "content": "夜明け前の静けさの中",
      "user": { "id": "uuid", "display_name": "ユーザーA", "avatar_url": "https://..." }
    }
  ],
  "song": {
    "id": "uuid",
    "title": "夜明けの詩",
    "audio_url": "https://storage.googleapis.com/...",
    "duration_sec": 45,
    "mood": "melancholic"
  }
}
```

### GET /users/me/songs

**Query**: `limit`, `cursor`

**Response (200)**

```json
{
  "songs": [
    {
      "id": "uuid",
      "title": "夜明けの詩",
      "audio_url": "https://storage.googleapis.com/...",
      "participant_count": 4,
      "my_lyric": "今日も空は青かった",
      "generated_at": "2026-03-15T09:45:00Z"
    }
  ],
  "pagination": {
    "next_cursor": null,
    "has_more": false
  }
}
```

## playlists

### POST /playlists

**Request**

```json
{
  "name": "Morning Mix",
  "description": "朝に聴く曲",
  "is_public": true
}
```

**Response (201)**

```json
{
  "playlist": {
    "id": "uuid",
    "name": "Morning Mix",
    "description": "朝に聴く曲",
    "is_public": true,
    "created_at": "2026-03-15T10:00:00Z",
    "updated_at": "2026-03-15T10:00:00Z"
  }
}
```

### GET /playlists

自分が作成したプレイリストと、他ユーザーの公開プレイリスト（`is_public: true`）を一覧取得する。
非公開プレイリストは所有者本人のみ取得できる。
返却される各プレイリストには所有者情報を含める。

**Query**: `limit`, `cursor`

**Response (200)**

```json
{
  "playlists": [
    {
      "id": "uuid",
      "owner": {
        "id": "uuid",
        "display_name": "playlist_owner",
        "avatar_url": "https://..."
      },
      "name": "Morning Mix",
      "description": "朝に聴く曲",
      "is_public": true,
      "track_count": 12,
      "created_at": "2026-03-15T10:00:00Z",
      "updated_at": "2026-03-15T10:00:00Z"
    }
  ],
  "pagination": {
    "next_cursor": null,
    "has_more": false
  }
}
```

### GET /playlists/{id}

プレイリスト詳細を取得する。
対象が公開プレイリストであれば他ユーザーも参照可能で、非公開プレイリストは所有者本人のみ参照できる。
レスポンスには所有者情報を含める。

**Response (200)**

```json
{
  "playlist": {
    "id": "uuid",
    "owner": {
      "id": "uuid",
      "display_name": "playlist_owner",
      "avatar_url": "https://..."
    },
    "name": "Morning Mix",
    "description": "朝に聴く曲",
    "is_public": true,
    "tracks": [
      {
        "id": "spotify:track:123",
        "title": "Song A",
        "artist_name": "Artist A",
        "artwork_url": "https://...",
        "preview_url": "https://..."
      }
    ],
    "created_at": "2026-03-15T10:00:00Z",
    "updated_at": "2026-03-15T10:00:00Z"
  }
}
```

### PATCH /playlists/{id}

**Request（全項目任意）**

```json
{
  "name": "Evening Mix",
  "description": "夜に聴く曲",
  "is_public": false
}
```

**Response (200)**

```json
{
  "playlist": {
    "id": "uuid",
    "name": "Evening Mix",
    "description": "夜に聴く曲",
    "is_public": false,
    "created_at": "2026-03-15T10:00:00Z",
    "updated_at": "2026-03-15T11:00:00Z"
  }
}
```

### DELETE /playlists/{id}

**Response (204)**

レスポンスボディなし。

### POST /playlists/{id}/tracks

プレイリストに楽曲を追加する。
同一 `track_id` が既にそのプレイリストへ追加済みの場合はべき等に処理し、**200** で既存レコードを返す。

**Request**

```json
{
  "track_id": "spotify:track:123"
}
```

**Response (201 / 重複時 200)**

```json
{
  "playlist_track": {
    "playlist_id": "uuid",
    "track": {
      "id": "spotify:track:123",
      "title": "Song A",
      "artist_name": "Artist A",
      "artwork_url": "https://...",
      "preview_url": "https://..."
    },
    "added_at": "2026-03-15T10:30:00Z"
  }
}
```

### DELETE /playlists/{id}/tracks/{track_id}

**Response (204)**

レスポンスボディなし。

## favorites

### POST /tracks/{id}/favorites

トラックをお気に入り登録する。
同一トラックが既にお気に入り済みの場合はべき等に処理し、**200** で既存状態を返す。

**Request**

リクエストボディなし。

**Response (201 / 重複時 200)**

```json
{
  "favorite": {
    "resource_type": "track",
    "resource_id": "spotify:track:123",
    "favorited": true,
    "created_at": "2026-03-15T10:40:00Z"
  }
}
```

### DELETE /tracks/{id}/favorites

**Response (204)**

レスポンスボディなし。

### GET /users/me/track-favorites

**Query**: `limit`, `cursor`

**Response (200)**

```json
{
  "tracks": [
    {
      "id": "spotify:track:123",
      "title": "Song A",
      "artist_name": "Artist A",
      "artwork_url": "https://...",
      "preview_url": "https://..."
    }
  ],
  "pagination": {
    "next_cursor": null,
    "has_more": false
  }
}
```

### POST /playlists/{id}/favorites

プレイリストをお気に入り登録する。
同一プレイリストが既にお気に入り済みの場合はべき等に処理し、**200** で既存状態を返す。

**Request**

リクエストボディなし。

**Response (201 / 重複時 200)**

```json
{
  "favorite": {
    "resource_type": "playlist",
    "resource_id": "uuid",
    "favorited": true,
    "created_at": "2026-03-15T10:40:00Z"
  }
}
```

### DELETE /playlists/{id}/favorites

**Response (204)**

レスポンスボディなし。

### GET /users/me/playlist-favorites

**Query**: `limit`, `cursor`

**Response (200)**

```json
{
  "playlists": [
    {
      "id": "uuid",
      "name": "Morning Mix",
      "description": "朝に聴く曲",
      "is_public": true,
      "track_count": 12,
      "created_at": "2026-03-15T10:00:00Z",
      "updated_at": "2026-03-15T10:00:00Z"
    }
  ],
  "pagination": {
    "next_cursor": null,
    "has_more": false
  }
}
```

## reports, blocks, mutes

### POST /reports

ユーザーを運営に通報する。
通報は管理ダッシュボードでレビューされ、規約違反が確認された場合にアカウント停止等の措置が取られる。
API の `target_user_id` は DB スキーマ上の `reports.reported_user_id` に相当する。

- `report_type: "user"` の場合、同一ユーザーへの重複通報は 1 件に集約される。初回作成時は **201**、既存通報がある場合は **200** で既存レコードを返す。
- `report_type: "comment"` の場合、同一コメントへの重複通報は 1 件に集約される。初回作成時は **201**、既存通報がある場合は **200** で既存レコードを返す。

- `report_type`: 通報対象の種別。`user` または `comment`。
- `target_user_id`: 被通報ユーザーの ID。`report_type: "user"` の場合に必須。
- `target_comment_id`: 対象コメントの ID。`report_type: "comment"` の場合に必須、`report_type: "user"` の場合は省略または `null`。
- `report_type: "comment"` の場合、`reports.reported_user_id` は `target_comment_id` からサーバー側で導出する（クライアント入力の `target_user_id` は受け付けない）。
- `reason`: 通報理由。以下の enum 値のいずれかを指定する。
  - `harassment` — ハラスメント・嫌がらせ
  - `spam` — スパム・宣伝
  - `impersonation` — なりすまし
  - `inappropriate_content` — 不適切なコンテンツ
  - `other` — その他（`detail` に詳細を記載）
- `detail`: 補足説明（任意、最大 500 文字）。

**Request**

```json
{
  "report_type": "user",
  "target_user_id": "uuid",
  "target_comment_id": null,
  "reason": "harassment",
  "detail": "不適切なメッセージ"
}
```

**Response (201 / 重複時 200)**

```json
{
  "report": {
    "id": "uuid",
    "report_type": "user",
    "target_user_id": "uuid",
    "target_comment_id": null,
    "reason": "harassment",
    "detail": "不適切なメッセージ",
    "created_at": "2026-03-15T11:00:00Z"
  }
}
```

### POST /blocks

指定ユーザーをブロックする。
ブロックの効果はアカウント削除まで持続する。

- ブロックされたユーザーからの BLE トークン逆引き（`GET /ble-tokens/{token}/user`）は 404 を返す。
- ブロック中の2ユーザー間ではエンカウントが生成されない（位置・BLE 両方）。
- 既にブロック済みの場合は 409 Conflict を返す。

**Request**

```json
{
  "target_user_id": "uuid"
}
```

**Response (201)**

```json
{
  "block": {
    "target_user_id": "uuid",
    "created_at": "2026-03-15T11:05:00Z"
  }
}
```

### DELETE /blocks/{target_user_id}

`{target_user_id}` はアンブロック対象ユーザーの ID。

**Response (204)**

レスポンスボディなし。

### GET /blocks

**Query**: `limit`, `cursor`

**Response (200)**

```json
{
  "blocks": [
    {
      "target_user_id": "uuid",
      "created_at": "2026-03-15T11:05:00Z"
    }
  ],
  "pagination": {
    "next_cursor": null,
    "has_more": false
  }
}
```

### POST /mutes

指定ユーザーをミュートする。
ブロックと異なりエンカウントは通常通り発生するが、ミュートしたユーザーのエンカウント・コメントが自分のフィード上に表示されなくなる（フィルタリングはサーバーサイドで実施）。
相手にはミュートされたことは通知されない。
既にミュート済みの場合は 409 Conflict を返す。

**Request**

```json
{
  "target_user_id": "uuid"
}
```

**Response (201)**

```json
{
  "mute": {
    "target_user_id": "uuid",
    "created_at": "2026-03-15T11:10:00Z"
  }
}
```

### DELETE /mutes/{target_user_id}

`{target_user_id}` はアンミュート対象ユーザーの ID。

**Response (204)**

レスポンスボディなし。

### GET /mutes

**Query**: `limit`, `cursor`

**Response (200)**

```json
{
  "mutes": [
    {
      "target_user_id": "uuid",
      "created_at": "2026-03-15T11:10:00Z"
    }
  ],
  "pagination": {
    "next_cursor": null,
    "has_more": false
  }
}
```
