package dto

import "time"

type CommentDTO struct {
	ID            string
	EncounterID   string
	UserID        string
	UserName      string
	UserAvatarURL *string
	Content       string
	CreatedAt     time.Time
}

type ListCommentsOutput struct {
	Comments   []CommentDTO
	NextCursor string
	HasMore    bool
}
