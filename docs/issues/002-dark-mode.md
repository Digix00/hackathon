# Issue #002: ダークモード実装

## 概要
アプリ全体でダークモードをサポートし、ユーザーがシステム設定または アプリ内設定でライト/ダークテーマを切り替えられるようにする。

## 発生する可能性のある問題

### 1. テーマ切り替えの不完全性
- 一部のコンポーネントがテーマに対応していない
- 切り替え時にUIが一時的に崩れる可能性

### 2. 視認性の問題
- 色のコントラストが不十分で、テキストが読みにくい
- ダークモードでの画像やアイコンが見づらい
- グラデーションや背景効果が適切に調整されていない

### 3. 一貫性の欠如
- コンポーネント間で色の使い方が統一されていない
- システムのダークモード設定との連携が不完全

## 対応方針

### iOS アプリでの実装

#### 1. カラーパレットの定義
```swift
extension Color {
    // プライマリカラー
    static let primaryLight = Color(hex: "6366F1")
    static let primaryDark = Color(hex: "818CF8")

    // 背景色
    static let backgroundLight = Color.white
    static let backgroundDark = Color(hex: "0F0F0F")

    // テキストカラー
    static let textPrimaryLight = Color.black
    static let textPrimaryDark = Color.white

    // セカンダリ要素
    static let surfaceLight = Color(hex: "F3F4F6")
    static let surfaceDark = Color(hex: "1F1F1F")
}
```

#### 2. テーママネージャーの実装
```swift
class ThemeManager: ObservableObject {
    @Published var isDarkMode: Bool = false

    init() {
        // システム設定を初期値とする
        self.isDarkMode = UITraitCollection.current.userInterfaceStyle == .dark
    }

    func toggleTheme() {
        isDarkMode.toggle()
    }
}
```

#### 3. SwiftUIでの適用
```swift
struct ContentView: View {
    @EnvironmentObject var themeManager: ThemeManager

    var body: some View {
        VStack {
            // コンテンツ
        }
        .preferredColorScheme(themeManager.isDarkMode ? .dark : .light)
    }
}
```

#### 4. 既存コンポーネントの更新
- `PrototypeTheme.swift`にダークモード対応のカラーセットを追加
- 各Viewで`.background()`や`.foregroundColor()`を動的に切り替え
- グラデーションや影の効果をテーマに応じて調整

## 推奨される実装

### カラーシステム
- **セマンティックカラー**: 役割ベースのカラー定義（primary, secondary, background, surface, error等）
- **システム連携**: iOS のダークモード設定と自動的に同期
- **手動切り替え**: アプリ内設定でユーザーが任意に切り替え可能

### 実装の優先順位
1. **Phase 1**: カラーパレットとテーママネージャーの実装
2. **Phase 2**: メイン画面（プレイヤー、ホーム）のダークモード対応
3. **Phase 3**: 設定画面、リスト画面などのダークモード対応
4. **Phase 4**: 細かい調整とテスト

### 対応が必要なコンポーネント
- プレイヤー画面（背景グラデーション、コントロールボタン）
- ホーム画面（カード、リスト）
- 設定画面
- ナビゲーションバー
- タブバー
- モーダル、アラート

## 実装スケジュール

- [ ] カラーパレット定義の作成
- [ ] テーママネージャーの実装
- [ ] PrototypeTheme.swiftの更新
- [ ] プレイヤー画面のダークモード対応
- [ ] ホーム画面のダークモード対応
- [ ] 設定画面にテーマ切り替えオプションを追加
- [ ] その他の画面のダークモード対応
- [ ] グラデーションと背景効果の調整
- [ ] テストと調整
- [ ] デザインレビュー

## テスト項目

1. **システム設定との連携**: iOSのダークモード設定変更時に正しく反映されるか
2. **手動切り替え**: アプリ内でテーマを切り替えた際にすべてのUIが正しく更新されるか
3. **視認性**: ダークモードでテキストやアイコンが十分なコントラストで見やすいか
4. **アニメーション**: テーマ切り替え時のアニメーションがスムーズか
5. **画像とアイコン**: ダークモードで適切に表示されるか
6. **グラデーション**: 背景のグラデーションがダークモードで適切に調整されているか
7. **状態の保持**: アプリを再起動してもテーマ設定が保持されるか

## 参考資料

### Apple公式ドキュメント
- [Supporting Dark Mode in Your Interface](https://developer.apple.com/documentation/uikit/appearance_customization/supporting_dark_mode_in_your_interface)
- [SwiftUI Color and Color Scheme](https://developer.apple.com/documentation/swiftui/color)
- [preferredColorScheme](https://developer.apple.com/documentation/swiftui/view/preferredcolorscheme(_:))

### デザインガイドライン
- Apple Human Interface Guidelines - Dark Mode
- Material Design - Dark theme

### 実装例
- [SwiftUI Dark Mode Tutorial](https://www.hackingwithswift.com/quick-start/swiftui/how-to-detect-dark-mode)

## 関連Issue
- #001 (タイトルやアーティスト名が長い場合の対応) - ダークモードでのテキスト視認性に影響

## 優先度
**High** - ユーザー体験とアクセシビリティの向上に重要

## ステータス
**Open** - 実装待ち

---
作成日: 2026-03-15
最終更新: 2026-03-15
