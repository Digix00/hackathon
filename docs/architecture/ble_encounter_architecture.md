# すれ違い音楽交換アプリ BLEアーキテクチャ設計

## 1. 目的

スマートフォン同士が近距離（数m〜数十m）ですれ違った際に、
ユーザーの「好きな曲」を自動で交換する。

BLEは **ユーザー識別のための一時トークン交換のみ** に使用し、
実際のデータ取得はバックエンドAPIを利用する。

------------------------------------------------------------------------

# 2. 全体アーキテクチャ

```
BLE Advertising / Scan
       ↓
BLEトークン取得
       ↓
クライアントcooldownフィルタ（重複検出抑制）
       ↓
Backend API (POST /encounter)
       ↓
サーバー: トークン → user_id 解決
       ↓
Encounter判定・登録
       ↓
曲データ取得 → クライアントへ返却
```

役割を分離することで

- BLE通信を最小化
- セキュリティ確保（トークンはサーバー管理）
- iOS / Android 拡張性
- サーバーでロジック制御

を実現する。

------------------------------------------------------------------------

# 3. BLEレイヤー

## 3.1 役割

BLEは以下のみを担当する。

- 近距離ユーザー検出
- BLEトークン（一時ID）の取得

BLEでは **ユーザー情報や曲情報は送らない。**

------------------------------------------------------------------------

## 3.2 BLE通信方式

```
advertise(ble_token)  ←→  scan
```

接続（connect）は使用しない。

理由

- 実装が簡単
- 電力消費が低い
- スマホ同士でも安定
- Android対応しやすい

------------------------------------------------------------------------

## 3.3 Advertising Payload

| 項目 | 内容 |
|------|------|
| 送信データ | `ble_token`（UUIDなど、サーバーが発行した一時トークン） |
| 格納場所 | **Manufacturer Data** |
| サイズ目安 | 8〜16 bytes |

------------------------------------------------------------------------

## 3.4 BLEトークン（一時ID）

ユーザー識別は **サーバーが発行した一時トークン** を使用する。

理由

- ユーザー追跡防止（クライアントにsecretを持たせない）
- プライバシー保護
- サーバー側でトークン失効・リヴォーク制御が可能

### DB: `ble_tokens` テーブル

| カラム | 型 | 説明 |
|--------|----|------|
| `id` | string | PK |
| `user_id` | string | users.id への外部キー |
| `token` | string | BLEアドバタイズ用トークン（UNIQUE） |
| `valid_from` | datetime | 有効開始日時 |
| `valid_to` | datetime | 有効終了日時（index、期限切れ定期削除用） |
| `created_at` | datetime | 作成日時 |
| `deleted_at` | datetime | 論理削除 |

**更新運用:** 毎日 0:00 UTC に全ユーザーのBLEトークンを再発行。`valid_to` 超過レコードは定期削除。

------------------------------------------------------------------------

# 4. クライアント軽量フィルタ（cooldown）

BLEは同じユーザーを短時間で何度も検出する（例：電車で隣に30秒いると10回検出）。
これを防ぐためクライアント側で軽量フィルタを行う。

## 4.1 フィルタルール

同じトークンは一定時間無視する。

| 設定 | 値 |
|------|----|
| cooldown | **10分** |

## 4.2 クライアント処理フロー

```
scan
  ↓
ble_token 取得
  ↓
ローカルキャッシュ確認
  ↓ 最近検出済み → 無視
  ↓ 未検出 → API送信
```

------------------------------------------------------------------------

# 5. APIレイヤー

BLEで取得したトークンをサーバーへ送信し、手動でエンカウント（`type: "ble"`）を登録する。
このAPIは認証必須（`Authorization: Bearer <Firebase ID Token>`）であるため、クライアントから自身のユーザーIDは送らない。

## エンドポイント

```
POST /encounters
```

### Request

```json
{
  "target_ble_token": "abc123xyz...",
  "type": "ble",
  "rssi": -58,
  "occurred_at": "2026-03-15T09:30:00Z"
}
```

