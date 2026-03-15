# Lyria API 連携設計

## 概要

Google DeepMind の **Lyria** は、テキストプロンプトから高品質な音楽を生成する AI モデル。
Vertex AI 経由で API を利用し、歌詞チェーン機能での楽曲生成に活用する。

---

## Lyria API 基本情報

| 項目 | 値 |
|------|-----|
| モデル | lyria-002 |
| アクセス方法 | Vertex AI Generative AI API |
| リージョン | us-central1（推奨） |
| 出力形式 | WAV / MP3 |
| 最大生成時間 | 約60秒 |
| レイテンシ | 30秒〜2分（楽曲長による） |

---

## アーキテクチャ

```
┌─────────────────────────────────────────────────────────────────┐
│                        Backend (Go)                             │
│                                                                 │
│  ┌─────────────┐    ┌─────────────┐    ┌─────────────────────┐ │
│  │   Handler   │───▶│   UseCase   │───▶│   LyriaClient       │ │
│  │             │    │             │    │   (port interface)  │ │
│  └─────────────┘    └─────────────┘    └──────────┬──────────┘ │
│                                                    │            │
└────────────────────────────────────────────────────┼────────────┘
                                                     │
                                                     ▼
┌─────────────────────────────────────────────────────────────────┐
│                    infra/lyria/client.go                        │
│                                                                 │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │  Vertex AI SDK                                          │   │
│  │  ├─ GenerateMusic(prompt, params) → AudioData           │   │
│  │  └─ CheckStatus(operationID) → Status                   │   │
│  └─────────────────────────────────────────────────────────┘   │
│                            │                                    │
└────────────────────────────┼────────────────────────────────────┘
                             │
                             ▼
┌─────────────────────────────────────────────────────────────────┐
│                     Google Cloud                                │
│                                                                 │
│  ┌───────────────┐    ┌───────────────┐    ┌───────────────┐   │
│  │  Vertex AI    │───▶│    Lyria      │───▶│ Cloud Storage │   │
│  │  (API Gateway)│    │   (lyria-002) │    │  (Audio保存)  │   │
│  └───────────────┘    └───────────────┘    └───────────────┘   │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

---

## Gemini + Lyria 連携フロー

歌詞から直接 Lyria を呼ぶのではなく、Gemini で歌詞を分析してから Lyria に渡す。

```
┌──────────────┐     ┌──────────────┐     ┌──────────────┐
│   歌詞連結   │────▶│   Gemini     │────▶│   Lyria      │
│              │     │  (分析)      │     │  (生成)      │
└──────────────┘     └──────────────┘     └──────────────┘
                            │
                            ▼
                     ┌──────────────┐
                     │ 分析結果     │
                     │ - ムード     │
                     │ - ジャンル   │
                     │ - テンポ     │
                     │ - タイトル案 │
                     └──────────────┘
```

---

## インターフェース定義

### Port（usecase/port/lyria.go）

```go
package port

import "context"

// LyriaClient は楽曲生成AIとの連携インターフェース
type LyriaClient interface {
    // GenerateSong は歌詞とパラメータから楽曲を生成する
    GenerateSong(ctx context.Context, req *LyriaRequest) (*LyriaResponse, error)
}

// LyriaRequest は楽曲生成リクエスト
type LyriaRequest struct {
    // Lyrics は連結された歌詞
    Lyrics string

    // Mood は楽曲のムード（Geminiで分析）
    // 例: "melancholic", "upbeat", "nostalgic", "energetic"
    Mood string

    // Genre はジャンル
    // 例: "J-POP", "Rock", "Electronic", "Acoustic"
    Genre string

    // Tempo はテンポ指定
    // 例: "slow", "medium", "fast"
    Tempo string

    // DurationSec は楽曲の長さ（秒）
    DurationSec int

    // Title は曲タイトル（メタデータ用）
    Title string
}

// LyriaResponse は楽曲生成結果
type LyriaResponse struct {
    // AudioData は生成された音声データ（WAV形式）
    AudioData []byte

    // Format は音声フォーマット
    Format string // "wav" or "mp3"

    // DurationSec は実際の楽曲長
    DurationSec int

    // Metadata は追加メタデータ
    Metadata map[string]string
}
```

### Port（usecase/port/gemini.go）

```go
package port

import "context"

