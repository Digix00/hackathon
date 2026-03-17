package vo

// GeneratedSongStatus は生成楽曲の状態。
type GeneratedSongStatus string

const (
	GeneratedSongStatusProcessing GeneratedSongStatus = "processing"
	GeneratedSongStatusCompleted  GeneratedSongStatus = "completed"
	GeneratedSongStatusFailed     GeneratedSongStatus = "failed"
)
