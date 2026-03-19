package entity

import (
	"time"

	"github.com/google/uuid"
)

type CommentUser struct {
	ID          string
	DisplayName string
	AvatarURL   *string
}

type Comment struct {
	ID          string
	EncounterID string
	User        CommentUser
	Content     string
	CreatedAt   time.Time
}

func NewComment(encounterID string, user User, content string) Comment {
	displayName := ""
	if user.Name != nil {
		displayName = *user.Name
	}
	return Comment{
		ID:          uuid.NewString(),
		EncounterID: encounterID,
		User: CommentUser{
			ID:          user.ID,
			DisplayName: displayName,
			AvatarURL:   user.AvatarURL,
		},
		Content:   content,
		CreatedAt: time.Now().UTC(),
	}
}
