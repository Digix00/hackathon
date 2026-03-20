package lyria

import (
	"context"

	"hackathon/internal/usecase/port"
)

// MockClient は開発環境用のモック Lyria クライアント
type MockClient struct{}

// NewMockClient はモッククライアントを返す
func NewMockClient() *MockClient {
	return &MockClient{}
}

// GenerateSong は固定の最小 WAV ファイルを返す（44バイトの無音WAV）
func (m *MockClient) GenerateSong(_ context.Context, req *port.LyriaRequest) (*port.LyriaResponse, error) {
	// 最小の有効な WAV ファイル（無音・44バイト）
	wavHeader := []byte{
		0x52, 0x49, 0x46, 0x46, // "RIFF"
		0x24, 0x00, 0x00, 0x00, // チャンクサイズ (36 bytes)
		0x57, 0x41, 0x56, 0x45, // "WAVE"
		0x66, 0x6D, 0x74, 0x20, // "fmt "
		0x10, 0x00, 0x00, 0x00, // fmt チャンクサイズ (16)
		0x01, 0x00, // PCM フォーマット
		0x01, 0x00, // モノラル
		0x44, 0xAC, 0x00, 0x00, // サンプルレート 44100
		0x88, 0x58, 0x01, 0x00, // バイトレート
		0x02, 0x00, // ブロックアライン
		0x10, 0x00, // ビット深度 16
		0x64, 0x61, 0x74, 0x61, // "data"
		0x00, 0x00, 0x00, 0x00, // データサイズ (0 = 無音)
	}

	duration := req.DurationSec
	if duration <= 0 {
		duration = 45
	}

	return &port.LyriaResponse{
		AudioData:   wavHeader,
		Format:      "wav",
		DurationSec: duration,
		Metadata: map[string]string{
			"mock": "true",
		},
	}, nil
}
