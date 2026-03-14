# 技術スタック概要

すれ違い趣味交換アプリ全体の技術選定まとめ。各領域の詳細は個別ドキュメントを参照。

## 構成マップ

```
[iOS (Swift)]  [Android (Kotlin)]
       ↓               ↓
    REST API (JSON)
       ↓
   [Backend: Go + Echo]
       ↓
   [Cloud SQL (GCP)]
```

## レイヤー別スタック一覧

| レイヤー | 技術 | 詳細ドキュメント |
|---|---|---|
| iOS | Swift | [mobile.md](./mobile.md) |
| Android | Kotlin | [mobile.md](./mobile.md) |
| Backend | Go + Echo | [backend.md](./backend.md) |
| DB | Cloud SQL（PostgreSQL） | [backend.md](./backend.md) |
| インフラ | GCP / Terraform | [infrastructure.md](./infrastructure.md) |
| スキーマ | OpenAPI 3.x | [schema.md](./schema.md) |
| CI/CD | GitHub Actions | [cicd.md](./cicd.md) |

## 外部連携

| サービス | 用途 |
|---|---|
| Spotify API | 楽曲情報取得・OAuth連携 |
| Apple Music API | 楽曲情報取得（地域差・審査難度に注意） |
| APNs | iOS プッシュ通知 |
| FCM | Android プッシュ通知 |

## 近接検知方式

| 方式 | 対象データ | 備考 |
|---|---|---|
| BLE | プロフィール・楽曲・プレイリスト | バックグラウンド動作制約あり（最優先技術検証） |
| 位置情報 | プロフィール・楽曲 | ぼかし処理（ランダムベクトル付加）が必要 |

## 認証フロー

```
[iOS]  Sign in with Apple
[Android]  Google Sign-In
       ↓
   Firebase Auth（ID トークン発行）
       ↓
   Bearer ヘッダに付けて Backend へ送信
       ↓
   Backend が Firebase Admin SDK でトークン検証 → UID 取得
       ↓
   UID をキーに Cloud SQL のユーザーレコードを参照・操作
```

- iOS は App Store ガイドライン上、サードパーティ認証を使う場合は Sign in with Apple が必須
- Android は Google Sign-In を採用
- Backend は Firebase ID トークンを直接検証し、独自セッションは持たない

## 主要な設計方針

- BLE ID は短命（毎日ローテーション）で追跡防止
- 位置情報はサーバーサイドでぼかして保存
- 通知はバッチ処理（10〜20分ごと）で連投防止
- MVP では画像・地図・再配布機能を除外
