# iOS アプリ開発環境セットアップ

## 前提

- Xcode（iOS 18.6 以上に対応したバージョン）
- Swift 5.0 以上

## 初回セットアップ

### 1. Xcode でプロジェクトを開く

```bash
open ios.xcodeproj
```

### 2. Swift Package Manager による依存関係の解決

Xcode がプロジェクトを開いた際に自動的に依存関係を解決します。

### 3. Firebase 設定ファイルを用意する

iOS は `.env` ではなく `xcconfig` を使います。まず example をコピーしてください。

```bash
cp ios/config/Secrets.example.xcconfig ios/config/Secrets.xcconfig
```

`ios/config/Secrets.xcconfig` は `.gitignore` で除外しています。実値はコミットしません。

最低限必要なキー:

```xcconfig
FIREBASE_API_KEY = YOUR_IOS_FIREBASE_API_KEY
FIREBASE_APP_ID = YOUR_IOS_FIREBASE_APP_ID
FIREBASE_GCM_SENDER_ID = YOUR_FIREBASE_SENDER_ID
FIREBASE_PROJECT_ID = YOUR_FIREBASE_PROJECT_ID
FIREBASE_STORAGE_BUCKET = YOUR_FIREBASE_STORAGE_BUCKET
GOOGLE_CLIENT_ID = YOUR_IOS_GOOGLE_CLIENT_ID
GOOGLE_REVERSED_CLIENT_ID = YOUR_IOS_REVERSED_CLIENT_ID
```

### 4. Firebase Console 側の前提

- Firebase Authentication で `apple.com` と Google を有効化
- iOS アプリを Firebase に登録
- Google ログインを使う場合は iOS 用 Client ID と Reversed Client ID を取得

`GoogleService-Info.plist` を使う運用でも動きますが、このプロジェクトでは `Secrets.xcconfig` だけでも Firebase を初期化できます。

## プロジェクト構造

```text
ios/
├── App/
├── Core/
├── Features/
├── Shared/
└── config/
    ├── Debug.xcconfig
    ├── Release.xcconfig
    ├── Secrets.example.xcconfig
    └── Secrets.xcconfig
```

## 環境別設定

### Debug（開発環境）

- Bundle ID: `com.digix.ios.dev`
- App Display Name: `ios Dev`
- API Base URL: `https://dev-api.example.com`
- APP_ENV: `debug`

### Release（本番環境）

- Bundle ID: `com.digix.ios`
- App Display Name: `ios`
- API Base URL: `https://api.example.com`
- APP_ENV: `release`

## ローカル開発環境への接続

バックエンドがローカルで起動している場合（`http://127.0.0.1:8000`）、`ios/config/Debug.xcconfig` の `API_BASE_URL` を以下のように変更してください。

```xcconfig
API_BASE_URL = http:/$()/127.0.0.1:8000
```

`$()/` は Xcode の設定ファイルで `//` を表すための記法です。

### Firebase Auth Emulator のトークンを使う

ローカルの `encounters` 取得には Firebase ID トークンが必要です。開発環境では Firebase Auth Emulator を使ってトークンを発行し、Xcode の環境変数で渡します。

1. Firebase Auth Emulator でデモユーザーを作成（UID は `demo-user-1`）

```bash
curl -s "http://127.0.0.1:9099/identitytoolkit.googleapis.com/v1/accounts:signUp?key=demo" \
  -H "Content-Type: application/json" \
  -d '{
    "email": "demo1@example.com",
    "password": "password",
    "returnSecureToken": true,
    "localId": "demo-user-1"
  }'
```

2. Xcode の Run Scheme で環境変数を設定

- `API_BASE_URL = http://127.0.0.1:8000`
- `FIREBASE_ID_TOKEN = <emulatorで発行したtoken>`

`FIREBASE_ID_TOKEN` は `BackendAPIClient` が優先して使用します。

## ビルド・実行

1. Xcode で `ios` スキームを選択
2. シミュレータまたは実機を選択
3. `Cmd + R` でビルド・実行

## トラブルシューティング

### Swift Package Manager の依存関係が解決されない場合

```text
File > Packages > Reset Package Caches
```

### ビルドエラーが発生する場合

1. `Cmd + Shift + K` でクリーンビルド
2. DerivedData を削除

```bash
rm -rf ~/Library/Developer/Xcode/DerivedData
```

## 関連ファイル

- `ios.xcodeproj`
- `ios/config/*.xcconfig`
- `ios/config/Secrets.example.xcconfig`
- `.gitignore`
