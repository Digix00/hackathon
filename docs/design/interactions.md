# インタラクション定義

## 概要

このドキュメントでは、アプリ全体のマイクロインタラクション、ジェスチャー、トランジションのタイミングを定義する。一貫した体験を提供するため、実装時はこの仕様に従う。

---

# 1. マイクロインタラクション

## 1.1 ボタン

### タップフィードバック

```
┌─────────────────────────────────────┐
│ 状態        │ 変化                  │
├─────────────────────────────────────┤
│ Default     │ scale: 1.0            │
│ Pressed     │ scale: 0.97           │
│ Released    │ scale: 1.0            │
└─────────────────────────────────────┘

タイミング:
- Press:   0ms（即時）
- Release: 100ms ease-out
```

### プライマリボタン

```
状態遷移:

[Default] ──tap──→ [Pressed] ──release──→ [Default]
                        │
                        ↓ (処理中)
                   [Loading]
                        │
                        ↓
              [Success] or [Error]

Loading状態:
- テキスト → スピナーに置換
- 背景色: 維持
- duration: 処理完了まで

Success状態（オプション）:
- スピナー → チェックマーク
- duration: 800ms → Default に戻る
```

### テキストボタン / アイコンボタン

```
Pressed:
- opacity: 0.6
- duration: 0ms（即時）

Released:
- opacity: 1.0
- duration: 150ms ease-out
```

---

## 1.2 いいねボタン

### アニメーションシーケンス

```
タップ時（未いいね → いいね）:

0ms     100ms    200ms    300ms    400ms
│        │        │        │        │
▽        ▽        ▽        ▽        ▽
♡ ────→ ♡ ────→ ♥ ────→ ♥ ────→ ♥
        scale    色変化   scale    scale
        0.8      赤系     1.3      1.0
                         + 粒子

粒子エフェクト:
- 6-8個の小さな円が放射状に飛散
- 色: いいね色の薄いバリエーション
- duration: 400ms
- 距離: 20-40pt
```

### 取り消し時

```
タップ時（いいね → 未いいね）:

0ms     150ms
│        │
▽        ▽
♥ ────→ ♡
scale    scale
0.9      1.0
色変化   完了

※ 粒子エフェクトなし（控えめに）
```

### ハプティクス

```
いいね時:   iOS: .impact(.light)
           Android: VibrationEffect.createOneShot(30, 100)

取り消し時: なし
```

---

## 1.3 トグルスイッチ

```
OFF → ON:

0ms          150ms        250ms
│             │            │
▽             ▽            ▽
[○────────]  [────○───]   [────────●]
             移動中        完了

- ノブ移動: 250ms spring(damping: 0.8)
- 背景色変化: 200ms ease-out
- ハプティクス: .impact(.light) at 0ms
```

---

## 1.4 プルトゥリフレッシュ

```
引っ張り中:

Pull距離    状態           表示
─────────────────────────────────────
0-60pt     pulling        矢印↓（回転なし）
60-80pt    threshold      矢印↑（180°回転）
80pt+      triggered      スピナーに変化

リリース後:
- < 60pt:  元に戻る（200ms ease-out）
- >= 60pt: リフレッシュ開始

リフレッシュ中:
- スピナー回転: 1000ms/回転, linear, infinite
- 位置: 上部に固定（60pt）

完了時:
- スピナー → チェックマーク（200ms）
- 300ms 表示後、上にスライドアウト（200ms）
```

---

## 1.5 テキスト入力

### フォーカス時

```
0ms                    200ms
│                       │
▽                       ▽
┌─────────────────┐    ┌─────────────────┐
│ placeholder     │ →  │                 │
└─────────────────┘    └─────────────────┘
border: Slate200       border: Accent
                       label 上に移動（あれば）

ラベルアニメーション:
- Y移動: 0 → -24pt
- scale: 1.0 → 0.85
- duration: 200ms ease-out
```

### 文字入力中

```
文字カウンター更新:
- 色変化なし（通常）
- 残り10文字: 色 → Yellow 600
- 残り0文字: 色 → Red 600
- 超過時: シェイクアニメーション（2回、50ms/回）
```

