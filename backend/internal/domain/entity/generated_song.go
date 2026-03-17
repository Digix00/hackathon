package entity

import (
	"time"

	"github.com/google/uuid"

	"hackathon/internal/domain/vo"
)

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

// NewGeneratedSong は processing 状態の GeneratedSong を生成する。
func NewGeneratedSong(chainID string) GeneratedSong {
	return GeneratedSong{
		ID:      uuid.NewString(),
		ChainID: chainID,
		Status:  vo.GeneratedSongStatusProcessing,
	}
}
