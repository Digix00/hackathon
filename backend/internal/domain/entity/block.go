package entity

import (
	"time"

	"github.com/google/uuid"
)

type Block struct {
	ID            string
	BlockerUserID string
	BlockedUserID string
	CreatedAt     time.Time
}

func NewBlock(blockerUserID, blockedUserID string) Block {
	return Block{
		ID:            uuid.NewString(),
		BlockerUserID: blockerUserID,
		BlockedUserID: blockedUserID,
		CreatedAt:     time.Now().UTC(),
	}
}
