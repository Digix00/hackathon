# ホーム画面 UI設計

## 概要

アプリのメイン画面。**2つのサーフェス構造**を採用し、上下スワイプで「Track Surface（シェア中の曲表示）」と「Library Surface（すれ違い情報・履歴）」を切り替える。没入感のある体験を提供する。

---

## 画面構成（2サーフェス構造）

### Track Surface（上面）

```
┌─────────────────────────────┐
│░░░░░░░░░░░░░░░░░░░░░░░░░░░░░│  ← ダイナミックブラー背景
│░                           ░│
│░ 35.6812° N, 139.7671° E  ░│  ← 位置情報
│░ TOKYO / SHIBUYA          ░│
│░                           ░│
│░          ● BEACON ACTIVE ░│  ← ステータス（パルスアニメーション）
│░                           ░│
│░                           ░│
│░      ┌─────────────┐      ░│
│░      │             │      ░│
│░      │             │      ░│
│░      │  ジャケット  │      ░│  ← ヒーロー表示（240pt）
│░      │             │      ░│  パルスアニメーション
│░      │             │      ░│  グロー効果
│░      └─────────────┘      ░│
│░                           ░│
│░   CURRENTLY SHARING       ░│
│░                           ░│
│░         曲名              ░│  ← 38pt Bold
│░      アーティスト名        ░│  ← 22pt Medium
│░                           ░│
│░                           ░│
│░   SWIPE UP FOR INSIGHTS   ░│  ← スワイプヒント
│░         ━━━━              ░│
│░░░░░░░░░░░░░░░░░░░░░░░░░░░░░│
└─────────────────────────────┘
```

### Library Surface（下面）

```
┌─────────────────────────────┐
│  すれ違いの情報              │  ← タブコンテンツエリア
│                             │
│  ┌───────────────────────┐  │
│  │ 今週出会った音楽        │  │
│  │ ┌──┐┌──┐┌──┐┌──┐    │  │
│  │ └──┘└──┘└──┘└──┘    │  │
│  └───────────────────────┘  │
│                             │
│  すれ違い                    │
│  ┌─────────┐ ┌─────────┐   │
│  │  今日   │ │ 今週    │   │
│  │   12    │ │   47    │   │
│  │   人    │ │   人    │   │
│  └─────────┘ └─────────┘   │
│                             │
│  最近の出会い                │
│  ┌───────────────────────┐  │
│  │ 🎵 曲名    ユーザー名  │  │
│  └───────────────────────┘  │
│                             │
├─────────────────────────────┤
│ ┌────┐┌────┐┌────┐┌────┐  │  ← Library Footer
│ │ ⚡ ││ 🕐 ││ 🎵 ││ 👤 │  │  4つのタブ
│ │情報││履歴││生成││設定│  │
│ └────┘└────┘└────┘└────┘  │
└─────────────────────────────┘
```

---

## サーフェス構造

### サーフェス切り替え

**インタラクション**:
- 上スワイプ（Track → Library）: しきい値 90pt
- 下スワイプ（Library → Track）: しきい値 90pt
- ドラッグ中: 0.9倍の減衰効果
- アニメーション: Spring (response: 0.34, damping: 0.86)

**ページインジケーター（Track Surface のみ表示）**:
```
右端に縦型インジケーター:
- 全長: 100pt
- アクティブ部分: 40pt、Accent カラー
- 非アクティブ: Border カラー 35%透明度
- 幅: 3pt Capsule
```

---

## Track Surface 詳細

### 1. ダイナミックブラー背景

**目的**: アルバムアートの世界観で画面全体を包み込む

**背景レイヤー構成**:
```
1. Base: PrototypeTheme.background
2. Blob 1: ジャケットカラー 35%透明度、450pt、blur 90pt
3. Blob 2: Accent カラー 12%透明度、380pt、blur 100pt
4. Blob 3: ジャケットカラー 20%透明度、320pt、blur 80pt
```

**アニメーション**:
- 各Blobが異なる軌道でゆっくり移動
- duration: 5秒、repeatForever, autoreverses
- easeInOut

### 2. 位置情報・ステータス表示

**位置情報**:
```
フォント: 10pt Bold、Data役割
色: テキストセカンダリ 60%透明度
テキスト例: "35.6812° N, 139.7671° E"

エリア名:
フォント: 10pt Black、Kerning 1.5
色: テキストセカンダリ 40%透明度
テキスト例: "TOKYO / SHIBUYA"
```

