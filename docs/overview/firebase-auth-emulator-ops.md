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

### 方法A: cURL でログインして取得

以下のリクエストで `idToken` を取得できます。

```
curl -s "http://localhost:9099/identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=demo-hackathon" \
  -H "Content-Type: application/json" \
  -d '{"email":"<EMAIL>","password":"<PASSWORD>","returnSecureToken":true}'
```

レスポンスの `idToken` を控えます。

---

## 4. iOS アプリへ ID トークンを設定

Xcode の Scheme で環境変数を設定します。

- Key: `FIREBASE_ID_TOKEN`
- Value: `<ID_TOKEN>`

---

## 5. 動作確認のポイント

- `FIREBASE_ID_TOKEN` が未設定だと 401 になります
- トークンには有効期限があるので、401 になったら再発行

---

## よくある詰まりポイント

- **Emulator UI が開けない**
  - `docker compose ps` で `firebase-emulator` が起動しているか確認
  - `http://localhost:4000` にアクセスできるか確認

- **ID トークンが取れない**
  - ユーザー作成時のメール/パスワードが合っているか確認
  - `demo-hackathon` をキーに使っているか確認

