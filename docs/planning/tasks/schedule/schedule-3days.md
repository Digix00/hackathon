# 実装スケジュール（3/14〜3/17）

> **最終更新**: 2026-03-16
> **現在**: Day 2（3/16 月）進行中

## 進捗サマリー

| ブランチ | 状態 | 概要 |
|---|---|---|
| `feat/gcp-resource-terraform` | ✅ 完了 | GCPインフラ構築（Cloud Run, Cloud SQL, Scheduler, Secret Manager） |
| `api-design` | ✅ 完了 | API設計・ER図・Backend設計ドキュメント整備 |
| `setup-android` | ✅ 完了 | Android環境セットアップ（CI/CD, BLE基盤, Room, Retrofit） |
| `feat/prototype` | 🔄 進行中 | iOSプロトタイプ（UIテーマ、画面コンポーネント） |

---

## メンバー・シフト

| 名前 | 役割 | 3/14(土) | 3/15(日) | 3/16(月) | 3/17(火) |
|---|---|---|---|---|---|
| 曽根 | iOS | 午後〜 | 10:00-13:15, 17:00-19:30 | 10:00-21:00 | 15:00-22:00 |
| 粉川 | Android（Backend得意） | 午後〜 | 12:00-24:00 | 12:00〜 | - |
| 三村 | Backend | - | 10:00〜 | 9:15-10:00, 21:00〜 | 9:15-10:00, 21:00-24:00 |
| 河田 | リベロ | - | - | 12:00〜 | - |

---

## Day 0: 3/14 (土) 午後 - 準備フェーズ

**稼働: 曽根 + 粉川（2名）**

### 目標
- プロジェクト初期化
- 開発環境セットアップ
- 翌日の本格実装に備える

### タスク割り当て

| 曽根 (iOS) | 粉川 (Backend) | 三村 (Infra) |
|---|---|---|
| Xcode プロジェクト作成 | Go プロジェクト初期化（Echo） | GCP Terraform 設定（`feat/gcp-resource-terraform`） |
| Firebase SDK 導入 | ディレクトリ構造作成 | Cloud Run / Cloud SQL / Scheduler リソース定義 |
| Sign in with Apple 設定開始 | docker-compose.yml 作成 | API設計ドキュメント作成（`api-design`） |
| | PostgreSQL + Firebase Auth Emulator 設定 | Android環境セットアップ開始（`setup-android`） |

### Day 0 完了条件
- [x] iOS プロジェクトが作成され、Firebase SDK が導入されている
- [x] Backend プロジェクトが初期化され、`docker compose up` で起動する
- [x] PostgreSQL と Firebase Auth Emulator が動作する
- [x] GCP Terraform リソース定義完了（Cloud Run, Cloud SQL, Scheduler, Secret Manager）
- [x] API設計・ER図ドキュメント整備完了（`api-design` ブランチ）
- [x] Android環境セットアップ完了（CI/CD, BLE基盤, Room, Retrofit）

---

## Day 1: 3/15 (日) - Android基盤・iOS BLE準備

**稼働: 三村(10:00〜), 曽根(10:00-13:15, 17:00-19:30), 粉川(12:00-24:00)**

### 目標
- Android BLE基盤が完成する
- iOS BLE実装の準備が整う

### タスク割り当て

| 時間 | 曽根 (iOS) | 粉川 (Backend/Android) | 三村 (Backend) |
|---|---|---|---|
| 10:00-12:00 | iOS BLE調査・技術検証 | - | DB スキーマ設計・マイグレーション |
| 12:00-13:15 | iOS BLE設計 | Android CI/CD構築 | ログ基盤 (zap) 実装 |
| 13:15-17:00 | （休憩） | Android BLE基盤実装 | Backend API 設計 |
| 17:00-19:30 | iOS BLE実装準備 | Android Room/Retrofit設定 | BLE トークンAPI設計 |
| 19:30-24:00 | - | Android BLE完成・レビュー対応 | - |

### Day 1 完了条件
- [x] Android環境セットアップ完了（CI/CD, BLE基盤, Room, Retrofit）（`setup-android` ブランチ）
- [x] iOS BLE技術調査・設計完了
- [-] iOS から Sign in with Apple でログインできる（実装スキップ）
- [-] `POST /users` でユーザー登録できる（後回し）
- [-] `GET /users/me` で自分の情報が取得できる（後回し）

---

## Day 2: 3/16 (月) - iOS BLE実装

**稼働: 三村(9:15-10:00, 21:00〜), 曽根(10:00-21:00), 粉川(12:00〜), 河田(12:00〜)**

### 目標
- iOS BLE アドバタイズ・スキャンが動作する
- iOS プロトタイプUIが完成する
- バックグラウンドBLE動作検証

