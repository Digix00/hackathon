package vo

// LyricChainStatus は歌詞チェーンの状態。
type LyricChainStatus string

const (
	LyricChainStatusPending    LyricChainStatus = "pending"
	LyricChainStatusGenerating LyricChainStatus = "generating"
	LyricChainStatusCompleted  LyricChainStatus = "completed"
	LyricChainStatusFailed     LyricChainStatus = "failed"
)
