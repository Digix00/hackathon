# モバイル技術スタック

## iOS

| 項目 | 採用技術 | 備考 |
|---|---|---|
| 言語 | Swift | |
| UI | TBD（SwiftUI / UIKit） | |
| BLE | CoreBluetooth | バックグラウンド動作は Info.plist 設定 + Central/Peripheral 両対応が必要 |
| 位置情報 | CoreLocation | 常時取得 or 使用時取得の権限設計が審査に影響 |
| 認証 | Sign in with Apple | App Store ガイドライン上、サードパーティ認証を使う場合は必須 |
| 通知 | APNs (UserNotifications) | |
| 音楽連携 | Spotify iOS SDK / MusicKit | MusicKit は Apple Music 専用 |

### iOS 実装メモ（ハッカソン判断）

ハッカソン期間中は実装速度を優先しつつ、`BackendAPIClient` のパスエンコードは共通ヘルパーに集約済み。`BackendEncounterUser` の専用モデル化は見送り（現状の `typealias` + 意図コメントで運用）。安定化フェーズで型の厳密化の再検討を行う。

### iOS プッシュ/PR前チェック

- `ObservableObject` + `@Published` を使う ViewModel は `import Combine` を必ず追加する（`SwiftUI` 単独では `@Published` が解決されない）
- iOS ターゲットをローカルでビルドし、`Combine` 未importによる `ObservableObject` エラーが出ないことを確認する

### iOS BLE 制約（最優先技術検証事項）

- バックグラウンドでの Peripheral アドバタイズは制限あり（フォアグラウンド遷移で復帰する挙動）
- Central スキャンはバックグラウンド継続可能だが、スキャン間隔が OS により延長される
- RSSI によるバックグラウンド距離推定の精度は低い（壁・ポケット・混雑による大幅なブレ）
- BLE ID は発行時刻から24時間有効の短命トークンを利用（固定 ID は追跡リスク）

## Android

| 項目 | 採用技術 | 備考 |
|---|---|---|
| 言語 | Kotlin | |
| UI | Jetpack Compose | StateFlow + collectAsState |
| アーキテクチャ | MVVM + Repository | 単一 app モジュール |
| DI | Hilt | |
| 通信 | Retrofit + OkHttp + Kotlinx Serialization | BuildConfig で dev/prod URL 切替 |
| ローカル保存 | Room + DataStore | BLE 交換レコードは Room、設定は DataStore |
| 画像 | Coil | ジャケ写キャッシュ |
| BLE | Android Bluetooth API (BluetoothLeScanner / AdvertiseCallback) | Foreground Service 常駐 |
| 位置情報 | FusedLocationProviderClient | |
| 認証 | Google Sign-In | Firebase Auth 連携 |
| 通知 | FCM | |
| 音楽連携 | Spotify Android SDK | |
| SDK | minSdk 26 / targetSdk 35 | |
| ビルド | dev/prod 2 flavor | |
| 秘密情報 | local.properties + CI Secrets | `local.properties` は .gitignore 対象 |
| 品質ゲート | ktlint + Detekt + ユニットテスト | CI 必須チェック |
| applicationId | com.digix00.musicswapping | |

### Android BLE 制約

- 機種差・メーカー独自省電力設定による挙動の差が大きい
- Android 12 以降は BLUETOOTH_SCAN / BLUETOOTH_ADVERTISE 権限が個別に必要
- バックグラウンドスキャンは Foreground Service 化が実質的に必要

## 共通設計方針

- オフライン時も UI が破綻しない設計（BLE 交換レコードをローカルに保持し、オンライン復帰時に再送）
- 外部 API（Spotify 等）のジャケ写はローカルキャッシュ
- 権限リクエストは Bluetooth → 通知 → 位置情報 の順でオンボーディングフローに組み込む
