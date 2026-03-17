package vo

import domainerrs "hackathon/internal/domain/errs"

// GeneratedSongStatus は生成楽曲の状態。
type GeneratedSongStatus string

const (
	GeneratedSongStatusProcessing GeneratedSongStatus = "processing"
	GeneratedSongStatusCompleted  GeneratedSongStatus = "completed"
	GeneratedSongStatusFailed     GeneratedSongStatus = "failed"
)

// NewGeneratedSongStatus は文字列を GeneratedSongStatus に変換する。無効値の場合は BadRequest を返す。
func NewGeneratedSongStatus(s string) (GeneratedSongStatus, error) {
	switch GeneratedSongStatus(s) {
	case GeneratedSongStatusProcessing, GeneratedSongStatusCompleted, GeneratedSongStatusFailed:
		return GeneratedSongStatus(s), nil
	}
	return "", domainerrs.BadRequest("invalid generated_song_status: " + s)
}
