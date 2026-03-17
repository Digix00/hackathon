package entity

import (
	"time"

	"hackathon/internal/domain/vo"
)

// LyricChain は複数ユーザーが歌詞を積み上げるチェーン。
type LyricChain struct {
	ID               string
	Status           vo.LyricChainStatus
	ParticipantCount int
	Threshold        int
	CreatedAt        time.Time
	CompletedAt      *time.Time
}

// LyricEntry は歌詞チェーンへの1ユーザー分の投稿。
type LyricEntry struct {
	ID          string
	ChainID     string
	UserID      string
	EncounterID string
	Content     string
	SequenceNum int
	CreatedAt   time.Time
}

// GeneratedSong は Lyria で生成された楽曲。
type GeneratedSong struct {
	ID          string
	ChainID     string
	Title       *string
	AudioURL    *string
	DurationSec *int
	Mood        *string
	Genre       *string
	Status      vo.GeneratedSongStatus
	GeneratedAt *time.Time
}

// OutboxLyriaJob は Lyria 生成ジョブのアウトボックス。
type OutboxLyriaJob struct {
	ID           string
	ChainID      string
	Status       vo.OutboxLyriaJobStatus
	RetryCount   int
	ErrorMessage *string
	CreatedAt    time.Time
	ProcessedAt  *time.Time
}
