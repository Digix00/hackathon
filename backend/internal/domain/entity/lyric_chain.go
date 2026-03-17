package entity

import (
	"time"

	"github.com/google/uuid"

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

// NewLyricChain は新規 LyricChain を生成する。
func NewLyricChain(threshold int) LyricChain {
	return LyricChain{
		ID:        uuid.NewString(),
		Status:    vo.LyricChainStatusPending,
		Threshold: threshold,
	}
}
