package lyria

import (
	"context"

	"hackathon/internal/usecase/port"
)

// MockClient は開発環境で使うモック実装。固定の空音声データを返す。
type MockClient struct{}

// GenerateSong はモックの空音声データを返す。
func (m *MockClient) GenerateSong(_ context.Context, req *port.LyriaRequest) (*port.LyriaResponse, error) {
	durationSec := req.DurationSec
	if durationSec <= 0 {
		durationSec = 45
	}
	// 最小限の WAV ヘッダー（44バイト）を持つ無音ファイル
	sampleAudio := makeEmptyWAV(durationSec)
	return &port.LyriaResponse{
		AudioData:   sampleAudio,
		Format:      "wav",
		DurationSec: durationSec,
		Metadata:    map[string]string{"mock": "true"},
	}, nil
}

// makeEmptyWAV は指定秒数の無音 WAV バイナリを生成する（44100Hz, 16bit, mono）。
func makeEmptyWAV(durationSec int) []byte {
	sampleRate := 44100
	numSamples := sampleRate * durationSec
	dataSize := numSamples * 2 // 16bit = 2 bytes/sample
	fileSize := 36 + dataSize

	header := make([]byte, 44)
	copy(header[0:4], "RIFF")
	putUint32LE(header[4:8], uint32(fileSize))
	copy(header[8:12], "WAVE")
	copy(header[12:16], "fmt ")
	putUint32LE(header[16:20], 16)                 // PCM chunk size
	putUint16LE(header[20:22], 1)                  // PCM format
	putUint16LE(header[22:24], 1)                  // mono
	putUint32LE(header[24:28], uint32(sampleRate)) // sample rate
	putUint32LE(header[28:32], uint32(sampleRate*2)) // byte rate
	putUint16LE(header[32:34], 2)                    // block align
	putUint16LE(header[34:36], 16)                   // bits per sample
	copy(header[36:40], "data")
	putUint32LE(header[40:44], uint32(dataSize))

	result := make([]byte, 44+dataSize)
	copy(result, header)
	// remaining bytes are zero = silence
	return result
}

func putUint32LE(b []byte, v uint32) {
	b[0] = byte(v)
	b[1] = byte(v >> 8)
	b[2] = byte(v >> 16)
	b[3] = byte(v >> 24)
}

func putUint16LE(b []byte, v uint16) {
	b[0] = byte(v)
	b[1] = byte(v >> 8)
}
