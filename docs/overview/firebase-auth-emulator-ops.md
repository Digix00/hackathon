# Firebase Auth エミュレータ運用手順（ローカル）

この手順書は、ローカル Docker 環境で Firebase Auth エミュレータを使い、
**iOS アプリから利用できる ID トークンを発行**するための手順です。

---

## 前提

- `backend/docker-compose.yml` で `firebase-emulator` が定義済み
- `backend/.env.development` に `FIREBASE_AUTH_EMULATOR_HOST=firebase-emulator:9099` が設定済み

---

## 1. エミュレータを起動

バックエンドの Docker を起動します。

```
cd backend

docker compose up -d
```

起動後、以下が利用できる状態になります。

- Auth Emulator: `http://localhost:9099`
- Emulator UI: `http://localhost:4000`

---

## 2. テストユーザーを作成

Emulator UI からユーザーを作成します。

1. ブラウザで `http://localhost:4000` を開く
2. Firebase Emulator UI の **Auth** タブを開く
3. **Add user** でメールとパスワードを設定

---

## 3. ID トークンを発行

作成したユーザーでログインし、ID トークンを取得します。

### 重要: UI に表示される User UID とは別物

Firebase Emulator UI に表示される `User UID` は、
そのまま `FIREBASE_ID_TOKEN` に設定する値ではありません。

- `localId`
  - Firebase UID
- `idToken`
  - iOS アプリの `FIREBASE_ID_TOKEN` に設定する値

使うのは **`idToken`** です。

### 方法A: cURL でログインして取得

以下のリクエストで `idToken` を取得できます。

```
curl -s "http://localhost:9099/identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=demo-hackathon" \
  -H "Content-Type: application/json" \
  -d '{"email":"<EMAIL>","password":"<PASSWORD>","returnSecureToken":true}'
```

レスポンスの `idToken` を控えます。

レスポンス例:

```json
{
  "localId": "tjNMTXMc0bIP9SUcYo9y10oEKJ6t",
  "email": "a@a",
  "idToken": "eyJhbGciOiJub25lIiwidHlwIjoiSldUIn0...."
}
```

- `localId` は UID
- `idToken` を Scheme に設定する

### 2 ユーザー分発行する

BLE 実機 2 台検証では、最低 2 ユーザー分の `idToken` を取得します。

例:

- User A: `a@a`
- User B: `b@b`

それぞれ `signInWithPassword` を実行して、
`USER_A_ID_TOKEN`, `USER_B_ID_TOKEN` を控えます。

---

## 4. バックエンドのアプリ内ユーザーを作成する

Firebase Auth Emulator にユーザーが存在しても、
バックエンドの `users` テーブルに対応レコードが無ければ利用できません。

未作成の場合、以下のようなエラーになります。

```text
record not found
SELECT * FROM "users" WHERE (auth_provider = 'firebase' AND provider_user_id = '...')
```

そのため、各 `idToken` ごとに一度 `POST /api/v1/users` を実行します。

### 例: User A

```bash
curl -X POST http://<MAC_LOCAL_IP>:8000/api/v1/users \
  -H "Authorization: Bearer <USER_A_ID_TOKEN>" \
  -H "Content-Type: application/json" \
  -d '{
    "display_name": "User A"
  }'
```

### 例: User B

```bash
curl -X POST http://<MAC_LOCAL_IP>:8000/api/v1/users \
  -H "Authorization: Bearer <USER_B_ID_TOKEN>" \
  -H "Content-Type: application/json" \
  -d '{
    "display_name": "User B"
  }'
```

### 作成確認

```bash
curl http://<MAC_LOCAL_IP>:8000/api/v1/users/me \
  -H "Authorization: Bearer <USER_A_ID_TOKEN>"
```

```bash
curl http://<MAC_LOCAL_IP>:8000/api/v1/users/me \
  -H "Authorization: Bearer <USER_B_ID_TOKEN>"
```

JSON でユーザー情報が返れば OK です。

---

## 5. iOS アプリへ ID トークンを設定

Xcode の Scheme で環境変数を設定します。

- Key: `FIREBASE_ID_TOKEN`
- Value: `<ID_TOKEN>`

BLE 実機 2 台検証では、Scheme を 2 つに分ける運用を推奨します。

例:

- `ios-UserA`
  - `FIREBASE_ID_TOKEN=<USER_A_ID_TOKEN>`
- `ios-UserB`
  - `FIREBASE_ID_TOKEN=<USER_B_ID_TOKEN>`

---

## 6. 動作確認のポイント

- `FIREBASE_ID_TOKEN` が未設定だと 401 になります
- トークンには有効期限があるので、401 になったら再発行
- `record not found` が出る場合は `POST /api/v1/users` が未実行の可能性が高い

---

## よくある詰まりポイント

- **Emulator UI が開けない**
  - `docker compose ps` で `firebase-emulator` が起動しているか確認
  - `http://localhost:4000` にアクセスできるか確認

- **ID トークンが取れない**
  - ユーザー作成時のメール/パスワードが合っているか確認
  - `demo-hackathon` をキーに使っているか確認

- **401 Unauthorized**
  - `idToken` ではなく `localId` / `User UID` を設定していないか確認

- **record not found**
  - Firebase Emulator 上のユーザー作成だけで終わっていないか確認
  - バックエンドに対して `POST /api/v1/users` を実行したか確認
