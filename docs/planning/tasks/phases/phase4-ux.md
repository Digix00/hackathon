# Phase 4: ユーザー体験向上

オンボーディング、いいね、コメント、通報機能の実装。

## 4.1 オンボーディング

### 4.1.1 オンボーディングフロー設計

- [ ] **iOS** オンボーディング画面設計（アプリ説明）
- [ ] **iOS** 権限リクエスト順序の実装（Bluetooth → 通知 → 位置情報）
- [ ] **iOS** 権限拒否時の再リクエスト導線
- [ ] **Android** オンボーディング画面設計（アプリ説明）
- [ ] **Android** 権限リクエスト順序の実装
- [ ] **Android** 権限拒否時の再リクエスト導線

### 4.1.2 初回設定フロー

- [ ] **iOS** プロフィール初期設定画面
- [ ] **iOS** お気に入り曲初期設定画面
- [ ] **iOS** 設定完了画面
- [ ] **Android** プロフィール初期設定画面
- [ ] **Android** お気に入り曲初期設定画面
- [ ] **Android** 設定完了画面

## 4.2 いいね（Favorites）機能

### 4.2.1 曲いいね基盤（Backend）

- [ ] **Backend** `internal/domain/entity/track_favorite.go` 定義
- [ ] **Backend** `internal/domain/repository/track_favorite.go` インターフェース定義
- [ ] **Backend** `internal/infra/rdb/track_favorite.go` リポジトリ実装
- [ ] **Backend** `internal/usecase/track_favorite.go` ユースケース実装

### 4.2.2 曲いいね API

- [ ] **Backend** `POST /tracks/:id/favorites` - 曲にいいね
- [ ] **Backend** `DELETE /tracks/:id/favorites` - いいね取り消し
- [ ] **Backend** `GET /users/me/track-favorites` - いいねした曲一覧

### 4.2.3 プレイリストいいね基盤（Backend）

- [ ] **Backend** `internal/domain/entity/playlist_favorite.go` 定義
- [ ] **Backend** `internal/domain/repository/playlist_favorite.go` インターフェース定義
- [ ] **Backend** `internal/infra/rdb/playlist_favorite.go` リポジトリ実装
- [ ] **Backend** `internal/usecase/playlist_favorite.go` ユースケース実装

### 4.2.4 プレイリストいいね API

- [ ] **Backend** `POST /playlists/:id/favorites` - プレイリストにいいね
- [ ] **Backend** `DELETE /playlists/:id/favorites` - いいね取り消し
- [ ] **Backend** `GET /users/me/playlist-favorites` - いいねしたプレイリスト一覧

### 4.2.5 いいね画面

- [ ] **iOS** いいねボタン UI（曲詳細・プレイリスト詳細）
- [ ] **iOS** いいねした曲一覧画面
- [ ] **iOS** いいねしたプレイリスト一覧画面
- [ ] **Android** いいねボタン UI（曲詳細・プレイリスト詳細）
- [ ] **Android** いいねした曲一覧画面
- [ ] **Android** いいねしたプレイリスト一覧画面

## 4.3 コメント機能

### 4.3.1 コメント基盤（Backend）

- [ ] **Backend** `internal/domain/entity/comment.go` 定義
- [ ] **Backend** `internal/domain/repository/comment.go` インターフェース定義
- [ ] **Backend** `internal/infra/rdb/comment.go` リポジトリ実装
- [ ] **Backend** `internal/usecase/comment.go` ユースケース実装

### 4.3.2 コメント API

- [ ] **Backend** `POST /encounters/:id/comments` - コメント投稿
- [ ] **Backend** `GET /encounters/:id/comments` - コメント一覧取得
- [ ] **Backend** `DELETE /comments/:id` - コメント削除（自分のコメントのみ）

### 4.3.3 コメント画面

- [ ] **iOS** すれ違い詳細画面にコメント表示
- [ ] **iOS** コメント入力 UI
- [ ] **iOS** コメント削除機能
- [ ] **Android** すれ違い詳細画面にコメント表示
- [ ] **Android** コメント入力 UI
- [ ] **Android** コメント削除機能

## 4.4 通報機能

### 4.4.1 通報基盤（Backend）