### エラー状態

```
エラー発生時:
- border: Red 500
- エラーテキスト: 下からフェードイン（150ms）
- シェイク: translateX ±4pt × 3回（200ms）
```

---

## 1.6 カード

### タップ可能カード

```
Pressed:
- scale: 0.98
- duration: 100ms ease-out

Released:
- scale: 1.0
- duration: 150ms ease-out
```

### スワイプ削除

```
スワイプ中:
- 背景に赤いアクション領域が見える
- ゴミ箱アイコン表示
- スワイプ量に応じてアイコンが拡大（max 1.2倍）

削除確定:
- カード: slideOut left（200ms）
- 高さ: collapse（200ms、slideOut後）
- 下のアイテム: 上に詰める（200ms）
```

---

## 1.7 通知バッジ

### 新規通知時

```
バッジ出現:
- scale: 0 → 1.2 → 1.0
- duration: 300ms spring

数字更新:
- 古い数字: fadeOut + slideUp（100ms）
- 新しい数字: fadeIn + slideUp（100ms）
```

---

## 1.8 ローディング

### スケルトンスクリーン

```
シマー効果:
- グラデーション移動: 左 → 右
- duration: 1500ms
- easing: linear
- repeat: infinite

グラデーション:
- ライト: #E2E8F0 → #F8FAFC → #E2E8F0
- ダーク: #334155 → #475569 → #334155
```

### スピナー

```
回転:
- duration: 1000ms/回転
- easing: linear
- repeat: infinite

色: Slate 500（ライト）/ Slate 400（ダーク）
サイズ: 20pt（小）/ 32pt（中）/ 48pt（大）
```

---

# 2. ジェスチャー

## 2.1 基本ジェスチャー

| ジェスチャー | 認識条件 | 用途 |
|---|---|---|
| タップ | < 200ms、移動 < 10pt | 選択、アクション |
| ロングプレス | >= 500ms | コンテキストメニュー |
| ダブルタップ | 2回タップ、間隔 < 300ms | いいね（詳細画面） |
| スワイプ | 移動 >= 50pt、速度 >= 100pt/s | ナビゲーション、削除 |
| ピンチ | 2本指、距離変化 | 画像ズーム（将来） |

---

## 2.2 画面別ジェスチャー

### ホーム画面

| ジェスチャー | 場所 | アクション |
|---|---|---|
| 下スワイプ | 画面上部 | プルトゥリフレッシュ |
| タップ | すれ違いカード | 詳細画面へ |
| ロングプレス | すれ違いカード | クイックアクション表示 |

### すれ違い詳細画面

| ジェスチャー | 場所 | アクション |
|---|---|---|
| ダブルタップ | アルバムアート | いいねトグル |
| 左エッジスワイプ | 画面左端 | 戻る |
| 下スワイプ | 画面上部（モーダル時） | 閉じる |

### すれ違い履歴一覧

| ジェスチャー | 場所 | アクション |
|---|---|---|
| 左スワイプ | リストアイテム | 削除/非表示 |
| 右スワイプ | リストアイテム | いいね |
| タップ | リストアイテム | 詳細画面へ |

### 設定画面

| ジェスチャー | 場所 | アクション |
|---|---|---|
| タップ | 設定項目 | 詳細/トグル |
| 左エッジスワイプ | 画面左端 | 戻る |

---

## 2.3 スワイプアクション詳細

### リストアイテムのスワイプ

```
左スワイプ（削除系）:

スワイプ量    状態              背景表示
───────────────────────────────────────────
0-60pt      preview          赤背景 + ゴミ箱
60-120pt    ready            アイコン拡大
120pt+      auto-trigger     自動実行

右スワイプ（ポジティブ系）:

スワイプ量    状態              背景表示
───────────────────────────────────────────
0-60pt      preview          緑/アクセント + ハート
60-120pt    ready            アイコン拡大
120pt+      auto-trigger     自動実行
```

### スワイプキャンセル

