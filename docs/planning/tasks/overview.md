# 実装タスク一覧

すれ違い趣味交換アプリの実装タスクを適切な粒度で分解したドキュメント。

## スケジュール・シフト

- [発表に向けた全体スケジュール（3/14〜3/21）](./schedule/schedule-full.md) ← メイン
- [Phase 1-3 詳細スケジュール（3/14〜3/17）](./schedule/schedule-3days.md)
- [メンバーシフト表](./member-shifts.md)

## フェーズ構成

| フェーズ | 概要 | 担当 |
|---|---|---|
| [Phase 1](./phases/phase1-infrastructure.md) | インフラ・認証基盤 | Backend, Infra |
| [Phase 2](./phases/phase2-ble-track.md) | BLE機能・曲設定 | iOS, Android, Backend |
| [Phase 3](./phases/phase3-encounter.md) | すれ違い交換機能 | iOS, Android, Backend |
| [Phase 4](./phases/phase4-ux.md) | ユーザー体験向上 | iOS, Android, Backend |
| [Phase 5](./phases/phase5-post-poc.md) | PoC後機能 | 全チーム |

## 優先順位（issues.md準拠）

### MVP（PoC前）

1. ログを取る
2. BLE機能
3. 曲設定
4. 曲交換（外部APIとの接続）
5. プロフィール（ログイン・ログアウト・アカウント削除）
6. 位置情報
7. プレイリスト交換
8. オンボーディング
9. いいね
10. コメント
11. 通報

### PoC後

12. 通知機能
13. 通知バッチにすれ違った数を表示
14. レート制限
15. タグ
16. 短命トークン
17. オフライン対応
18. ログ解析

## 担当者

| 領域 | 担当 |
|---|---|
| iOS (Swift) | 曽根 |
| Android (Kotlin) | 粉川 |
| Backend (Go) | 三村 |
| リベロ | 河田 |

## タスクステータス凡例

- `[ ]` : 未着手
- `[x]` : 完了
- `[-]` : 対応不要 / スキップ
