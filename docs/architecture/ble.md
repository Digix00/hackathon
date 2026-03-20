# すれ違い音楽交換アプリ BLEアーキテクチャ設計（改訂版）

## 1. 目的

スマートフォン同士が近距離（数m〜数十m）ですれ違った際に、
ユーザーの「好きな曲」を自動で交換する。

BLEは **ユーザー識別のための一時トークン交換のみ** に使用し、
実際のデータ取得・エンカウント判定はバックエンドAPIを利用する。

BLEでは以下を送信しない

- user_id
- 個人情報
- 曲情報

本設計書では以下を扱う。

-   BLE通信設計
-   クライアント検出ロジック
-   Backendとの連携方法
-   iOS / Android 制約
-   セキュリティ設計

API詳細仕様は **API設計書を参照する。**

------------------------------------------------------------------------

# 2. 全体アーキテクチャ

    BLE Advertising / Scan
           ↓
    BLEトークン取得
           ↓
    クライアントフィルタ
      - cooldown
      - rssi
      - detection count
      - debounce
           ↓
    Backend API 呼び出し
           ↓
    サーバー: トークン → user_id 解決
           ↓
    Encounter判定・登録
           ↓
    曲情報取得

責務分離

  レイヤー   役割
  ---------- --------------------
  BLE        近距離ユーザー検出
  Client     軽量フィルタ
  API        エンカウント登録
  Server     ビジネスロジック

------------------------------------------------------------------------

# 3. BLEレイヤー

## 3.1 BLEの役割

BLEは以下のみを担当する。

-   近距離ユーザー検出
-   一時トークンの受信

BLEは **ユーザー識別専用**

------------------------------------------------------------------------

## 3.2 BLE通信方式

    advertise(serviceUUIDs = [APP_UUID, TOKEN_UUID])  ←→  scan(APP_UUID)

connectは使用しない

理由

- 接続は不安定
- 電力消費が増える
- iOS background制約が多い


------------------------------------------------------------------------

## 3.3 Advertising Payload

BLE advertising payloadは最大 **31 bytes** の制限がある。


payload構成

|項目|内容|
|---|---|
APP_SERVICE_UUID | アプリ識別 |
TOKEN_UUID | 一時トークン |

advertising
serviceUUIDs = [
  APP_SERVICE_UUID,
  TOKEN_UUID
]

理由

iOSバックグラウンドではService UUID指定スキャンが必要

BLEはAdvertising PacketとScan Response Packetを使用する。

Local Nameなど追加情報は
Scan Responseに含まれる可能性がある。

------------------------------------------------------------------------

# 3.4 Scan方式

scan(serviceUUIDs=[APP_SERVICE_UUID])

token取得

advertisement.serviceUUIDs
↓
TOKEN_UUID抽出

## Scan開始条件

centralManager.state == poweredOn

## Scan duplicate policy

iOS
CBCentralManagerScanOptionAllowDuplicatesKey = true

Android
setReportDelay(0)

# 3.5 Advertising / Scanパラメータ

### iOS


scan parameters controlled by OS


iOSでは

- scan_interval
- scan_window

は設定不可

---

### Android

|設定|値|
|---|---|
scan_interval | 5s |
scan_window | 2s |
scan_mode | low_power |

---

### Advertising

|設定|値|
|---|---|
advertise_interval | iOS / Android OS controlled |
advertise_mode | low_power |

# 3.6 BLE Detection Strategy

BLE検出率向上のため
以下の3つを組み合わせる

iOSはバックグラウンドスキャン頻度を制限するため
単純なadvertise + scanでは検出率が低くなる。

そのため以下の戦略を組み合わせる。
- BLE advertise
- Opportunistic scan
- Foreground boost

---

## Opportunistic Scan

スキャンは常時実行せず
一定周期で短時間のみ実行する

Android
scan 5秒
sleep 10秒

iOS
OS-controlled scan scheduling

iOSではscan intervalをアプリから制御できない

Androidの実装

while appRunning:

  startScan()

  sleep(scanWindow)

  stopScan()

  sleep(scanInterval)

---

## Foreground Boost

アプリがForeground状態のとき
scan強度を上げる

foreground

continuous scan

background

opportunistic scan


------------------------------------------------------------------------

# 4. BLEトークン設計

ユーザー識別は **サーバーが発行** 

理由

-   ユーザー追跡防止
-   クライアントにsecretを持たせない
-   サーバーで失効管理可能

------------------------------------------------------------------------
## トークンフォーマット

ble_token = 8 bytes

UUID変換

