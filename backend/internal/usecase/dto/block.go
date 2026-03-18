package dto

import "time"

type CreateBlockInput struct {
	BlockedUserID string
}

type BlockDTO struct {
	ID            string
	BlockedUserID string
	CreatedAt     time.Time
}
