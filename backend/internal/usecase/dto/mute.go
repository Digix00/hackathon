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

type MuteListDTO struct {
	Mutes      []MuteDTO
	NextCursor *string
	HasMore    bool
}
