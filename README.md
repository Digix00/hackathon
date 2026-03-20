# hackathon

## リポジトリ構成

| ディレクトリ | 内容 |
|---|---|
| `backend/` | Go + Echo サーバー / Worker / Firebase Emulator / PostgreSQL |
| `ios/` | iOS アプリ（Swift） |
| `android/` | Android アプリ |

## バックエンド

詳細は [backend/README.md](backend/README.md) を参照してください。

```bash
cd backend
make run-dev
```

## iOS アプリ

詳細は [ios/README.md](ios/README.md) を参照してください。

```bash
open ios/ios.xcodeproj
```

## Mobile Firebase Auth 設定

このリポジトリではモバイル向け設定に `.env` は使いません。各プラットフォームの標準的な方法で管理します。

- iOS: `ios/ios/config/Secrets.xcconfig`
- Android: `android/local.properties`

どちらも実ファイルは Git に載せず、example ファイルを元に作成します。

### iOS

```bash
cp ios/ios/config/Secrets.example.xcconfig ios/ios/config/Secrets.xcconfig
```

必要な主な値:

- `FIREBASE_API_KEY`
- `FIREBASE_APP_ID`
- `FIREBASE_GCM_SENDER_ID`
- `FIREBASE_PROJECT_ID`
- `FIREBASE_STORAGE_BUCKET`
- `GOOGLE_CLIENT_ID`
- `GOOGLE_REVERSED_CLIENT_ID`

### Android

```bash
cp android/local.properties.example android/local.properties
cp android/app/google-services.json.example android/app/google-services.json
```

必要な主な値:

- `dev.google.web_client_id`
- `prod.api.base_url`
- `prod.google.web_client_id`
- `google-services.json` 内の Firebase Android 設定

注意:

- Apple Sign In は iOS のみです
- Google Sign In は iOS / Android でそれぞれの Client ID が必要です
- Firebase の API key や App ID はクライアントに入る前提の公開設定値であり、サーバー秘密鍵ではありません
- Firebase Admin SDK の credential や OAuth client secret はモバイルアプリに入れません

## 関連ファイル

- `backend/Makefile` - 開発用コマンド定義
- `backend/docker-compose.yml`
- `backend/firebase.json`
- `backend/.env.development`
- `backend/cmd/server/main.go`
- `ios/README.md` - iOS アプリのセットアップ手順
- `ios/ios/config/Secrets.example.xcconfig` - iOS Firebase 設定テンプレート
- `android/local.properties.example` - Android ローカル設定テンプレート
- `android/app/google-services.json.example` - Android Firebase 設定テンプレート