```
スワイプ中に反対方向へ:
- 60pt未満でリリース: 元の位置に戻る（200ms spring）
- velocity < 50pt/s でリリース: 元の位置に戻る
```

---

## 2.4 ロングプレスメニュー

### 表示アニメーション

```
0ms      100ms     200ms     300ms
│         │         │         │
▽         ▽         ▽         ▽
[press]  [scale]   [menu]    [complete]
         0.97      fadeIn
         blur bg   slideUp

メニュー出現:
- scale: 0.9 → 1.0
- opacity: 0 → 1
- Y: +10pt → 0
- duration: 200ms spring

背景:
- blur: 0 → 10pt
- overlay: rgba(0,0,0,0) → rgba(0,0,0,0.3)
- duration: 200ms
```

### メニュー項目

```
項目タップ:
- 背景ハイライト: 即時
- メニュー全体: scale 0.95 → fadeOut（150ms）
- アクション実行: メニュー消失後
```

---

## 2.5 エッジスワイプ（戻る）

```
iOS:
- 認識範囲: 画面左端 0-20pt
- 閾値: 画面幅の50%、または velocity > 500pt/s
- アニメーション: インタラクティブ（指に追従）

Android:
- システムの戻るジェスチャーに準拠
- 予測的バックアニメーション対応
```

---

# 3. トランジション・タイミング

## 3.1 画面遷移

### Push（進む）

```
新画面:
- 開始位置: X = 画面幅100%
- 終了位置: X = 0
- duration: 350ms
- easing: ease-out（iOS）/ FastOutSlowIn（Android）

現画面:
- 開始位置: X = 0
- 終了位置: X = -30%（視差効果）
- duration: 350ms
- opacity: 1.0 → 0.8（オプション）
```

### Pop（戻る）

```
現画面:
- 開始位置: X = 0
- 終了位置: X = 画面幅100%
- duration: 300ms
- easing: ease-in-out

前画面:
- 開始位置: X = -30%
- 終了位置: X = 0
- duration: 300ms
```

### モーダル（Present）

```
モーダル:
- 開始位置: Y = 画面高さ100%
- 終了位置: Y = 0（または上部マージン）
- duration: 400ms
- easing: spring(damping: 0.85)

背景オーバーレイ:
- opacity: 0 → 0.5
- duration: 300ms
```

### モーダル（Dismiss）

```
モーダル:
- 開始位置: Y = 現在位置
- 終了位置: Y = 画面高さ100%
- duration: 300ms
- easing: ease-in

背景オーバーレイ:
- opacity: 0.5 → 0
- duration: 250ms
```

---

## 3.2 シェアドエレメントトランジション

### すれ違いカード → 詳細画面

```
アルバムアート:
- サイズ: 48pt → 200pt
- 位置: リスト内 → 画面中央上部
- 角丸: 6pt → 16pt
- duration: 400ms
- easing: spring(damping: 0.8)

その他要素:
- フェードイン: 遅延100ms、duration 200ms
```

### 詳細画面 → 戻る

```
アルバムアート:
- サイズ: 200pt → 48pt
- 位置: 画面中央 → リスト内元位置
- duration: 350ms

その他要素:
- フェードアウト: duration 150ms（先行）
```

---

## 3.3 コンポーネント別トランジション

### トースト通知

```
表示:
- 開始: Y = -100%, opacity = 0
- 終了: Y = 0, opacity = 1
- duration: 300ms spring
- 自動非表示: 3000ms後

非表示:
- Y: 0 → -100%
- opacity: 1 → 0
- duration: 250ms ease-in
```

### ボトムシート

```
表示:
- Y: 100% → 0（または途中位置）
- duration: 400ms spring(damping: 0.9)
- 背景overlay: 0 → 0.5（300ms）

ドラッグ中:
- 指に追従（インタラクティブ）
- 下方向にスナップポイント設定

非表示:
- velocity > 500pt/s down: 即閉じ
- 中間位置でリリース: 近いスナップポイントへ
```

### ダイアログ