- `target_ble_token`: BLEスキャンで検出した相手のトークン
- `type`: `ble` 固定
- `rssi`: 受信信号強度。距離推定・フィルタ用。サーバーDBには保存しない。
- `occurred_at`: クライアント側の検出時刻

### Response（201 Created / 200 OK）

レスポンスは軽量化のため `tracks` （曲情報）を**含まない**。
同一トークンペアで5分以内の重複送信は、サーバー側で冪等に処理され（既存のレコードを返し `200 OK` となる）。

```json
{
  "encounter": {
    "id": "enc_xxx",
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

------------------------------------------------------------------------

# 6. サーバー処理

## 6.1 判定フロー

```
POST /encounters リクエスト受信（Bearerトークンから self_user_id 解決）
  ↓
ble_tokens テーブルで target_ble_token から other_user_id 解決（期限チェック含む）
  ↓
直近5分以内の同一ペア('ble'タイプ)重複送信か？
  ↓ YES → 既存の encounter を返し 200 OK（冪等処理）
  ↓ NO  → 制限チェックへ進む
  ↓
同一ペアで本日交換済み？（encounters テーブルを DATE(occurred_at) で確認）
  ↓ YES → 無視（制限エラー or 既存エンカウント返却）
  ↓ NO  → daily_encounter_counts をインクリメント
  ↓
Encounter 登録（201 Created） + 各ユーザーの現在シェア中の曲等を encounter_tracks に保存
  ※ APIレスポンス自体に tracks は含めず、encounter(相手ユーザー情報) のみを返す
```

------------------------------------------------------------------------

# 7. Encounter 制御

同じユーザーペアとの交換は **1日1回** に制限する。

## DB: `encounters` テーブル

| カラム | 型 | 説明 |
|--------|----|------|
| `id` | string | PK |
| `user_id_1` | string | users.id への外部キー（`user_id_1 < user_id_2` CHECK制約） |
| `user_id_2` | string | users.id への外部キー |
| `occurred_at` | datetime | すれ違い発生日時 |
| `encounter_type` | string | `'ble'` \| `'location'` |
| `latitude` | float (nullable) | ぼかし済み緯度（`encounter_type='location'` のみ） |
| `longitude` | float (nullable) | ぼかし済み経度（`encounter_type='location'` のみ） |
| `created_at` | datetime | 作成日時 |
| `deleted_at` | datetime | 論理削除 |

> **Note:** `user_id_1 < user_id_2` のCHECK制約により、同一ペアの重複登録を防ぐ。

## DB: `encounter_tracks` テーブル

すれ違いに紐づく交換曲情報。`source_user_id` はサーバー内部でのみ使用し、公開APIには露出しない。

| カラム | 型 | 説明 |
|--------|----|------|
| `id` | string | PK |
| `encounter_id` | string | encounters.id への外部キー |
| `track_id` | string | tracks.id への外部キー |
| `source_user_id` | string | users.id への外部キー（どちらのユーザー由来の曲か） |
| `created_at` | datetime | 作成日時 |
| `deleted_at` | datetime | 論理削除 |

**制約:** `(encounter_id, track_id, source_user_id)` で UNIQUE 制約

## DB: `daily_encounter_counts` テーブル

レート制限用の日別すれ違いカウント。

| カラム | 型 | 説明 |
|--------|----|---------|
| `user_id` | string | users.id への外部キー |
| `date` | date | 対象日 |
| `count` | integer | すれ違い件数 |
| `created_at` | datetime | 作成日時 |
| `updated_at` | datetime | 更新日時 |

**制約:** `(user_id, date)` で UNIQUE 制約  
**運用:** UPSERT でカウントをインクリメント。しきい値（3 / 5 / 10 / 50 / 100）超過でドメインエラー。

## 判定クエリ例（同一ペア重複チェック）

```sql
SELECT * FROM encounters
WHERE user_id_1 = $1 AND user_id_2 = $2
  AND DATE(occurred_at) = CURRENT_DATE
  AND deleted_at IS NULL
