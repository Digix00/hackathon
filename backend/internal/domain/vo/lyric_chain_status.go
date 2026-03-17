package vo

import domainerrs "hackathon/internal/domain/errs"

// LyricChainStatus は歌詞チェーンの状態。
type LyricChainStatus string

const (
	LyricChainStatusPending    LyricChainStatus = "pending"
	LyricChainStatusGenerating LyricChainStatus = "generating"
	LyricChainStatusCompleted  LyricChainStatus = "completed"
	LyricChainStatusFailed     LyricChainStatus = "failed"
)

// NewLyricChainStatus は文字列を LyricChainStatus に変換する。無効値の場合は BadRequest を返す。
func NewLyricChainStatus(s string) (LyricChainStatus, error) {
	switch LyricChainStatus(s) {
	case LyricChainStatusPending, LyricChainStatusGenerating, LyricChainStatusCompleted, LyricChainStatusFailed:
		return LyricChainStatus(s), nil
	}
	return "", domainerrs.BadRequest("invalid lyric_chain_status: " + s)
}
