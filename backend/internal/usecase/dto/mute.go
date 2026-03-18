package dto

import "time"

type CreateMuteInput struct {
	TargetUserID string
}

type MuteDTO struct {
	ID           string
	TargetUserID string
	CreatedAt    time.Time
}