**BEACON ACTIVE ステータス**:
```
背景: Surface カラー 40%透明度、Capsule
パディング: 横12pt、縦6pt

構成:
- パルスドット（6pt Circle、Accent カラー）
- パルスリング（2pt stroke、2.5倍にスケール、フェードアウト）
- テキスト "BEACON ACTIVE"（10pt Black、Kerning 1.2）

アニメーション:
  duration: 2秒、easeOut、repeatForever
```

### 3. ヒーロー表示（アルバムアート）

**目的**: 没入感のある大型ヒーロー表示で、シェア中の曲を体験させる

**アルバムアート**:
```
サイズ: 240pt × 240pt（大型）
角丸: なし（円形マスク）
シャドウ: ジャケットカラー 20%透明度、radius 30pt
中央配置
```

**グロー・パルス演出**:
```
背景グロー（3層構造）:
- 内側リング: ジャケットカラー 15%、340pt、blur 20-32pt（パルス）
- 外側リング: ジャケットカラー 10%、300pt、1pt stroke（パルス）
- アートワーク: MockArtworkView 240pt

パルスアニメーション:
- グロー: scale 1.0 → 1.15、duration 2.5秒、repeatForever
- リング: scale 0.95 → 1.05、duration 3秒、repeatForever
- easeInOut
```

**テキスト表示**:
```
ラベル "CURRENTLY SHARING":
  フォント: 11pt Black、Kerning 1.5
  色: ジャケットカラー 70%透明度

曲名:
  フォント: 38pt Black、Tracking -1.0
  色: テキストプライマリ
  制限: 2行
  配置: 中央

アーティスト名:
  フォント: 22pt Medium
  色: テキストセカンダリ
  配置: 中央
```

**曲未設定時**:
```
┌─────────────────────────────────┐
│                                 │
│       ┌─────────────┐           │
│       │             │           │
│       │     +       │           │  ← 140pt Circle
│       │     🎵      │           │  Surface Muted背景
│       │             │           │  40pt アイコン
│       └─────────────┘           │
│                                 │
│      SET YOUR TRACK             │
│  (14pt Black、Kerning 1.2)      │
│                                 │
└─────────────────────────────────┘

タップ → SearchView へ遷移
```

### 4. スワイプヒント

**レイアウト**:
```
テキスト: "SWIPE UP FOR INSIGHTS"
  フォント: 10pt Black、Kerning 2.0
  色: テキストセカンダリ 50%透明度

インジケーター:
  40pt × 4pt Capsule
  色: Border 60%透明度

マージン: 下12pt
```

---

## Library Surface 詳細

### 1. タブ構成

Library Surfaceは4つのタブで構成される:

| タブ | アイコン | タイトル | 内容 |
|---|---|---|---|
| Insights | dot.radiowaves.left.and.right | すれ違い情報 | HomeInsightsPage |
| History | clock.arrow.circlepath | 履歴 | EncounterListView |
| Songs | waveform | 生成曲 | GeneratedSongsView |
| Profile | person.crop.circle | プロフィール | SettingsHubView |

### 2. Library Footer（カスタムタブバー）

**レイアウト**:
```
┌────────────────────────────────────┐
│ ┌────┐ ┌────┐ ┌────┐ ┌────┐     │
│ │ ⚡ │ │ 🕐 │ │ 🎵 │ │ 👤 │     │
│ │情報│ │履歴│ │生成│ │設定│     │
│ └────┘ └────┘ └────┘ └────┘     │
└────────────────────────────────────┘

背景: .ultraThinMaterial
上部ボーダー: Border 60%透明度、1pt
```

**タブボタンスタイル**:
```
サイズ: maxWidth × 56pt
角丸: 18pt、continuous
アイコン: 15pt Semibold
ラベル: 11pt Semibold、lineLimit 1

アクティブ:
  背景: テキストプライマリ
  テキスト: 白

非アクティブ:
  背景: 透明
  テキスト: テキストセカンダリ

パディング:
  横: 12pt
  上: 10pt
  下: 18pt（Safe Area含む）

アニメーション: easeInOut 0.2秒
```

### 3. Insightsタブ（すれ違い情報）

**目的**: すれ違いの統計と最近の出会いを表示

**セクション構成**:

