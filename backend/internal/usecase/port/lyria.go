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
