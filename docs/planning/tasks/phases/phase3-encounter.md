# Phase 3: すれ違い交換機能

BLE / 位置情報によるすれ違い検知と曲交換の実装。

## 3.1 すれ違い（Encounter）基盤

### 3.1.1 Encounter データモデル（Backend）

- [ ] **Backend** `internal/domain/entity/encounter.go` 定義
- [ ] **Backend** `internal/domain/vo/encounter_type.go` 定義（"ble" / "location"）
- [ ] **Backend** `internal/domain/repository/encounter.go` インターフェース定義
- [ ] **Backend** `internal/infra/rdb/encounter.go` リポジトリ実装
- [ ] **Backend** CHECK 制約実装（user_id_1 < user_id_2）

### 3.1.2 Encounter ユースケース

- [ ] **Backend** `internal/usecase/encounter.go` 実装
- [ ] **Backend** 重複すれ違い防止ロジック（同一ペア・短時間内）
- [ ] **Backend** ブロックユーザーとのすれ違い除外

### 3.1.3 Encounter API

- [ ] **Backend** `POST /encounters` - すれ違い登録
- [ ] **Backend** `GET /encounters` - すれ違い履歴一覧取得
- [ ] **Backend** `GET /encounters/:id` - すれ違い詳細取得
- [ ] **Backend** `DELETE /encounters/:id` - すれ違い履歴削除（論理削除）

## 3.2 BLE すれ違い検知

### 3.2.1 iOS BLE すれ違い処理

- [ ] **iOS** BLE トークン検出時のすれ違い判定ロジック
- [ ] **iOS** すれ違いレコードのローカル保存（Core Data / Realm）
- [ ] **iOS** オンライン時にサーバーへ送信
- [ ] **iOS** 送信成功後のローカルレコード削除

### 3.2.2 Android BLE すれ違い処理

- [ ] **Android** BLE トークン検出時のすれ違い判定ロジック
- [ ] **Android** すれ違いレコードのローカル保存（Room）
- [ ] **Android** オンライン時にサーバーへ送信
- [ ] **Android** 送信成功後のローカルレコード削除

## 3.3 位置情報すれ違い検知

### 3.3.1 位置情報基盤（Backend）

- [ ] **Backend** 位置情報ぼかし処理実装（ランダムベクトル付加）
- [ ] **Backend** 近接判定ロジック実装（半径設定：100/500/1000/5000m）
- [ ] **Backend** 位置情報マッチング処理実装

### 3.3.2 位置情報 API

- [ ] **Backend** `POST /locations` - 位置情報送信
- [ ] **Backend** 近接ユーザー検索・すれ違い自動生成

### 3.3.3 iOS 位置情報

- [ ] **iOS** CoreLocation 権限リクエスト
- [ ] **iOS** 位置情報取得（significant-change / region monitoring）
- [ ] **iOS** 位置情報送信処理
- [ ] **iOS** バッテリー消費最適化

### 3.3.4 Android 位置情報

- [ ] **Android** 位置情報権限リクエスト
- [ ] **Android** FusedLocationProvider による位置取得
- [ ] **Android** 位置情報送信処理
- [ ] **Android** バッテリー消費最適化

## 3.4 曲交換機能

### 3.4.1 曲交換ロジック

- [ ] **Backend** すれ違い成立時に相手のお気に入り曲を取得
- [ ] **Backend** 交換曲情報をすれ違いレコードに紐付け

### 3.4.2 曲交換 API

- [ ] **Backend** `GET /encounters/:id/tracks` - すれ違いで交換した曲一覧

### 3.4.3 交換曲表示画面

- [ ] **iOS** すれ違い詳細画面（相手のプロフィール + 曲）
- [ ] **iOS** 交換曲の再生（Spotify 連携）
- [ ] **Android** すれ違い詳細画面（相手のプロフィール + 曲）
- [ ] **Android** 交換曲の再生（Spotify 連携）

## 3.5 プレイリスト交換

### 3.5.1 プレイリスト基盤（Backend）

- [ ] **Backend** `internal/domain/entity/playlist.go` 定義
- [ ] **Backend** `internal/domain/entity/playlist_track.go` 定義
- [ ] **Backend** `internal/domain/repository/playlist.go` インターフェース定義
- [ ] **Backend** `internal/infra/rdb/playlist.go` リポジトリ実装

### 3.5.2 プレイリスト API

- [ ] **Backend** `POST /playlists` - プレイリスト作成
- [ ] **Backend** `GET /playlists/me` - プレイリスト一覧取得
- [ ] **Backend** `GET /playlists/:id` - プレイリスト詳細取得
- [ ] **Backend** `PATCH /playlists/:id` - プレイリスト更新
- [ ] **Backend** `DELETE /playlists/:id` - プレイリスト削除
- [ ] **Backend** `POST /playlists/:id/tracks` - プレイリストに曲追加
- [ ] **Backend** `DELETE /playlists/:id/tracks/:track_id` - プレイリストから曲削除

### 3.5.3 プレイリスト画面

- [ ] **iOS** プレイリスト一覧画面
- [ ] **iOS** プレイリスト作成・編集画面
- [ ] **iOS** プレイリスト詳細画面（曲一覧）
- [ ] **Android** プレイリスト一覧画面
- [ ] **Android** プレイリスト作成・編集画面
- [ ] **Android** プレイリスト詳細画面（曲一覧）

## 3.6 すれ違い履歴画面

### 3.6.1 履歴一覧

- [ ] **iOS** すれ違い履歴一覧画面
- [ ] **iOS** 日付・タイプ（BLE/位置情報）でのフィルタ
- [ ] **iOS** 履歴削除機能
- [ ] **Android** すれ違い履歴一覧画面
- [ ] **Android** 日付・タイプ（BLE/位置情報）でのフィルタ
- [ ] **Android** 履歴削除機能

## 完了条件

- [ ] BLE 近接検知ですれ違いが成立する
- [ ] 位置情報ですれ違いが成立する
- [ ] すれ違い時に相手のお気に入り曲が取得できる
- [ ] すれ違い履歴が一覧表示される
- [ ] プレイリストの作成・編集・交換ができる
