# iOS BLE 実機 2 台検証（ローカル Docker バックエンド）手順

この手順書は、**ローカルの Docker でバックエンドを起動**し、
**iPhone 実機 2 台で BLE の送受信を検証**するための流れをまとめたものです。

人によって変わる値（ローカルIPなど）は **プレースホルダ** で記載しています。

---

## 前提

- iPhone 実機 2 台
- 同一 Wi-Fi（Mac と iPhone が同じネットワーク）
- Mac で Docker が動作すること
- iOS アプリを Xcode でビルドできること

---

## 1. バックエンドをローカル Docker で起動する

このプロジェクトのバックエンド起動手順に従って、API と DB を起動します。
（詳細はチーム内のバックエンド手順書に合わせてください）

**確認ポイント**
- API が `http://<MAC_LOCAL_IP>:<API_PORT>/api/v1/...` で疎通できること
- DB が起動しており、`ble_tokens` などのテーブルが使えること

---

## 2. iOS アプリの API エンドポイントを設定する

iOS 側は `API_BASE_URL` を参照します。人によって値が変わるため、
**Scheme の Environment Variables で設定**するのが推奨です。

### 推奨: Scheme の Environment Variables

- Key: `API_BASE_URL`
- Value: `http://<MAC_LOCAL_IP>:<API_PORT>`

`<MAC_LOCAL_IP>` は Mac のローカル IP（例: `192.168.x.x`）
`<API_PORT>` はバックエンドの API ポート（例: `8000`）

---

## 3. 認証トークンを設定する

アプリは API リクエスト時に **Bearer Token** を要求します。
そのため、環境変数 `FIREBASE_ID_TOKEN` を設定しておく必要があります。

### 推奨: Firebase Auth エミュレータで ID トークンを発行

ローカル運用ではエミュレータの利用が想定されています。
手順は以下のドキュメントにまとめています。

- `/Users/ryusuke/home/hackathon/docs/overview/firebase-auth-emulator-ops.md`

### Scheme の Environment Variables

- Key: `FIREBASE_ID_TOKEN`
- Value: `<ID_TOKEN>`

---

## 4. iPhone 実機へビルド・インストール（2 台）

1. iPhone A を接続してビルド & インストール
2. iPhone B を接続してビルド & インストール

※ 同じ Scheme 設定で OK（トークンや API URL は共通でよい）

---

## 5. BLE 動作確認

1. 両端末でアプリを起動
2. Bluetooth を ON
3. 2 台を近づける

**期待される挙動**
- 端末同士の BLE 検出が発生し、
  `ble-tokens` に紐づくユーザー取得・エンカウント登録が行われる

---

## 6. よくある詰まりポイント

- **iPhone から API に繋がらない**
  - `localhost` を使っていないか確認
  - `<MAC_LOCAL_IP>` に置き換えているか確認
  - Mac / iPhone が同じ Wi-Fi か確認

- **401 Unauthorized が返る**
  - `FIREBASE_ID_TOKEN` の設定があるか確認
  - 期限切れトークンでないか確認

- **BLE 反応が弱い / 出ない**
  - 端末が近いか（数十 cm）
  - Bluetooth が ON か
  - バックグラウンド動作は不安定になりやすい（iOS 制約）

---

# 現状の実装で「未実装 / 不足している可能性があるもの」

実機検証を確実にするために、現状のコード上で足りていない点は以下です。

1. **検知結果の UI 表示がない**
   - BLE 検知が起きても画面に表示されないため、
     「動いているか分からない」状態になりやすい

2. **検知ログ / デバッグ表示がない**
   - RSSI や検知トークンの確認ができない
   - コンソールにログ出しも未整備

3. **検知フィルタが厳しめ**
   - RSSI 閾値 / 検知回数 / デバウンス / クールダウンで
     短時間では検知が出づらい可能性がある

4. **バックエンド依存が必須**
   - BLE 広告開始が API 依存のため、
     API が起動していないと検証が進まない

---

## 推奨の追加対応（任意）

- 画面上に `isAdvertising / isScanning / latestDetection` を表示
- BLE 検知を `Console` に出力
- 検知フィルタをテスト用に緩める
