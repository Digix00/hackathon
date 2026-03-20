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
	Mood           string   `json:"mood"`            // メインのムード
	SecondaryMoods []string `json:"secondary_moods"` // サブムード
	Genre          string   `json:"genre"`           // 推奨ジャンル
	Tempo          string   `json:"tempo"`           // 推奨テンポ
	SuggestedTitle string   `json:"suggested_title"` // タイトル案
	Keywords       []string `json:"keywords"`        // キーワード
	Language       string   `json:"language"`        // 言語（ja, en, etc.）
}

// ModerationResult はコンテンツモデレーション結果
type ModerationResult struct {
	IsHarmful  bool     `json:"is_harmful"`
	Categories []string `json:"categories"` // 該当したカテゴリ
	Confidence float64  `json:"confidence"`
	Suggestion string   `json:"suggestion"` // 修正提案（該当時）
}
