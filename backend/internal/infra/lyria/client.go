package lyria

import (
	"bytes"
	"context"
	"encoding/base64"
	"encoding/json"
	"fmt"
	"io"
	"net/http"

	"golang.org/x/oauth2/google"

	"hackathon/internal/usecase/port"
)

// Client は Lyria API (Vertex AI Predict) REST クライアント。
// Application Default Credentials (ADC) で認証する。
type Client struct {
	projectID string
	location  string
	modelID   string
	hc        *http.Client
}

// NewClient は ADC を使って Lyria クライアントを生成する。
func NewClient(ctx context.Context, projectID, location, modelID string) (*Client, error) {
	hc, err := google.DefaultClient(ctx, "https://www.googleapis.com/auth/cloud-platform")
	if err != nil {
		return nil, fmt.Errorf("lyria: failed to create http client: %w", err)
	}
	return &Client{
		projectID: projectID,
		location:  location,
		modelID:   modelID,
		hc:        hc,
	}, nil
}

// GenerateSong は歌詞とパラメータから楽曲を生成する。
func (c *Client) GenerateSong(ctx context.Context, req *port.LyriaRequest) (*port.LyriaResponse, error) {
	endpoint := fmt.Sprintf(
		"https://%s-aiplatform.googleapis.com/v1/projects/%s/locations/%s/publishers/google/models/%s:predict",
		c.location, c.projectID, c.location, c.modelID,
	)

	prompt := buildPrompt(req)
	durationSec := req.DurationSec
	if durationSec <= 0 {
		durationSec = 45
	}

	reqBody := map[string]any{
		"instances": []map[string]any{
			{
				"prompt":        prompt,
				"duration_sec":  durationSec,
				"output_format": "wav",
			},
		},
		"parameters": map[string]any{
			"temperature": 0.3,
		},
	}

	body, err := json.Marshal(reqBody)
	if err != nil {
		return nil, err
	}

	httpReq, err := http.NewRequestWithContext(ctx, http.MethodPost, endpoint, bytes.NewReader(body))
	if err != nil {
		return nil, err
	}
	httpReq.Header.Set("Content-Type", "application/json")

	resp, err := c.hc.Do(httpReq)
	if err != nil {
		return nil, fmt.Errorf("lyria: request failed: %w", err)
	}
	defer resp.Body.Close()

	respBody, err := io.ReadAll(resp.Body)
	if err != nil {
		return nil, err
	}
	if resp.StatusCode != http.StatusOK {
		return nil, fmt.Errorf("lyria: API error (status=%d): %s", resp.StatusCode, string(respBody))
	}

	audioData, err := extractAudioData(respBody)
	if err != nil {
		return nil, err
	}

	return &port.LyriaResponse{
		AudioData:   audioData,
		Format:      "wav",
		DurationSec: durationSec,
		Metadata:    map[string]string{"prompt": prompt},
	}, nil
}

func buildPrompt(req *port.LyriaRequest) string {
	return fmt.Sprintf(`Generate a %s %s song with %s tempo.

Lyrics:
%s

Style notes:
- Mood: %s
- Genre: %s
- Create a memorable melody that matches the emotional tone of the lyrics
- Include appropriate instrumental accompaniment`,
		req.Mood, req.Genre, req.Tempo,
		req.Lyrics,
		req.Mood, req.Genre,
	)
}

type lyriaResponse struct {
	Predictions []struct {
		AudioContent string `json:"audio_content"` // base64 encoded WAV
	} `json:"predictions"`
}

func extractAudioData(body []byte) ([]byte, error) {
	var resp lyriaResponse
	if err := json.Unmarshal(body, &resp); err != nil {
		return nil, fmt.Errorf("lyria: failed to parse response: %w", err)
	}
	if len(resp.Predictions) == 0 || resp.Predictions[0].AudioContent == "" {
		return nil, fmt.Errorf("lyria: empty audio content in response")
	}
	audioData, err := base64.StdEncoding.DecodeString(resp.Predictions[0].AudioContent)
	if err != nil {
		return nil, fmt.Errorf("lyria: failed to decode audio content: %w", err)
	}
	return audioData, nil
}
