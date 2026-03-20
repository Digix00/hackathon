package gemini

import (
	"context"
	"encoding/json"
	"fmt"
	"strings"

	"cloud.google.com/go/vertexai/genai"

	"hackathon/internal/usecase/port"
)

// Client は Vertex AI 経由で Gemini を呼び出すクライアント
type Client struct {
	client *genai.Client
	model  *genai.GenerativeModel
}

// NewClient は Gemini クライアントを初期化する
func NewClient(ctx context.Context, projectID, location, modelID string) (*Client, error) {
	client, err := genai.NewClient(ctx, projectID, location)
	if err != nil {
		return nil, fmt.Errorf("gemini.NewClient: %w", err)
	}

	model := client.GenerativeModel(modelID)
	model.SetTemperature(0.7)

	return &Client{
		client: client,
		model:  model,
	}, nil
}

// extractText はレスポンスからテキスト部分を取り出す
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

// cleanJSON はモデルが返す可能性のある Markdown コードフェンスを除去する
func cleanJSON(s string) string {
	s = strings.TrimSpace(s)
	s = strings.TrimPrefix(s, "```json")
	s = strings.TrimPrefix(s, "```")
	s = strings.TrimSuffix(s, "```")
	return strings.TrimSpace(s)
}

// Close は内部の gRPC 接続を閉じる
func (c *Client) Close() error {
	return c.client.Close()
}

// AnalyzeLyrics は歌詞を分析してムード・ジャンル等を推定する
func (c *Client) AnalyzeLyrics(ctx context.Context, lyrics string) (*port.LyricsAnalysis, error) {
	prompt := "以下の歌詞を分析してください。\n\n" +
		"必ず有効な JSON オブジェクトのみを返してください。" +
		"説明文、前置き・後置きの文章、コメント、Markdown のコードブロックやバッククォートなど、JSON 以外の文字は一切出力しないでください。\n\n" +
		"歌詞:\n" + lyrics + "\n\n" +
		"以下の形式の JSON オブジェクトのみを返してください:\n" +
		"{\n" +
		"  \"mood\": \"メインのムード（英語1語。次のいずれか: melancholic, upbeat, nostalgic, energetic, peaceful, romantic）\",\n" +
		"  \"secondary_moods\": [\"サブムード1（日本語）\", \"サブムード2（日本語）\"],\n" +
		"  \"genre\": \"推奨ジャンル（英語。例: j-pop, rock, ballad, electronic）\",\n" +
		"  \"tempo\": \"推奨テンポ（英語。次のいずれか: slow, medium, fast）\",\n" +
		"  \"suggested_title\": \"歌詞の内容に合った曲タイトル案（日本語）\",\n" +
		"  \"keywords\": [\"キーワード1（日本語）\", \"キーワード2（日本語）\", \"キーワード3（日本語）\"],\n" +
		"  \"language\": \"言語コード（英小文字の2文字。例: ja, en）\"\n" +
		"}"

	resp, err := c.model.GenerateContent(ctx, genai.Text(prompt))
	if err != nil {
		return nil, fmt.Errorf("gemini.AnalyzeLyrics: %w", err)
	}

	raw := cleanJSON(extractText(resp))
	var analysis port.LyricsAnalysis
	if err := json.Unmarshal([]byte(raw), &analysis); err != nil {
		return nil, fmt.Errorf("gemini.AnalyzeLyrics: failed to parse JSON: %w", err)
	}

	return &analysis, nil
}

// ModerateContent はコンテンツの安全性をチェックする
func (c *Client) ModerateContent(ctx context.Context, content string) (*port.ModerationResult, error) {
	prompt := "以下のテキストが不適切なコンテンツを含むかチェックしてください。\n\n" +
		"必ず有効な JSON オブジェクトのみを返してください。JSON 以外の文字は一切出力しないでください。\n\n" +
		"テキスト: " + content + "\n\n" +
		"以下の形式の JSON オブジェクトを返してください:\n" +
		"{\n" +
		"  \"is_harmful\": true/false,\n" +
		"  \"categories\": [\"該当カテゴリ（ヘイト、暴力、成人向け等）\"],\n" +
		"  \"confidence\": 0.0-1.0,\n" +
		"  \"suggestion\": \"修正提案（該当時のみ）\"\n" +
		"}"

	resp, err := c.model.GenerateContent(ctx, genai.Text(prompt))
	if err != nil {
		return nil, fmt.Errorf("gemini.ModerateContent: %w", err)
	}

	raw := cleanJSON(extractText(resp))
	var result port.ModerationResult
	if err := json.Unmarshal([]byte(raw), &result); err != nil {
		return nil, fmt.Errorf("gemini.ModerateContent: failed to parse JSON: %w", err)
	}

	return &result, nil
}

// GenerateTitle は歌詞から曲タイトルを生成する
func (c *Client) GenerateTitle(ctx context.Context, lyrics string, mood string) (string, error) {
	prompt := fmt.Sprintf(
		"以下の歌詞とムードに合った曲タイトルを日本語で1つだけ生成してください。\nタイトルのみを返し、説明や引用符は不要です。\n\nムード: %s\n歌詞:\n%s",
		mood, lyrics,
	)

	resp, err := c.model.GenerateContent(ctx, genai.Text(prompt))
	if err != nil {
		return "", fmt.Errorf("gemini.GenerateTitle: %w", err)
	}

	title := strings.TrimSpace(extractText(resp))
	if title == "" {
		return "無題", nil
	}

	return title, nil
}
