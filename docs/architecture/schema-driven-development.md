# スキーマ駆動開発

## 合意済み

- REST (JSON) を採用する
- 破壊的変更は CI でブロックする（`oasdiff breaking` を将来導入予定）

### 現在の実装方針（ハックハソン暫定）

Design-first への移行は将来的な目標とし、ハックハソン期間中はスピード優先で **Code-first（swag）** を採用する。

| 項目 | 採用方針 |
|---|---|
| スキーマ生成 | `swag init`（Go コードのアノテーションから Swagger 2.0 を自動生成） |
| Swagger UI | `GET /swagger/*`（development / test 環境のみ公開） |
| Android クライアント | `openapi-generator -g kotlin --library jvm-retrofit2` |
| iOS クライアント | `openapi-generator -g swift5`（`--additional-properties=responseAs=AsyncAwait`） |

生成コマンド: `make generate-code`（`backend/` または リポジトリルートから実行可能）

### 将来的な移行目標（Design-first）

| プラットフォーム | 移行後ツール |
|---|---|
| Go | `oapi-codegen`（Echo と相性が良い） |
| Swift | `swift-openapi-generator`（Apple 公式、SPM プラグイン） |
| Kotlin | `openapi-generator`（`kotlin` ターゲット） |

---

## 未決定

### 1. スキーマ編集ツール

手書き（YAML直書き）か、GUI補助ツールを使うか。

| 候補 | OSS | 概要 |
|---|---|---|
| VSCode + OpenAPI (Swagger) Editor 拡張 | ✅ | エディタ内でバリデーション・プレビュー。追加セットアップ不要 |
| Swagger Editor（Docker）| ✅ | ブラウザ GUI。docker-compose に追加するだけ |
| Stoplight Studio | ❌（商用） | GUI が洗練されているがクラウド機能は有料 |

### 2. スキーマファイルの置き場所

どのリポジトリで管理するか。

| 候補 | 概要 | トレードオフ |
|---|---|---|
| バックエンドリポジトリ（`schema/`） | Go 実装と同じ場所で管理 | モバイル側が参照しにくい |
| 専用スキーマリポジトリ | 3チームが対等に参照できる | リポジトリが増える・CI 連携が複雑になる |
| このドキュメントリポジトリ（`docs/`） | 設計書と同じ場所で管理 | 実装リポジトリの CI と分離する必要がある |

### 3. 生成コードの扱い

生成コードをリポジトリにコミットするか、CI でオンザフライ生成するか。

| 候補 | 概要 | トレードオフ |
|---|---|---|
| コミットする | 差分で変更内容を可視化できる | 生成コードが PR に混入する |
| CI でオンザフライ生成 | リポジトリがクリーン | 生成失敗時の原因追跡が難しい |

### 4. モバイルへのスキーマ配布方法

スキーマ変更時に iOS・Android リポジトリへどう伝えるか。

| 候補 | 概要 | トレードオフ |
|---|---|---|
| CI が各リポジトリに自動 PR 作成 | 変更を担当者がレビューできる | CI 設定が複雑になる |
| Git submodule | スキーマの参照を同期できる | submodule 管理のオーバーヘッド |
| 手動コピー | シンプル | 同期漏れリスクが高い |
