package entity

import (
	"time"

	"hackathon/internal/domain/vo"
)

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