```
表示:
- scale: 0.9 → 1.0
- opacity: 0 → 1
- duration: 250ms spring
- 背景overlay: 0 → 0.6（200ms）

非表示:
- scale: 1.0 → 0.95
- opacity: 1 → 0
- duration: 200ms ease-out
```

### ドロップダウン/ピッカー

```
展開:
- height: 0 → auto
- opacity: 0 → 1
- duration: 250ms ease-out

折りたたみ:
- height: auto → 0
- opacity: 1 → 0
- duration: 200ms ease-in
```

---

## 3.4 リストアニメーション

### アイテム追加（上部に挿入）

```
新アイテム:
- 開始: height = 0, opacity = 0
- 終了: height = auto, opacity = 1
- duration: 300ms ease-out

既存アイテム:
- Y: 0 → +itemHeight
- duration: 300ms ease-out
- stagger: 30ms（下のアイテムほど遅延）
```

### アイテム削除

```
削除アイテム:
- height: auto → 0
- opacity: 1 → 0
- X: 0 → -100%（スワイプ削除の場合）
- duration: 250ms ease-in

下のアイテム:
- Y: 0 → -deletedHeight
- duration: 250ms ease-out
- 開始: 削除アニメーション50%時点
```

### 初回ロード

```
各アイテム:
- 開始: opacity = 0, Y = +20pt
- 終了: opacity = 1, Y = 0
- duration: 300ms ease-out
- stagger: 50ms（上から順に）
- 最大stagger: 5アイテムまで（それ以降は同時）
```

---

## 3.5 状態変化

### ローディング → コンテンツ

```
スケルトン:
- opacity: 1 → 0
- duration: 200ms

コンテンツ:
- opacity: 0 → 1
- duration: 300ms
- 開始: スケルトン消失後50ms
```

### エラー → リトライ

```
エラー表示:
- opacity: 1 → 0
- duration: 150ms

ローディング:
- opacity: 0 → 1
- duration: 150ms
```

### 空状態 → コンテンツあり

```
空状態イラスト:
- scale: 1.0 → 0.9
- opacity: 1 → 0
- duration: 200ms

コンテンツ:
- opacity: 0 → 1
- Y: +20pt → 0
- duration: 300ms
- 開始: 空状態消失後
```

---

# 4. ハプティクスガイドライン

## 4.1 iOS

| 用途 | フィードバック |
|---|---|
| ボタンタップ | `.impact(.light)` |
| 重要なアクション | `.impact(.medium)` |
| 成功 | `.notificationOccurred(.success)` |
| エラー | `.notificationOccurred(.error)` |
| 警告 | `.notificationOccurred(.warning)` |
| 選択変更 | `.selectionChanged()` |
| すれ違い成立 | `.impact(.medium)` + `.impact(.light)` |

## 4.2 Android

| 用途 | フィードバック |
|---|---|
| ボタンタップ | `HapticFeedbackConstants.VIRTUAL_KEY` |
| 重要なアクション | `VibrationEffect.createOneShot(50, 180)` |
| 成功 | `VibrationEffect.createOneShot(30, 100)` |
| エラー | `VibrationEffect.createWaveform([0,50,50,50], -1)` |
| 選択変更 | `HapticFeedbackConstants.CLOCK_TICK` |
| すれ違い成立 | `VibrationEffect.createWaveform([0,50,30,50], -1)` |

---

# 5. パフォーマンス指針

## 5.1 アニメーション

- **60fps維持**: transform, opacity のみアニメーション
- **GPU活用**: `will-change` / `layer` ヒント
- **メインスレッド**: レイアウト計算をアニメーション中に行わない

## 5.2 ジェスチャー

- **キャンセル可能**: すべてのジェスチャーは途中キャンセル対応
- **インタラクティブ**: ドラッグ系は指に追従（フレーム遅延なし）
- **優先度**: 競合時は意図的なジェスチャーを優先

## 5.3 省電力

- **アニメーション停止**: バックグラウンド時
- **簡易モード**: 低電力モード時はアニメーション簡略化
- **リデュースモーション**: 設定に応じてフェードのみに
