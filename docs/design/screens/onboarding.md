# オンボーディング画面 UI設計

## 概要

初回起動時のユーザー体験を設計。**3ステップ以内**で初期設定を完了させ、すぐにアプリ体験を開始できるようにする。

---

## フロー構成（実装版）

```
[Welcome] → [Identity] → [Presence] → [Ready]
```

**計4ステップ**。シンプルなプログレスインジケーターで進行状況を明示。

### 実装の特徴

| 特徴 | 詳細 |
|---|---|
| 4ステップ構成 | Welcome, Identity, Presence, Ready |
| プログレスインジケーター | 4つのCapsule、アクティブが強調 |
| タイトル/サブタイトル | 各ステップで異なるメッセージ |
| 会話型UI | 共感的なマイクロコピー |
| 前へ/次へボタン | ステップ1-2で戻るボタン表示 |

---

## プログレスインジケーター

**デザイン**:
```
HStack(spacing: 10):
  ForEach(0..<4):
    Capsule()
      .fill(index == step ? テキストプライマリ : Border)
      .frame(
        width: index == step ? 32 : 12,
        height: 6
      )

配置: 最上部、左揃え
マージン: 下部に適切なスペース
```

**ステップ表示**:
```
ステップ0: [●●●○] (32, 12, 12, 12)
ステップ1: [○●●○] (12, 32, 12, 12)
ステップ2: [○○●○] (12, 12, 32, 12)
ステップ3: [○○○●] (12, 12, 12, 32)
```

---

## 画面詳細

### Step 0: Welcome

**タイトル**: "Hello World."
**サブタイトル**: "A NEW WAY TO CONNECT"

**目的**: アプリの価値を伝え、期待感を醸成

**レイアウト**:
```
VStack(spacing: 24):
  ZStack:
    Circle(stroke, 200pt)      // Border
    Circle(stroke, 260pt)      // Border 50%
    Image(waveform, 64pt)      // Accent カラー

  VStack(alignment: .leading, spacing: 16):
    Text("URBAN SERENDIPITY")
      // 12pt Black、Accent、Kerning 2.0

    Text("すれ違う、\n音楽で繋がる。")
      // 32pt Black、行間4pt

    Text("街を歩くだけで、誰かの「今の気分」と出会える。新しい音楽体験を始めましょう。")
      // 16pt Medium、テキストセカンダリ、行間6pt

パディング: 横8pt
```

**ビジュアル要素**:
- 同心円のボーダー（200pt、260pt）
- 中央にwaveformアイコン（64pt、Accent カラー）
- パディング: 縦20pt

**ボタン**:
- 次へボタン（CONTINUE）のみ
- 認証は実装されていない（プロトタイプ）

---

### Step 1: Identity

**タイトル**: "Identity"
**サブタイトル**: "HOW OTHERS WILL SEE YOU"

**目的**: プロフィールとシェアする曲を設定

**レイアウト**:
```
SectionCard(title: "YOUR PROFILE"):
  VStack(alignment: .leading, spacing: 20):
    HStack(spacing: 20):
      ZStack:
        Circle(Surface Elevated, 80pt)
        Image(person.fill, 32pt)
      VStack(alignment: .leading):
        Text("NICKNAME")  // 10pt Black、セカンダリ
        Text("miyu")      // 20pt Bold、プライマリ

    Divider

    VStack(alignment: .leading, spacing: 12):
      Text("SHARING TRACK")  // 10pt Black、セカンダリ

      HStack:
        MockArtworkView(52pt)
        VStack(alignment: .leading):
          Text("夜に駆ける")      // 16pt Bold
          Text("YOASOBI")       // 14pt、セカンダリ
        Spacer
        Image(pencil)

      背景: Surface Elevated 50%
      角丸: 14pt
      パディング: 12pt

Text("この情報はすれ違った相手にのみ公開されます。")
  // 13pt、テキストターシャリ、中央揃え
```

**特徴**:
- SectionCard内に統合されたプロフィール表示
- ニックネームとシェア曲が1画面に
- モックデータを使用（実際の入力機能はプロトタイプでは未実装）

---

### Step 2: Presence

**タイトル**: "Presence"
**サブタイトル**: "SETTING UP THE BEACON"

**目的**: 必要な権限をまとめて説明・取得

