package entity

import (
	"time"

	"github.com/google/uuid"
)

type Mute struct {
	ID           string
	UserID       string
	TargetUserID string
	CreatedAt    time.Time
}

func NewMute(userID, targetUserID string) Mute {
	return Mute{
		ID:           uuid.NewString(),
		UserID:       userID,
		TargetUserID: targetUserID,
		CreatedAt:    time.Now().UTC(),
	}
}
