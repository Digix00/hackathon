# Phase 2: BLE機能・曲設定

BLE近接検知と外部音楽API連携の実装。

## 2.1 BLE トークン管理

### 2.1.1 BLE トークン基盤（Backend）

- [ ] **Backend** `internal/domain/entity/ble_token.go` 定義
- [ ] **Backend** `internal/domain/repository/ble_token.go` インターフェース定義
- [ ] **Backend** `internal/infra/rdb/ble_token.go` リポジトリ実装
- [ ] **Backend** `internal/usecase/ble_token.go` ユースケース実装
- [ ] **Backend** トークン生成ロジック実装（UUID v4）

### 2.1.2 BLE トークン API

- [ ] **Backend** `POST /ble-tokens` - 新規トークン発行
- [ ] **Backend** `GET /ble-tokens/current` - 現在有効なトークン取得
- [ ] **Backend** `GET /ble-tokens/:token/user` - トークンからユーザー情報取得

### 2.1.3 BLE トークン定期処理

- [ ] **Backend** `cmd/worker/` に期限切れトークン削除処理実装
- [ ] **Infra** Cloud Scheduler で毎日 0:00 UTC にトークンローテーションをキック

## 2.2 iOS BLE 実装

### 2.2.1 BLE 基盤

- [ ] **iOS** CoreBluetooth マネージャークラス実装
- [ ] **iOS** Info.plist に BLE バックグラウンド設定追加
- [ ] **iOS** Bluetooth 権限リクエスト実装

### 2.2.2 BLE Peripheral（アドバタイズ）

- [ ] **iOS** Peripheral マネージャー実装
- [ ] **iOS** Service / Characteristic 定義
- [ ] **iOS** BLE トークンをアドバタイズデータに設定
- [ ] **iOS** バックグラウンドアドバタイズ対応

### 2.2.3 BLE Central（スキャン）

- [ ] **iOS** Central マネージャー実装
- [ ] **iOS** 対象 Service UUID でスキャン
- [ ] **iOS** 検出した Peripheral から BLE トークン読み取り
- [ ] **iOS** バックグラウンドスキャン対応
- [ ] **iOS** RSSI による距離推定（参考値）

### 2.2.4 BLE 状態管理

- [ ] **iOS** BLE ON/OFF 状態監視
- [ ] **iOS** バックグラウンド復帰時の再開処理
- [ ] **iOS** エラーハンドリング（権限拒否、BLE 未対応）

## 2.3 Android BLE 実装

### 2.3.1 BLE 基盤

- [ ] **Android** Bluetooth マネージャークラス実装
- [ ] **Android** BLUETOOTH_SCAN / BLUETOOTH_ADVERTISE 権限リクエスト
- [ ] **Android** 位置情報権限リクエスト（BLE スキャンに必要）

### 2.3.2 BLE Advertiser

- [ ] **Android** AdvertiseCallback 実装
- [ ] **Android** Service / Characteristic 定義
- [ ] **Android** BLE トークンをアドバタイズデータに設定
- [ ] **Android** Foreground Service 化

### 2.3.3 BLE Scanner

- [ ] **Android** BluetoothLeScanner 実装
- [ ] **Android** ScanCallback でデバイス検出
- [ ] **Android** 検出した Advertiser から BLE トークン読み取り
- [ ] **Android** Foreground Service でバックグラウンドスキャン
- [ ] **Android** RSSI による距離推定（参考値）

### 2.3.4 BLE 状態管理

- [ ] **Android** Bluetooth ON/OFF 状態監視
- [ ] **Android** 省電力設定による停止への対処
- [ ] **Android** エラーハンドリング

## 2.4 外部音楽 API 連携

### 2.4.1 Spotify API 連携（Backend）

- [ ] **Backend** `internal/usecase/port/music.go` インターフェース定義
- [ ] **Backend** `internal/infra/music/spotify.go` 実装
- [ ] **Backend** Spotify OAuth 2.0 認可フロー実装
- [ ] **Backend** 楽曲検索 API 呼び出し実装
- [ ] **Backend** 楽曲詳細取得 API 呼び出し実装

### 2.4.2 Spotify 連携 API

- [ ] **Backend** `GET /music-connections/{provider}/authorize`（`provider=spotify`） - Spotify 認可開始
- [ ] **Backend** `GET /music-connections/{provider}/callback`（`provider=spotify`） - Spotify 認可コールバック
- [ ] **Backend** `GET /tracks/search` - 楽曲検索
- [ ] **Backend** `GET /tracks/:id` - 楽曲詳細取得

### 2.4.3 iOS Spotify 連携

- [ ] **iOS** Spotify iOS SDK 導入
- [ ] **iOS** OAuth 認可フロー実装
- [ ] **iOS** 楽曲検索 UI 実装
- [ ] **iOS** 楽曲詳細表示 UI 実装
- [ ] **iOS** ジャケット画像キャッシュ実装

### 2.4.4 Android Spotify 連携

- [ ] **Android** Spotify Android SDK 導入
- [ ] **Android** OAuth 認可フロー実装
- [ ] **Android** 楽曲検索 UI 実装
- [ ] **Android** 楽曲詳細表示 UI 実装
- [ ] **Android** ジャケット画像キャッシュ実装

## 2.5 曲設定機能

### 2.5.1 ユーザー曲登録（Backend）

- [ ] **Backend** `internal/domain/entity/user_track.go` 定義
- [ ] **Backend** `internal/domain/repository/user_track.go` インターフェース定義
- [ ] **Backend** `internal/infra/rdb/user_track.go` リポジトリ実装
- [ ] **Backend** `internal/usecase/user_track.go` ユースケース実装

### 2.5.2 曲設定 API

- [ ] **Backend** `POST /users/me/tracks` - お気に入り曲登録
- [ ] **Backend** `GET /users/me/tracks` - お気に入り曲一覧取得
- [ ] **Backend** `DELETE /users/me/tracks/:id` - お気に入り曲削除

### 2.5.3 曲設定画面

- [ ] **iOS** お気に入り曲一覧画面
- [ ] **iOS** 曲追加フロー（検索 → 選択 → 登録）
- [ ] **iOS** 曲削除機能
- [ ] **Android** お気に入り曲一覧画面
- [ ] **Android** 曲追加フロー（検索 → 選択 → 登録）
- [ ] **Android** 曲削除機能

## 完了条件

- [ ] iOS / Android で BLE アドバタイズ・スキャンが動作する
- [ ] バックグラウンドで BLE が継続動作する（技術検証完了）
- [ ] Spotify 連携で楽曲検索・詳細取得ができる
- [ ] お気に入り曲の登録・一覧・削除が動作する