**レイアウト**:
```
VStack(alignment: .leading, spacing: 16):
  PermissionRow(
    icon: "location.fill",
    title: "Location Services",
    description: "近くの人を見つけるために使用します。"
  )

  PermissionRow(
    icon: "dot.radiowaves.left.and.right",
    title: "Bluetooth",
    description: "BLE信号で安全にすれ違いを検知します。"
  )

  PermissionRow(
    icon: "bell.fill",
    title: "Notifications",
    description: "新しい出会いや曲の生成をお知らせします。"
  )

GlassmorphicCard:
  HStack:
    Image(shield.fill)  // Success カラー
    Text("プライバシーは保護されており、正確な現在地が共有されることはありません。")
      // 12pt Medium、テキストセカンダリ
```

**PermissionRow スタイル**:
```
HStack(alignment: .top, spacing: 12):
  Image(icon)         // 18pt、Accent
  VStack(alignment: .leading):
    Text(title)       // 16pt Semibold
    Text(description) // 14pt、テキストセカンダリ
  Spacer
  Image(checkmark.circle.fill)  // Success

背景: Surface Muted
角丸: 14pt
パディング: 12pt
```

**特徴**:
- 3つの権限を説明のみ（実際の権限リクエストは未実装）
- チェックマークは常に表示（プロトタイプ）
- プライバシー説明カードで安心感を提供

---

### Step 3: Ready

**タイトル**: "Ready."
**サブタイトル**: "EVERYTHING IS SET"

**目的**: 設定完了を祝福し、すぐに体験開始

**レイアウト**:
```
VStack(spacing: 32):
  ZStack:
    Circle(Success 10%, 140pt)
    Image(checkmark.seal.fill, 64pt)
      // Success カラー

  パディング上: 40pt

  VStack(spacing: 12):
    Text("READY TO EXPLORE")
      // 14pt Black、Success、Kerning 1.5

    Text("準備が完了しました")
      // 28pt Black

    Text("iPhoneを持って街に出かけましょう。\n誰かの音楽があなたを待っています。")
      // 16pt Medium、テキストセカンダリ
      // 中央揃え、行間6pt
```

**ボタン**:
- ラベル: "BEGIN JOURNEY"
- タップ → onFinish() → メインアプリへ遷移

**演出**（実装予定）:
- チェックマークアイコンのスケールアニメーション
- Successカラーでポジティブな印象

---

## ナビゲーションとボタン

### AppScaffold レイアウト

**構成**:
```swift
AppScaffold(
  title: stepTitle,
  subtitle: stepSubtitle
) {
  // コンテンツ
}
```

**タイトル/サブタイトル**:
| ステップ | タイトル | サブタイトル |
|---|---|---|
| 0 | Hello World. | A NEW WAY TO CONNECT |
| 1 | Identity | HOW OTHERS WILL SEE YOU |
| 2 | Presence | SETTING UP THE BEACON |
| 3 | Ready. | EVERYTHING IS SET |

### ボタン配置

**レイアウト**:
```
HStack(spacing: 16):
  if step > 0 && step < 3:
    Button(戻る):             // 左、56pt Circle
      Image(arrow.left)
      背景: Surface Muted

  PrimaryButton(
    title: step == 3 ? "BEGIN JOURNEY" : "CONTINUE"
  )
  // 右、拡張
```

**ステップ別表示**:
- ステップ0: CONTINUE のみ
- ステップ1-2: 戻る + CONTINUE
- ステップ3: CONTINUE のみ（"BEGIN JOURNEY"）

---

## 実装の注意点（プロトタイプ）

**現在の実装**:
- 実際の認証機能は未実装（プロトタイプ）
- プロフィール入力フィールドは未実装（モックデータ表示のみ）
- 権限リクエストは未実装（説明のみ）
- ステップは常に進行可能

**プロトタイプで表示されるもの**:
- 4ステップのフロー構造
- UIコンポーネントとレイアウト
- プログレスインジケーター
- ナビゲーション（戻る/次へ）

**将来の実装予定**:
- 実際の認証（Apple/Google Sign-In）
- 入力フィールドの動作
- 実際の権限リクエスト（Location, Bluetooth, Notifications）
- バリデーション
- 状態の永続化

---

## アクセシビリティ

### VoiceOver/TalkBack

| 要素 | 読み上げ |
|---|---|
| プログレス | 「ステップ1/3」 |
| 権限カード | 「位置情報、許可が必要です。近くにいる人を見つけるために使います」 |
| 許可済み | 「位置情報、許可済み」 |

### ダイナミックタイプ

- 大きいサイズでもプログレスバーは固定高さ
- テキストは最大150%まで対応