#### すれ違いの情報

**目的**: ジャケットを並べて「音楽との出会いの軌跡」を視覚的に表現

**レイアウト**:
```
SectionCard:
  ┌─────────────────────────────┐
  │ SectionHeader:              │
  │ 今週出会った音楽    すべて→ │
  │                             │
  │ ┌──┐┌──┐┌──┐┌──┐          │
  │ │  ││  ││  ││  │          │  ← 各 56pt × 56pt
  │ └──┘└──┘└──┘└──┘          │     4列グリッド
  │ ┌──┐┌──┐┌──┐┌────┐        │
  │ │  ││  ││  ││+12 │        │  ← 8枚目以降は「+N」
  │ └──┘└──┘└──┘└────┘        │
  └─────────────────────────────┘
```

**グリッド仕様**:
```
LazyVGrid:
  columns: 4列、各56pt固定
  spacing: 8pt
  alignment: .leading

アイテム:
  サイズ: 56pt × 56pt
  角丸: 8pt、continuous

最大表示: 7枚 + 「+N」バッジ
```

**「+N」バッジ**:
```
背景: Surface Elevated
テキスト: 15pt Semibold、テキストセカンダリ
サイズ: 56pt × 56pt
角丸: 8pt
```

**インタラクション**:
- 各ジャケットタップ → NavigationLink で EncounterListView へ
- 「すべて→」タップ → NavigationLink で EncounterListView へ

**空状態**:
- weeklyTracks が空の場合、セクション全体を非表示

---

#### すれ違いサマリ

**目的**: 今日と今週の数値を並べて表示

**レイアウト**:
```
VStack(alignment: .leading):
  Text("すれ違い")  // sectionTitle

  HStack(spacing: 14):
    SummaryMetricCard(今日)
    SummaryMetricCard(今週)
```

**SummaryMetricCard スタイル**:
```
背景: Surface Elevated
角丸: 14pt、continuous
パディング: 16pt
幅: maxWidth

構成:
  タイトル: 14pt Medium、テキストセカンダリ
  数値: 32pt Bold、テキストプライマリ
  単位: 13pt、テキストセカンダリ
  補足: 12pt、テキストセカンダリ（0の時のみ）

ゼロ状態:
  "まだありません"を表示
```

**アクセシビリティ**:
- `.accessibilityLabel("{タイトル}のすれ違い、{count}人")`

---

#### 最近の出会いリスト

**目的**: 直近のすれ違いをクイックアクセス

**レイアウト**:
```
SectionCard:
  ┌─────────────────────────────┐
  │ SectionHeader:              │
  │ 最近の出会い        すべて→ │
  │                             │
  │ VStack(spacing: 12):        │
  │ ┌───────────────────────┐   │
  │ │ EncounterRow          │   │
  │ └───────────────────────┘   │
  │ ┌───────────────────────┐   │
  │ │ EncounterRow          │   │
  │ └───────────────────────┘   │
  └─────────────────────────────┘
```

**EncounterRow スタイル**:
```
背景: Surface Elevated
角丸: 16pt
パディング: 14pt

レイアウト:
  HStack(spacing: 14):
    MockArtworkView: 48pt × 48pt
    VStack(alignment: .leading):
      曲名: cardTitle
      アーティスト: body、テキストセカンダリ
    Spacer
    VStack(alignment: .trailing):
      ユーザー名: meta、テキストプライマリ
      相対時間: metaCompact、テキストターシャリ
```

**Typography**（PrototypeTheme.Typography.Encounter）:
```
cardTitle: 15pt Semibold
body: 13pt Regular
meta: 13pt Regular
metaCompact: 13pt Regular
```

**表示件数**: 最大 5 件（`recentEncounters.prefix(5)`）

**空状態**:
```
FirstEncounterEmptyState:
  EmptyStateCard(
    icon: "figure.walk",
    title: "まだすれ違いがありません",
    message: "新しい出会いを待っています",
    tint: PrototypeTheme.info
  )
```

**インタラクション**:
- 各アイテムタップ → NavigationLink で EncounterDetailView へ
- 「すべて→」タップ → NavigationLink で EncounterListView へ

### 4. オフラインバナー

**表示条件**: `homeState.isOffline == true`