TOKEN_UUID =
APP_PREFIX(8bytes)
+
TOKEN(8bytes)

例
xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx

------------------------------------------------------------------------

## トークンrotation戦略

トークンは **ユーザー単位で24時間有効** とする。

    token_valid_to = issued_at + 24h

これにより

- サーバー負荷を抑えた運用
- MVPでの実装運用コスト最適化
- 発行時刻基準の24時間TTLによる最低限の追跡防止

------------------------------------------------------------------------

# 5. クライアント軽量フィルタ

BLEは同じユーザーを短時間で何度も検出する。

例

    電車
    ↓
    30秒
    ↓
    10回検出

これを防ぐため **クライアントcooldownフィルタ** を行う。

------------------------------------------------------------------------

## cooldown設定

  設定       値
  ---------- -----
  cooldown   5分

------------------------------------------------------------------------

## foreground判定

foregroundでは誤検知を減らすため

- 同一tokenを **30秒以内に2回検出** したときのみ成立
- RSSI は **-85以上**

## background判定

iOSのbackground scanはOS制御で
30秒以内に2回検出できる保証がない。

そのため background では

- **1回検出で成立**
- RSSI は foreground より厳しく **-80以上**
- 30秒 debounce には依存しない

## debounce

同一tokenの短時間連打抑止は foreground のみで行う。

- foreground: 30秒以内の連続API送信禁止
- background: debounce なし

------------------------------------------------------------------------

## RSSIフィルタ

遠距離ノイズを防ぐため以下を適用する。

  条件                 処理
  -------------------- ------
  foreground rssi < -85 無視
  background rssi < -80 無視

距離目安

|RSSI|距離|
|---|---|
-60 | 約1m |
-70 | 約2m |
-80 | 約5m |

------------------------------------------------------------------------

## detection count

誤検出防止

- foreground: detect_count >= 2
- background: detect_count >= 1

------------------------------------------------------------------------

# 6. Backend Interaction

BLE検出後、クライアントはBackend APIへ
エンカウント登録リクエストを送信する。

    POST /encounters

APIのRequest / Response仕様は **API設計書を参照する。**

------------------------------------------------------------------------

# 7. サーバー処理（概要）

サーバーは以下を実施する。

    APIリクエスト受信
    ↓
    token → user_id 解決
    ↓
    重複チェック
    ↓
    レート制限チェック
    ↓
    Encounter登録

|制御|内容|
|---|---|
|1日制限 | 同一ユーザーペア（A×B の組み合わせ）ごとに 1日1回。例: AがBと1回、AがCと1回、AがDと1回…は全て OK。 |
|冪等 | 5分以内重複 |
|rate limit | API保護 |

------------------------------------------------------------------------

# 8. iOS Background 制約

iOSでは

- ユーザーがアプリをスワイプ終了した場合、BLEは停止する
- background scan throttling
- scan頻度OS制御

また

- Local Nameはadvertiseされない
- Service UUIDはoverflow領域

------------------------------------------------------------------------

# 9. iOS Capability

Info.plist

NSBluetoothAlwaysUsageDescription

Capabilities

Background Modes
→バックグラウンドでBLEを動かすための設定

- bluetooth-central(バックグラウンドでスキャン許可)
- bluetooth-peripheral（バックグラウンドでアドバタイズ許可）

------------------------------------------------------------------------

# 10. Battery対策

BLEは電力消費が大きい

対策

- low power advertising
- RSSIフィルタ
- cooldown
- debounce

さらに

|条件|動作|
|---|---|
BLE OFF | 停止 |
battery saver | 停止 |

app background long time
→ scan frequency reduce

------------------------------------------------------------------------

# 11. セキュリティ設計

  項目        内容
  ----------- --------------------
  user_id     BLEで送信しない
  token       サーバー発行
  token期限   24時間
  revoke      サーバーで失効可能

------------------------------------------------------------------------

# 12. すれ違い処理フロー

    ① token取得
    ② advertise開始
    ③ scan(APP_SERVICE_UUID)
    ④ TOKEN_UUID取得
    ⑤ RSSI check
    ⑥ detection count
    ⑦ cooldown
    ⑧ debounce
    ⑨ API送信
    ⑩ server判定
    ⑪ encounter登録

------------------------------------------------------------------------

# 13. 技術スタック

## Mobile

iOS\
Swift + CoreBluetooth

Android\
Kotlin + BLE API

## Backend

Go\
Echo\
PostgreSQL

------------------------------------------------------------------------

# 14. 将来拡張

-   すれ違い履歴
-   曲レコメンド
-   位置情報連携
-   友達機能
-   コメント機能