// GeminiClient はGemini APIとの連携インターフェース
type GeminiClient interface {
    // AnalyzeLyrics は歌詞を分析してムード・ジャンル等を推定する
    AnalyzeLyrics(ctx context.Context, lyrics string) (*LyricsAnalysis, error)

    // ModerateContent はコンテンツの安全性をチェックする
    ModerateContent(ctx context.Context, content string) (*ModerationResult, error)

    // GenerateTitle は歌詞から曲タイトルを生成する
    GenerateTitle(ctx context.Context, lyrics string, mood string) (string, error)
}

// LyricsAnalysis は歌詞分析結果
type LyricsAnalysis struct {
    Mood           string   `json:"mood"`             // メインのムード
    SecondaryMoods []string `json:"secondary_moods"`  // サブムード
    Genre          string   `json:"genre"`            // 推奨ジャンル
    Tempo          string   `json:"tempo"`            // 推奨テンポ
    SuggestedTitle string   `json:"suggested_title"`  // タイトル案
    Keywords       []string `json:"keywords"`         // キーワード
    Language       string   `json:"language"`         // 言語（ja, en, etc.）
}

// ModerationResult はコンテンツモデレーション結果
type ModerationResult struct {
    IsHarmful    bool     `json:"is_harmful"`
    Categories   []string `json:"categories"` // 該当したカテゴリ
    Confidence   float64  `json:"confidence"`
    Suggestion   string   `json:"suggestion"` // 修正提案（該当時）
}
```

---

## 実装

### infra/lyria/client.go

```go
package lyria

import (
    "context"
    "fmt"

    aiplatform "cloud.google.com/go/aiplatform/apiv1"
    "cloud.google.com/go/aiplatform/apiv1/aiplatformpb"
    port "example.com/yourapp/internal/usecase/port"
    "google.golang.org/api/option"
    "google.golang.org/protobuf/types/known/structpb"
)

type Client struct {
    projectID  string
    location   string
    modelID    string
    endpoint   *aiplatform.PredictionClient
}

func NewClient(ctx context.Context, projectID, location string) (*Client, error) {
    endpoint := fmt.Sprintf("%s-aiplatform.googleapis.com:443", location)
    client, err := aiplatform.NewPredictionClient(ctx, option.WithEndpoint(endpoint))
    if err != nil {
        return nil, fmt.Errorf("failed to create prediction client: %w", err)
    }

    return &Client{
        projectID: projectID,
        location:  location,
        modelID:   "lyria-002",
        endpoint:  client,
    }, nil
}

func (c *Client) GenerateSong(ctx context.Context, req *port.LyriaRequest) (*port.LyriaResponse, error) {
    // プロンプト構築
    prompt := c.buildPrompt(req)

    // Vertex AI エンドポイント
    endpointPath := fmt.Sprintf(
        "projects/%s/locations/%s/publishers/google/models/%s",
        c.projectID, c.location, c.modelID,
    )

    // モデルパラメータ（温度などのチューニング用）
    params, err := structpb.NewStruct(map[string]interface{}{
        "temperature": 0.3,
    })
    if err != nil {
        return nil, fmt.Errorf("failed to create params: %w", err)
    }

    // インスタンスペイロード（Lyria への実際の入力）
    instanceStruct, err := structpb.NewStruct(map[string]interface{}{
        "prompt":        prompt,
        "duration_sec":  req.DurationSec,
        "output_format": "wav",
    })
    if err != nil {
        return nil, fmt.Errorf("failed to create instance: %w", err)
    }

    // PredictRequest.Instances は []*structpb.Value を受け取る
    instanceValue := structpb.NewStructValue(instanceStruct)

    // API呼び出し
    resp, err := c.endpoint.Predict(ctx, &aiplatformpb.PredictRequest{
        Endpoint:   endpointPath,
        Instances:  []*structpb.Value{instanceValue},
        Parameters: structpb.NewStructValue(params),
    })
    if err != nil {
        return nil, fmt.Errorf("lyria prediction failed: %w", err)
    }

    // レスポンス解析
    audioData, err := c.extractAudioData(resp)
    if err != nil {
        return nil, err
    }

    return &port.LyriaResponse{
        AudioData:   audioData,
        Format:      "wav",
        DurationSec: req.DurationSec,
    }, nil
}

func (c *Client) buildPrompt(req *port.LyriaRequest) string {
    // Lyriaに渡すプロンプトを構築
    return fmt.Sprintf(`Generate a %s %s song with %s tempo.

Lyrics:
%s

Style notes:
- Mood: %s
- Genre: %s
- Create a memorable melody that matches the emotional tone of the lyrics
- Include appropriate instrumental accompaniment`,
        req.Mood,
        req.Genre,
        req.Tempo,
        req.Lyrics,
        req.Mood,
        req.Genre,
    )
}
```

### infra/gemini/client.go

```go
package gemini

