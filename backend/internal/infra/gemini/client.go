package gemini

import (
	"bytes"
	"context"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"strings"

	"golang.org/x/oauth2/google"

	"hackathon/internal/usecase/port"
)

// Client は Gemini API (Vertex AI) REST クライアント。
// Application Default Credentials (ADC) で認証する。
type Client struct {
	projectID string
	location  string
	modelID   string
	hc        *http.Client
}

// NewClient は ADC を使って Gemini クライアントを生成する。
func NewClient(ctx context.Context, projectID, location, modelID string) (*Client, error) {
	hc, err := google.DefaultClient(ctx, "https://www.googleapis.com/auth/cloud-platform")
	if err != nil {
		return nil, fmt.Errorf("gemini: failed to create http client: %w", err)
	}
	return &Client{
		projectID: projectID,
		location:  location,
		modelID:   modelID,
		hc:        hc,
	}, nil
}

// AnalyzeLyrics は歌詞を分析してムード・ジャンル等を推定する。
func (c *Client) AnalyzeLyrics(ctx context.Context, lyrics string) (*port.LyricsAnalysis, error) {
	prompt := fmt.Sprintf(`以下の歌詞を分析してください。

必ず有効な JSON オブジェクトのみを返してください。説明文、Markdown コードブロック等、JSON 以外の文字は一切出力しないでください。

歌詞:
%s

以下の形式の JSON オブジェクト「のみ」を返してください:
{
  "mood": "メインのムード（英語1語。melancholic/upbeat/nostalgic/energetic/peaceful/romanticのいずれか）",
  "secondary_moods": ["サブムード1", "サブムード2"],
  "genre": "推奨ジャンル（英語。j-pop/rock/ballad/electronic/acousticなど）",
  "tempo": "推奨テンポ（英語。slow/medium/fastのいずれか）",
  "suggested_title": "曲タイトル案（日本語）",
  "keywords": ["キーワード1", "キーワード2", "キーワード3"],
  "language": "言語コード（ja/en等）"
}`, lyrics)

	text, err := c.generateContent(ctx, prompt)
	if err != nil {
		return nil, err
	}

	var analysis port.LyricsAnalysis
	if err := json.Unmarshal([]byte(cleanJSON(text)), &analysis); err != nil {
		return nil, fmt.Errorf("gemini: failed to parse lyrics analysis: %w", err)
	}
	return &analysis, nil
}

// ModerateContent はコンテンツの安全性をチェックする。
func (c *Client) ModerateContent(ctx context.Context, content string) (*port.ModerationResult, error) {
	prompt := fmt.Sprintf(`以下のテキストが不適切なコンテンツを含むかチェックしてください。

必ず有効な JSON オブジェクトのみを返してください。JSON 以外の文字は一切出力しないでください。

テキスト: %s

以下の形式の JSON オブジェクトを返してください:
{
  "is_harmful": true/false,
  "categories": ["該当カテゴリ（ヘイト、暴力、成人向け等）"],
  "confidence": 0.0-1.0,
  "suggestion": "修正提案（該当時のみ、不要なら空文字）"
}`, content)

	text, err := c.generateContent(ctx, prompt)
	if err != nil {
		return nil, err
	}

	var result port.ModerationResult
	if err := json.Unmarshal([]byte(cleanJSON(text)), &result); err != nil {
		return nil, fmt.Errorf("gemini: failed to parse moderation result: %w", err)
	}
	return &result, nil
}

// generateContent は Vertex AI Gemini REST API を呼び出してテキストを生成する。
func (c *Client) generateContent(ctx context.Context, prompt string) (string, error) {
	endpoint := fmt.Sprintf(
		"https://%s-aiplatform.googleapis.com/v1/projects/%s/locations/%s/publishers/google/models/%s:generateContent",
		c.location, c.projectID, c.location, c.modelID,
	)

	reqBody := map[string]any{
		"contents": []map[string]any{
			{
				"role": "user",
				"parts": []map[string]any{
					{"text": prompt},
				},
			},
		},
		"generationConfig": map[string]any{
			"temperature":     0.7,
			"maxOutputTokens": 1024,
		},
	}

	body, err := json.Marshal(reqBody)
	if err != nil {
		return "", err
	}

	req, err := http.NewRequestWithContext(ctx, http.MethodPost, endpoint, bytes.NewReader(body))
	if err != nil {
		return "", err
	}
	req.Header.Set("Content-Type", "application/json")

	resp, err := c.hc.Do(req)
	if err != nil {
		return "", fmt.Errorf("gemini: request failed: %w", err)
	}
	defer resp.Body.Close()

	respBody, err := io.ReadAll(resp.Body)
	if err != nil {
		return "", err
	}
	if resp.StatusCode != http.StatusOK {
		return "", fmt.Errorf("gemini: API error (status=%d): %s", resp.StatusCode, string(respBody))
	}

	return extractGeminiText(respBody)
}

type geminiResponse struct {
	Candidates []struct {
		Content struct {
			Parts []struct {
				Text string `json:"text"`
			} `json:"parts"`
		} `json:"content"`
	} `json:"candidates"`
}

func extractGeminiText(body []byte) (string, error) {
	var resp geminiResponse
	if err := json.Unmarshal(body, &resp); err != nil {
		return "", fmt.Errorf("gemini: failed to parse response: %w", err)
	}
	if len(resp.Candidates) == 0 || len(resp.Candidates[0].Content.Parts) == 0 {
		return "", fmt.Errorf("gemini: empty response")
	}
	return resp.Candidates[0].Content.Parts[0].Text, nil
}

// cleanJSON は Gemini が返す可能性のある ```json ... ``` を除去する。
func cleanJSON(s string) string {
	s = strings.TrimSpace(s)
	if strings.HasPrefix(s, "```") {
		lines := strings.Split(s, "\n")
		if len(lines) >= 2 {
			s = strings.Join(lines[1:], "\n")
		}
		s = strings.TrimSuffix(strings.TrimSpace(s), "```")
	}
	return strings.TrimSpace(s)
}