```

------------------------------------------------------------------------

# 8. 曲情報取得

Encounter 登録時、相手ユーザーの現在シェア中の曲（`user_current_tracks`）またはお気に入り曲（`user_tracks`）を取得し、サーバー内で自動的に `encounter_tracks` に保存する。

**注意点**: バックエンドAPIの軽量化方針により、`POST /encounters` のレスポンスには `tracks` 配列が含まれない。
クライアントが曲情報を必要とする場合は、返却された `encounter.id` を用いて、別途トラック情報込みのエンカウント詳細を取得する。

```
（POST /encounters 成功処理内）
user_current_tracks（なければ user_tracks）から取得
  ↓
encounter_tracks に保存

（クライアント側の曲データ取得）
クライアント → GET /encounters/{id} をリクエスト
  ↓
encounter_tracks を含む完全なエンカウント詳細を返却
```

------------------------------------------------------------------------

# 9. ユーザー設定

`user_settings` テーブルでユーザーごとに検出動作を制御する。

| 設定フィールド | デフォルト | 説明 |
|----------------|-----------|------|
| `ble_enabled` | true | BLE検出のON/OFF |
| `location_enabled` | true | 位置情報検出のON/OFF |
| `detection_distance` | 50m | 検出距離 |
| `schedule_enabled` | false | 時間帯スケジュールのON/OFF |
| `schedule_start_time` | - | 検出開始時刻 |
| `schedule_end_time` | - | 検出終了時刻 |

------------------------------------------------------------------------

# 10. セキュリティ設計

- `user_id` はBLEで送信しない → `ble_token`（一時トークン）を利用
- BLEトークンはサーバーが発行・管理し、クライアントはsecretを持たない
- トークンに有効期限（`valid_to`）を設定し、期限切れトークンは無効
- サーバー側でリヴォーク可能（`deleted_at`による論理削除）

------------------------------------------------------------------------

# 11. すれ違い処理の全体フロー

```
[事前準備]
① クライアント起動時 or トークン期限切れ前に GET /ble-tokens/current (無ければ POST /ble-tokens) でサーバから ble_token を取得
  （※トークン自体は毎日0:00 UTC にサーバー側で再発行される）

[すれ違い発生]
② 互いに advertise(ble_token)
③ scan → 相手の ble_token (= target_ble_token) 検出
④ クライアント cooldown チェック（10分以内の重複はアプリ内で無視）
⑤ クライアントから POST /encounters リクエスト送信 (rssi, occurred_at 含む)

[サーバー処理]
⑥ target_ble_token → 相手 user_id 解決（有効期限チェック含む）
⑦ 冪等性チェック（5分以内の重複送信は既存レコードを返す）
⑧ 同一ペア・当日の重複チェック（encounters テーブル）
⑨ daily_encounter_counts チェック（しきい値超過でエラー）
⑩ Encounter 登録 + encounter_tracks 保存 + daily_encounter_counts 更新
⑪ エンカウント情報(相手プロフィール等のみ)をクライアントへ返却 (201 Created)

[曲情報が必要な場合]
⑫ クライアントが GET /encounters/{id} を呼び出し、曲情報(tracks)を取得して表示
```

------------------------------------------------------------------------

# 12. 技術スタック

## Mobile

- **iOS**: Swift + CoreBluetooth
- **Android**: Kotlin + BLE API

## Backend

- **言語**: Go
- **フレームワーク**: Echo
- **DB**: PostgreSQL
- **ORM**: GORM

------------------------------------------------------------------------

# 13. 将来拡張

追加可能機能

- すれ違い履歴一覧
- 近くのユーザー一覧（位置情報連携）
- 曲レコメンド
- Spotify / Apple Music 連携
- 友達追加
- コメント・いいね機能
- ブロック・ミュート機能

------------------------------------------------------------------------

# 14. 実装ステップ

1. サーバー: BLEトークン発行API実装
2. iOS: CoreBluetooth advertising / scan 実装
3. iOS: クライアントcooldownフィルタ実装
4. サーバー: `POST /encounter` API実装
5. サーバー: encounter 判定・登録ロジック実装
6. サーバー: 曲データ取得・返却実装
7. Android: BLE実装（iOS完了後）