- [ ] **Backend** `internal/domain/entity/report.go` 定義
- [ ] **Backend** `internal/domain/repository/report.go` インターフェース定義
- [ ] **Backend** `internal/infra/rdb/report.go` リポジトリ実装
- [ ] **Backend** `internal/usecase/report.go` ユースケース実装
- [ ] **Backend** 通報回数による is_restricted フラグ更新ロジック

### 4.4.2 通報 API

- [ ] **Backend** `POST /reports` - ユーザー通報
- [ ] **Backend** 通報理由テンプレート定義

### 4.4.3 通報画面

- [ ] **iOS** 通報ボタン UI（すれ違い詳細画面）
- [ ] **iOS** 通報理由選択ダイアログ
- [ ] **iOS** 通報完了確認
- [ ] **Android** 通報ボタン UI（すれ違い詳細画面）
- [ ] **Android** 通報理由選択ダイアログ
- [ ] **Android** 通報完了確認

## 4.5 ブロック・ミュート機能

### 4.5.1 ブロック基盤（Backend）

- [ ] **Backend** `internal/domain/entity/block.go` 定義
- [ ] **Backend** `internal/domain/repository/block.go` インターフェース定義
- [ ] **Backend** `internal/infra/rdb/block.go` リポジトリ実装
- [ ] **Backend** `internal/usecase/block.go` ユースケース実装

### 4.5.2 ブロック API

- [ ] **Backend** `POST /users/me/blocks` - ユーザーブロック
- [ ] **Backend** `DELETE /users/me/blocks/:blocked_user_id` - ブロック解除
- [ ] **Backend** `GET /users/me/blocks` - ブロック一覧取得

### 4.5.3 ミュート基盤（Backend）

- [ ] **Backend** `internal/domain/entity/mute.go` 定義
- [ ] **Backend** `internal/domain/repository/mute.go` インターフェース定義
- [ ] **Backend** `internal/infra/rdb/mute.go` リポジトリ実装
- [ ] **Backend** `internal/usecase/mute.go` ユースケース実装

### 4.5.4 ミュート API

- [ ] **Backend** `POST /users/me/mutes` - ユーザーミュート
- [ ] **Backend** `DELETE /users/me/mutes/:target_user_id` - ミュート解除
- [ ] **Backend** `GET /users/me/mutes` - ミュート一覧取得

### 4.5.5 ブロック・ミュート画面

- [ ] **iOS** ブロック / ミュートボタン UI
- [ ] **iOS** ブロック一覧画面（設定内）
- [ ] **iOS** ミュート一覧画面（設定内）
- [ ] **Android** ブロック / ミュートボタン UI
- [ ] **Android** ブロック一覧画面（設定内）
- [ ] **Android** ミュート一覧画面（設定内）

## 4.6 ホーム画面

### 4.6.1 ホーム画面実装

- [ ] **iOS** ホーム画面レイアウト
- [ ] **iOS** すれ違い数表示
- [ ] **iOS** 一押しソング表示
- [ ] **iOS** 最近のすれ違いサマリ
- [ ] **Android** ホーム画面レイアウト
- [ ] **Android** すれ違い数表示
- [ ] **Android** 一押しソング表示
- [ ] **Android** 最近のすれ違いサマリ

## 4.7 設定画面

### 4.7.1 設定画面実装

- [ ] **iOS** 設定画面トップ
- [ ] **iOS** プロフィール設定
- [ ] **iOS** すれ違い半径設定
- [ ] **iOS** 通知設定
- [ ] **iOS** 公開範囲設定
- [ ] **iOS** ブロック / ミュート一覧
- [ ] **iOS** ヘルプ / FAQ
- [ ] **iOS** ログアウト
- [ ] **iOS** アカウント削除
- [ ] **Android** 設定画面トップ
- [ ] **Android** プロフィール設定
- [ ] **Android** すれ違い半径設定
- [ ] **Android** 通知設定
- [ ] **Android** 公開範囲設定
- [ ] **Android** ブロック / ミュート一覧
- [ ] **Android** ヘルプ / FAQ
- [ ] **Android** ログアウト
- [ ] **Android** アカウント削除

## 完了条件

- [ ] オンボーディングで権限取得・初期設定が完了する
- [ ] 曲 / プレイリストにいいねできる
- [ ] すれ違いにコメントできる
- [ ] ユーザーを通報 / ブロック / ミュートできる
- [ ] ホーム画面にすれ違い数・一押しソングが表示される
- [ ] 設定画面から各種設定変更ができる