### タスク割り当て

| 時間 | 曽根 (iOS) | 粉川 (Backend) | 三村 (Backend) | 河田 (支援) |
|---|---|---|---|---|
| 9:15-10:00 | - | - | BLE トークン API レビュー | - |
| 10:00-12:00 | iOS BLE Peripheral 実装 | - | - | - |
| 12:00-15:00 | iOS BLE Central 実装 | Backend BLE トークン API | - | iOS BLE 技術調査 |
| 15:00-18:00 | バックグラウンドBLE検証 | Backend Encounter API 設計 | - | iOS BLE 支援 |
| 18:00-21:00 | iOS プロトタイプUI統合 | Backend Encounter API 実装 | - | iOS 支援 |
| 21:00-24:00 | - | Backend API 実装継続 | - | - |

### Day 2 完了条件
- [x] iOS プロトタイプ完成（UIテーマ、画面コンポーネント）（`feat/prototype` ブランチ）
- [ ] iOS で BLE アドバタイズ・スキャンが動作する
- [ ] **バックグラウンドで BLE が継続動作する（最重要検証）**
- [ ] Backend BLE トークン API 完成
- [ ] Backend Encounter API 設計完了
- [-] Spotify 連携で楽曲検索ができる（後回し）
- [-] お気に入り曲の登録・一覧・削除ができる（後回し）

---

## Day 3: 3/17 (火) - すれ違い検知実装

**稼働: 三村(9:15-10:00, 21:00-24:00), 曽根(15:00-22:00)**
※ 粉川・河田は不在

### 目標
- BLE すれ違い検知が動作する
- すれ違いデータがBackendに送信される

### タスク割り当て

| 時間 | 曽根 (iOS) | 三村 (Backend) |
|---|---|---|
| 9:15-10:00 | - | Encounter API 実装開始 |
| 15:00-18:00 | BLE すれ違い検知実装 | - |
| 18:00-21:00 | ローカルキュー実装 | - |
| 21:00-22:00 | iOS ↔ Backend 統合テスト | Encounter API 完成 |
| 22:00-24:00 | - | 曲交換ロジック実装 |

### Day 3 完了条件
- [ ] iOS BLE すれ違い検知が動作する
- [ ] BLE トークンをBackendに送信できる
- [ ] Backend Encounter API 完成
- [ ] すれ違いデータが DB に保存される
- [-] すれ違い時に相手のお気に入り曲が取得できる（Phase 4 に延期）
- [ ] LyricChain / LyricEntry のDBスキーマ設計完了（Day 4 準備）

---

## 依存関係図

```
Day 0 (3/14 午後)          Day 1 (3/15)              Day 2 (3/16)              Day 3 (3/17)
曽根+粉川                   全員                       全員                       曽根+三村
─────────────────────────────────────────────────────────────────────────────────────────

[iOS初期化] ──────────▶ [Sign in with Apple] ──▶ [BLE実装] ──────────▶ [すれ違い検知]
                              │                      │
[Backend初期化] ─────▶ [認証API] ─────────────▶ [BLE トークンAPI]        │
      │                       │                      │                      │
[docker-compose] ────▶ [ユーザーAPI] ────────▶ [Spotify連携] ─────────▶ [Encounter API]
                                                     │                      │
                                              [曲設定API] ───────────▶ [曲交換ロジック]
```

---

## 稼働時間まとめ

| 名前 | Day 0 | Day 1 | Day 2 | Day 3 | 合計 |
|---|---|---|---|---|---|
| 曽根 | 4h | 5.5h | 11h | 7h | **27.5h** |
| 粉川 | 4h | 12h | 12h | 0h | **28h** |
| 三村 | 0h | 10h+ | 4h | 4h | **18h+** |
| 河田 | 0h | 0h | 9h+ | 0h | **9h+** |

---

## リスクと対策

| リスク | 対策 |
|---|---|
| Day 3 に粉川・河田が不在 | Day 2 までに Backend API を完成させる |
| BLE バックグラウンド動作が不安定 | Day 2 に集中検証、河田が支援 |
| 三村の稼働が分散（朝・夜） | 粉川が Backend をカバー |
| Spotify API 制限 | 事前に開発用アカウントで確認 |

---

## MVP スコープ（時間が足りない場合）

**必須（絶対やる）**
- 認証（iOS）
- BLE すれ違い検知（iOS）
- 曲設定・曲交換

**優先度下げ可能**
- 位置情報すれ違い → Phase 4 以降に延期
- プレイリスト機能 → 曲交換のみに簡略化
- Android 実装 → 次フェーズで粉川が集中実装
