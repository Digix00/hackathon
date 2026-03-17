package port

import "context"

// LyriaClient は楽曲生成AIとの連携インターフェース。
type LyriaClient interface {
	// GenerateSong は歌詞とパラメータから楽曲を生成する。
	GenerateSong(ctx context.Context, req *LyriaRequest) (*LyriaResponse, error)
}

// LyriaRequest は楽曲生成リクエスト。
type LyriaRequest struct {
	Lyrics      string
	Mood        string // "melancholic", "upbeat", "nostalgic", "energetic", "peaceful", "romantic"
	Genre       string // "j-pop", "rock", "ballad", "electronic", "acoustic"
	Tempo       string // "slow", "medium", "fast"
	DurationSec int
	Title       string
}

// LyriaResponse は楽曲生成結果。
type LyriaResponse struct {
	AudioData   []byte
	Format      string // "wav" or "mp3"
	DurationSec int
	Metadata    map[string]string
}