**レイアウト**:
```
HStack:
  Image(systemName: "wifi.exclamationmark")
    色: Warning
  Text("オフラインです")
    フォント: 14pt Medium
  Spacer

背景: Surface Muted
角丸: 14pt、continuous
パディング: 横14pt、縦12pt
```

**配置**: Insights タブの最上部

---

### 5. スクロールジェスチャー

**下スワイプで Track Surface へ戻る**:
```
DragGesture(minimumDistance: 20):
  条件: translation.height > 80pt
  アクション: selectedPage = 0（Hero）に切り替え
  アニメーション: easeInOut 0.25秒
```

---

## インタラクション

### サーフェス切り替え（上下スワイプ）

**Track → Library（上スワイプ）**:
```
条件: translation.height < -90pt かつ abs(vertical) > abs(horizontal)
アクション: selectedSurface = .library
アニメーション: Spring (response: 0.34, damping: 0.86)
```

**Library → Track（下スワイプ）**:
```
条件: translation.height > 90pt かつ abs(vertical) > abs(horizontal)
アクション: selectedSurface = .track
アニメーション: 同上
```

**ドラッグ中の追従**:
```
verticalDragOffset を .updating で管理
表示オフセット: dragOffset * 0.9（減衰効果）
```

### ヒーローカードタップ
- NavigationLink で SearchView へ遷移
- タップエリア: ヒーローカード全体

### Libraryタブ切り替え
- タブボタンタップで即座に切り替え
- TabView の .page スタイルで横スワイプも可能
- アニメーション: easeInOut 0.2秒

---

## 状態パターン

### 初回利用（すれ違いゼロ）

**Track Surface**:
- 曲が設定されている場合: 通常のヒーロー表示
- 曲が未設定の場合: "SET YOUR TRACK" プレースホルダー

**Library Surface（Insights タブ）**:
```
- weeklyTracks セクション: 非表示
- すれ違いサマリ: 0人 + "まだありません"
- 最近の出会い: FirstEncounterEmptyState 表示
  EmptyStateCard(
    icon: "figure.walk",
    title: "まだすれ違いがありません",
    message: "新しい出会いを待っています",
    tint: PrototypeTheme.info
  )
```

### 曲未設定
```
Track Surface に表示:
  ┌─────────────────┐
  │                 │
  │      +          │  ← 140pt Circle
  │      🎵         │  Surface Muted背景
  │                 │
  └─────────────────┘
   SET YOUR TRACK
   (14pt Black、Kerning 1.2)

タップ → SearchView へ遷移
```

### オフライン
```
Library Surface（Insights タブ）の最上部に表示:

OfflineBannerView:
┌─────────────────────────────┐
│ ⚠️ オフラインです            │
│ (wifi.exclamationmark)      │
│ 14pt Medium                 │
└─────────────────────────────┘

背景: Surface Muted
角丸: 14pt、continuous
パディング: 横14pt、縦12pt

- キャッシュされたデータを表示
- 新規データ取得は不可
```

---

## テーマとカラー

**PrototypeTheme を使用**:
```swift
// 基本カラー
background: ライトモード優先のモノトーン背景
surface: カード背景
surfaceElevated: 強調されたカード背景
surfaceMuted: ミュートされた背景

// テキスト
textPrimary: 主要テキスト
textSecondary: 副次テキスト
textTertiary: 三次テキスト

// アクセント
accent: アクセントカラー
border: ボーダーカラー

// セマンティック
success: 成功カラー
warning: 警告カラー
error: エラーカラー
info: 情報カラー
```

**ダイナミックカラー**:
- アルバムアートから抽出したドミナントカラーを使用
- グロー、パルス、背景ブラーに適用

---

## アクセシビリティ

### VoiceOver/TalkBack

**Track Surface**:
- ヒーローカード: 「曲名、アーティスト名、シェア中」
- BEACON ACTIVE: 「ビーコン有効」
- 位置情報: 読み上げスキップ（decorative）

**Library Surface（Insights タブ）**:
- すれ違いカード: `.accessibilityLabel("今日のすれ違い、12人")`
- EncounterRow: 「曲名、アーティスト名、ユーザー名さんと3分前にすれ違い」

### ダイナミックタイプ
- システムフォントスケーリングに対応
- 最大200%まで対応
- テキストレイアウトは自動調整

### タッチターゲット
- タブボタン: 最小 56pt × 56pt
- EncounterRow: 最小 48pt height
- ヒーローカード: 大型タップエリア
