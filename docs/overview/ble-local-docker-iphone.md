# iOS BLE 実機 2 台検証（ローカル Docker バックエンド）手順

この手順書は、**ローカルの Docker でバックエンドを起動**し、
**iPhone 実機 2 台で BLE の送受信を検証**するための流れをまとめたものです。

人によって変わる値（ローカルIPなど）は **プレースホルダ** で記載しています。

---

## 前提

- iPhone 実機 2 台
- 同一 Wi-Fi（Mac と iPhone が同じネットワーク）
- Mac で Docker が動作すること
- iOS アプリを Xcode でビルドできること

---

## 1. バックエンドをローカル Docker で起動する

このプロジェクトのバックエンド起動手順に従って、API と DB を起動します。
（詳細はチーム内のバックエンド手順書に合わせてください）

**確認ポイント**
- API が `http://<MAC_LOCAL_IP>:<API_PORT>/api/v1/...` で疎通できること
- DB が起動しており、`ble_tokens` などのテーブルが使えること

---

## 2. iOS アプリの API エンドポイントを設定する

iOS 側は `API_BASE_URL` を参照します。人によって値が変わるため、
**Scheme の Environment Variables で設定**するのが推奨です。

### Mac のローカル IP を確認する

実機 iPhone からは `localhost` を参照できません。
必ず **Mac のローカル IP** を使います。

例:

```bash
ipconfig getifaddr en0
```

Wi-Fi 利用時はこれで `192.168.x.x` が返ることが多いです。

### 疎通確認

Mac 上で以下を叩き、`404 Not Found` でもよいので
**バックエンドの JSON レスポンスが返ること**を確認します。

```bash
curl http://<MAC_LOCAL_IP>:<API_PORT>
curl http://<MAC_LOCAL_IP>:<API_PORT>/health
```

ルートや `/health` が 404 でも、
**`<MAC_LOCAL_IP>:<API_PORT>` に到達できていること自体が確認できれば OK** です。

### 推奨: Scheme の Environment Variables

- Key: `API_BASE_URL`
- Value: `http://<MAC_LOCAL_IP>:<API_PORT>`

`<MAC_LOCAL_IP>` は Mac のローカル IP（例: `192.168.x.x`）
`<API_PORT>` はバックエンドの API ポート（例: `8000`）

---

## 3. 認証トークンを設定する

アプリは API リクエスト時に **Bearer Token** を要求します。
そのため、環境変数 `FIREBASE_ID_TOKEN` を設定しておく必要があります。

注意: Firebase Emulator UI に表示される `User UID` をそのまま設定しても認証できません。

- `FIREBASE_ID_TOKEN`
  - ログイン時に返る **JWT 形式の ID トークン**
  - 実際に Scheme に設定する値はこちら

`signInWithPassword` のレスポンス例:

```json
{
  "localId": "Firebase UID",
  "idToken": "これをFIREBASE_ID_TOKENに設定する"
}
```

### 推奨: Firebase Auth エミュレータで ID トークンを発行

ローカル運用ではエミュレータの利用が想定されています。
手順は以下のドキュメントにまとめています。

- [firebase-auth-emulator-ops.md](./firebase-auth-emulator-ops.md)

### Scheme の Environment Variables

- Key: `FIREBASE_ID_TOKEN`
- Value: `<ID_TOKEN>`

### 重要: 2 台検証ではユーザーを分ける

BLE 実機 2 台検証では、
**iPhone A / iPhone B で別ユーザーの ID トークンを使う**ことを推奨します。

例:

- iPhone A
  - `FIREBASE_ID_TOKEN=<USER_A_ID_TOKEN>`
- iPhone B
  - `FIREBASE_ID_TOKEN=<USER_B_ID_TOKEN>`

同じトークンを 2 台で使うより、別ユーザーの方が
エンカウント登録と画面確認が分かりやすいです。

### 推奨: Scheme を 2 つに分ける

Xcode では以下のように Scheme を分けると運用しやすいです。

- `ios-UserA`
- `ios-UserB`

どちらも `API_BASE_URL` は同じで、
`FIREBASE_ID_TOKEN` だけを変えます。

### 重要: ID トークン取得後にアプリ内ユーザーを作成する

Firebase Auth Emulator にユーザーがあるだけでは不十分です。
バックエンドの `users` テーブルに対応ユーザーが未作成だと、
以下のような `record not found` が出ます。

```text
SELECT * FROM "users" WHERE (auth_provider = 'firebase' AND provider_user_id = '...')
```

その場合は、各 ID トークンごとに一度 `POST /api/v1/users` を実行して
アプリ内ユーザーを作成してください。

例:

```bash
curl -X POST http://<MAC_LOCAL_IP>:<API_PORT>/api/v1/users \
  -H "Authorization: Bearer <ID_TOKEN>" \
  -H "Content-Type: application/json" \
  -d '{
    "display_name": "User A"
  }'
```

作成後、以下で確認します。

```bash
curl http://<MAC_LOCAL_IP>:<API_PORT>/api/v1/users/me \
  -H "Authorization: Bearer <ID_TOKEN>"
```

---

## 4. iPhone 実機へビルド・インストール（2 台）

1. iPhone A を接続してビルド & インストール
2. iPhone B を接続してビルド & インストール

推奨:

- iPhone A は `ios-UserA`
- iPhone B は `ios-UserB`

を使って起動します。

---

## 5. BLE 動作確認

1. 両端末でアプリを起動
2. Bluetooth を ON
3. 2 台を近づける

**期待される挙動**
- 端末同士の BLE 検出が発生し、
  `ble-tokens` に紐づくユーザー取得・エンカウント登録が行われる
- Home 上部の BLE 状態表示が `SCANNING` または `STANDBY` になる
- 履歴画面に encounter が表示される

---

## 6. よくある詰まりポイント

- **iPhone から API に繋がらない**
  - `localhost` を使っていないか確認
  - `<MAC_LOCAL_IP>` に置き換えているか確認
  - Mac / iPhone が同じ Wi-Fi か確認

- **401 Unauthorized が返る**
  - `FIREBASE_ID_TOKEN` の設定があるか確認
  - `User UID` ではなく `idToken` を設定しているか確認
  - 期限切れトークンでないか確認

- **record not found が返る**
  - Firebase Auth Emulator のユーザーだけ作っていて、
    アプリ内ユーザーを `POST /api/v1/users` で未作成の可能性が高い

- **BLE 反応が弱い / 出ない**
  - 端末が近いか（数十 cm）
  - Bluetooth が ON か
  - バックグラウンド動作は不安定になりやすい（iOS 制約）

---

# 現状の実装で「未実装 / 不足している可能性があるもの」

実機検証を確実にするために、現状のコード上で足りていない点は以下です。

1. **検知結果の UI 表示がない**
   - BLE 検知が起きても画面に表示されないため、
     「動いているか分からない」状態になりやすい

2. **検知ログ / デバッグ表示がない**
   - RSSI や検知トークンの確認ができない
   - コンソールにログ出しも未整備

3. **検知フィルタが厳しめ**
   - RSSI 閾値 / 検知回数 / デバウンス / クールダウンで
     短時間では検知が出づらい可能性がある

4. **バックエンド依存が必須**
   - BLE 広告開始が API 依存のため、
     API が起動していないと検証が進まない

---

## 推奨の追加対応（任意）

- 画面上に `isAdvertising / isScanning / latestDetection` を表示
- BLE 検知を `Console` に出力
- 検知フィルタをテスト用に緩める