import (
    "context"
    "encoding/json"
    "fmt"

    "cloud.google.com/go/vertexai/genai"
    port "example.com/yourapp/internal/usecase/port"
)

type Client struct {
    client  *genai.Client
    model   *genai.GenerativeModel
}

func NewClient(ctx context.Context, projectID, location string) (*Client, error) {
    client, err := genai.NewClient(ctx, projectID, location)
    if err != nil {
        return nil, err
    }

    model := client.GenerativeModel("gemini-1.5-flash")
    model.SetTemperature(0.7)

    return &Client{
        client: client,
        model:  model,
    }, nil
}

// Gemini レスポンスからテキスト部分のみを取り出すヘルパー関数の一例。
// - 複数候補が返る場合: 先頭の候補のみを利用
// - 候補0件/テキストパート無しの場合: 空文字列を返す
func extractText(resp *genai.GenerateContentResponse) string {
    if resp == nil || len(resp.Candidates) == 0 {
        return ""
    }

    cand := resp.Candidates[0]
    if cand.Content == nil || len(cand.Content.Parts) == 0 {
        return ""
    }

    for _, part := range cand.Content.Parts {
        if txt, ok := part.(genai.Text); ok {
            return string(txt)
        }
    }

    return ""
}

func (c *Client) AnalyzeLyrics(ctx context.Context, lyrics string) (*port.LyricsAnalysis, error) {
    prompt := fmt.Sprintf(`以下の歌詞を分析してください。

必ず有効な JSON オブジェクトのみを返してください。説明文、前置き・後置きの文章、コメント、Markdown のコードブロックやバッククォート（``` や `）など、JSON 以外の文字は一切出力しないでください。
出力は先頭から末尾まで 1 つの JSON オブジェクトのみとし、改行は JSON 内のインデントのために使用しても構いません。

歌詞:
%s

以下の形式の JSON オブジェクト「のみ」を返してください。前後に説明文やコードフェンス（```）を付けないでください。
各フィールドの値は、指定された言語・形式に厳密に従ってください。
{
  "mood": "メインのムード（英語1語。次のいずれか: melancholic, upbeat, nostalgic, energetic, peaceful, romantic）",
  "secondary_moods": ["サブムード1（日本語）", "サブムード2（日本語）"],
  "genre": "推奨ジャンル（英語。例: j-pop, rock, ballad, electronic）",
  "tempo": "推奨テンポ（英語。次のいずれか: slow, medium, fast）",
  "suggested_title": "歌詞の内容に合った曲タイトル案（日本語）",
  "keywords": ["キーワード1（日本語）", "キーワード2（日本語）", "キーワード3（日本語）"],
  "language": "言語コード（英小文字の2文字。例: ja, en）"
}`, lyrics)

    resp, err := c.model.GenerateContent(ctx, genai.Text(prompt))
    if err != nil {
        return nil, fmt.Errorf("gemini analysis failed: %w", err)
    }

    // JSONパース
    var analysis port.LyricsAnalysis
    if err := json.Unmarshal([]byte(extractText(resp)), &analysis); err != nil {
        return nil, fmt.Errorf("failed to parse analysis: %w", err)
    }

    return &analysis, nil
}

func (c *Client) ModerateContent(ctx context.Context, content string) (*port.ModerationResult, error) {
    prompt := fmt.Sprintf(`以下のテキストが不適切なコンテンツを含むかチェックしてください。

必ず有効な JSON オブジェクトのみを返してください。説明文、前置き・後置きの文章、コメント、Markdown のコードブロックやバッククォート（``` や `）など、JSON 以外の文字は一切出力しないでください。
出力は先頭から末尾まで 1 つの JSON オブジェクトのみとし、改行は JSON 内のインデントのために使用しても構いません。

テキスト: %s

以下の形式の JSON オブジェクトを返してください。
{
  "is_harmful": true/false,
  "categories": ["該当カテゴリ（ヘイト、暴力、成人向け等）"],
  "confidence": 0.0-1.0,
  "suggestion": "修正提案（該当時のみ）"
}`, content)

    resp, err := c.model.GenerateContent(ctx, genai.Text(prompt))
    if err != nil {
        return nil, err
    }

    var result port.ModerationResult
    if err := json.Unmarshal([]byte(extractText(resp)), &result); err != nil {
        return nil, err
    }

    return &result, nil
}
```

---

## 環境変数

```bash
# Vertex AI設定
VERTEX_AI_PROJECT_ID=your-gcp-project
VERTEX_AI_LOCATION=us-central1

# Lyria設定
LYRIA_MODEL_ID=lyria-002
LYRIA_DEFAULT_DURATION=45
LYRIA_TIMEOUT_SEC=300

# Gemini設定
GEMINI_MODEL_ID=gemini-1.5-flash
GEMINI_TEMPERATURE=0.7
```

---

## Cloud Storage 連携

生成された音声ファイルは Cloud Storage に保存。

### バケット構成

```
gs://ana-prod-generated-songs/
├── songs/
│   ├── {chain_id}/
│   │   ├── original.wav      # 生成オリジナル
│   │   └── compressed.mp3    # 配信用圧縮版
│   └── ...
└── temp/                      # 一時ファイル（TTL: 24h）
```

### アップロード処理

```go
func (s *StorageClient) UploadSong(ctx context.Context, chainID string, audioData []byte) (string, error) {
    objectPath := fmt.Sprintf("songs/%s/original.wav", chainID)

    wc := s.bucket.Object(objectPath).NewWriter(ctx)
    wc.ContentType = "audio/wav"
    wc.CacheControl = "public, max-age=31536000" // 1年キャッシュ

    if _, err := wc.Write(audioData); err != nil {
        return "", err
    }
    if err := wc.Close(); err != nil {
        return "", err
    }

    // 署名付きURLまたは公開URL返却
    return fmt.Sprintf("https://storage.googleapis.com/%s/%s", s.bucketName, objectPath), nil
}
```

---

## エラーハンドリング

### Lyria API エラー

| エラー | 対応 |
|--------|------|
| RESOURCE_EXHAUSTED | レート制限。指数バックオフでリトライ |
| INVALID_ARGUMENT | プロンプト不正。ログ記録して失敗扱い |
| INTERNAL | サービス障害。3回リトライ後失敗 |
| DEADLINE_EXCEEDED | タイムアウト。リトライ |

### リトライ設定

```go
var retryConfig = &RetryConfig{
    MaxAttempts:     3,
    InitialInterval: 5 * time.Second,
    MaxInterval:     60 * time.Second,
    Multiplier:      2.0,
    RetryableErrors: []codes.Code{
        codes.ResourceExhausted,
        codes.Internal,
        codes.DeadlineExceeded,
        codes.Unavailable,
    },
}
```

---

## コスト見積もり

| 項目 | 単価（概算） | 月間想定 |
|------|-------------|---------|
| Lyria API | $0.05/秒生成 | 100曲×45秒 = $225 |
| Gemini API | $0.0001/1K tokens | 〜$10 |
| Cloud Storage | $0.02/GB | 〜$5 |
| **合計** | | **〜$240/月** |

※ ハッカソン期間は無料枠 + クレジットで対応可能

---

## 開発環境でのモック

本番 Lyria API は開発環境では使わず、モックを使用。

```go
// infra/lyria/mock.go
type MockClient struct{}

func (m *MockClient) GenerateSong(ctx context.Context, req *port.LyriaRequest) (*port.LyriaResponse, error) {
    // 固定のサンプル音声を返す
    sampleAudio, _ := os.ReadFile("testdata/sample_song.wav")
    return &port.LyriaResponse{
        AudioData:   sampleAudio,
        Format:      "wav",
        DurationSec: 45,
    }, nil
}
```

---

## Terraform 追加設定

```hcl
# Vertex AI API有効化
resource "google_project_service" "vertexai" {
  service = "aiplatform.googleapis.com"
}

# 生成楽曲保存用バケット
resource "google_storage_bucket" "generated_songs" {
  name     = "${var.project_id}-generated-songs"
  location = var.region

  uniform_bucket_level_access = true

  lifecycle_rule {
    condition {
      age = 1  # temp/配下は1日で削除
      matches_prefix = ["temp/"]
    }
    action {
      type = "Delete"
    }
  }
}

# サービスアカウントにVertex AI権限付与
resource "google_project_iam_member" "worker_vertexai" {
  project = var.project_id
  role    = "roles/aiplatform.user"
  member  = "serviceAccount:${google_service_account.worker.email}"
}
```
