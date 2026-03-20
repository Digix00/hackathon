package lyria

import (
	"context"
	"encoding/base64"
	"fmt"

	aiplatform "cloud.google.com/go/aiplatform/apiv1"
	"cloud.google.com/go/aiplatform/apiv1/aiplatformpb"
	"google.golang.org/api/option"
	"google.golang.org/protobuf/types/known/structpb"

	"hackathon/internal/usecase/port"
)

// Client は Vertex AI 経由で Lyria を呼び出す本番クライアント
type Client struct {
	projectID  string
	location   string
	modelID    string
	prediction *aiplatform.PredictionClient
}

// NewClient は Lyria クライアントを初期化する
func NewClient(ctx context.Context, projectID, location, modelID string) (*Client, error) {
	endpoint := fmt.Sprintf("%s-aiplatform.googleapis.com:443", location)
	prediction, err := aiplatform.NewPredictionClient(ctx, option.WithEndpoint(endpoint))
	if err != nil {
		return nil, fmt.Errorf("lyria.NewClient: failed to create prediction client: %w", err)
	}

	return &Client{
		projectID:  projectID,
		location:   location,
		modelID:    modelID,
		prediction: prediction,
	}, nil
}

// GenerateSong は歌詞とパラメータから楽曲を生成する
func (c *Client) GenerateSong(ctx context.Context, req *port.LyriaRequest) (*port.LyriaResponse, error) {
	prompt := c.buildPrompt(req)

	endpointPath := fmt.Sprintf(
		"projects/%s/locations/%s/publishers/google/models/%s",
		c.projectID, c.location, c.modelID,
	)

	params, err := structpb.NewStruct(map[string]interface{}{
		"temperature": 0.3,
	})
	if err != nil {
		return nil, fmt.Errorf("lyria.GenerateSong: failed to create params: %w", err)
	}

	instanceStruct, err := structpb.NewStruct(map[string]interface{}{
		"prompt":        prompt,
		"duration_sec":  req.DurationSec,
		"output_format": "wav",
	})
	if err != nil {
		return nil, fmt.Errorf("lyria.GenerateSong: failed to create instance: %w", err)
	}

	resp, err := c.prediction.Predict(ctx, &aiplatformpb.PredictRequest{
		Endpoint:   endpointPath,
		Instances:  []*structpb.Value{structpb.NewStructValue(instanceStruct)},
		Parameters: structpb.NewStructValue(params),
	})
	if err != nil {
		return nil, fmt.Errorf("lyria.GenerateSong: prediction failed: %w", err)
	}

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

func (c *Client) extractAudioData(resp *aiplatformpb.PredictResponse) ([]byte, error) {
	if len(resp.Predictions) == 0 {
		return nil, fmt.Errorf("lyria.extractAudioData: no predictions in response")
	}

	pred := resp.Predictions[0].GetStructValue()
	if pred == nil {
		return nil, fmt.Errorf("lyria.extractAudioData: prediction is not a struct")
	}

	audioField, ok := pred.Fields["audio"]
	if !ok {
		return nil, fmt.Errorf("lyria.extractAudioData: no 'audio' field in prediction")
	}

	encoded := audioField.GetStringValue()
	if encoded == "" {
		return nil, fmt.Errorf("lyria.extractAudioData: 'audio' field is empty")
	}

	audioData, err := base64.StdEncoding.DecodeString(encoded)
	if err != nil {
		return nil, fmt.Errorf("lyria.extractAudioData: failed to decode base64 audio: %w", err)
	}

	return audioData, nil
}
