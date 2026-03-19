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

### 3. Secrets.xcconfig の作成

`ios/config/Secrets.xcconfig` は `.gitignore` で除外されているため、手動で作成する必要があります。

```bash
touch ios/config/Secrets.xcconfig
```

Firebase の API キーなどの秘匿情報を記述してください。

```
// Secrets.xcconfig の例
FIREBASE_API_KEY = your_firebase_api_key_here
```

## プロジェクト構造

```
ios/
├── App/          # アプリケーションエントリーポイント
├── Core/         # コア機能
├── Features/     # 機能別モジュール
├── Shared/       # 共有コンポーネント
└── config/       # 環境別設定ファイル
    ├── Debug.xcconfig    # 開発環境設定
    ├── Release.xcconfig  # 本番環境設定
    └── Secrets.xcconfig  # 秘匿情報（要手動作成）
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

```
API_BASE_URL = http:/$()/127.0.0.1:8000
```

※ `$()/` は Xcode の設定ファイルで `//` をエスケープするための記法です。Run Scheme の環境変数では不要です。

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

レスポンスの `idToken` を控えておきます。

2. Xcode の Run Scheme で環境変数を設定

- `API_BASE_URL` = `http://127.0.0.1:8000`
- `FIREBASE_ID_TOKEN` = `<emulatorで発行したtoken>`

`FIREBASE_ID_TOKEN` は `BackendAPIClient` が優先して使用します。

## ビルド・実行

1. Xcode で `ios` スキームを選択
2. シミュレータまたは実機を選択
3. `Cmd + R` でビルド・実行

## トラブルシューティング

### Swift Package Manager の依存関係が解決されない場合

```
File > Packages > Reset Package Caches
```

### ビルドエラーが発生する場合

1. `Cmd + Shift + K` でクリーンビルド
2. DerivedData を削除

```bash
rm -rf ~/Library/Developer/Xcode/DerivedData
```

## 関連ファイル

- `ios.xcodeproj` - Xcode プロジェクトファイル
- `ios/config/*.xcconfig` - 環境別設定ファイル
- `.gitignore` - Git 除外設定
