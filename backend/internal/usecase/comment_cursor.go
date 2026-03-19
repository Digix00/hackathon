package usecase

import (
	"encoding/base64"
	"encoding/json"
	"time"

	domainerrs "hackathon/internal/domain/errs"
	"hackathon/internal/domain/repository"
)

type commentCursorPayload struct {
	CreatedAt time.Time `json:"created_at"`
	ID        string    `json:"id"`
}

func parseCommentCursor(raw string) (*repository.CommentCursor, error) {
	if raw == "" {
		return nil, nil
	}

	decoded, err := base64.RawURLEncoding.DecodeString(raw)
	if err != nil {
		return nil, domainerrs.BadRequest("cursor is invalid")
	}

	var payload commentCursorPayload
	if err := json.Unmarshal(decoded, &payload); err != nil {
		return nil, domainerrs.BadRequest("cursor is invalid")
	}
	if payload.ID == "" || payload.CreatedAt.IsZero() {
		return nil, domainerrs.BadRequest("cursor is invalid")
	}

	return &repository.CommentCursor{
		CreatedAt: payload.CreatedAt,
		ID:        payload.ID,
	}, nil
}

func encodeCommentCursor(cursor *repository.CommentCursor) (string, error) {
	if cursor == nil {
		return "", nil
	}
	payload, err := json.Marshal(commentCursorPayload{
		CreatedAt: cursor.CreatedAt.UTC(),
		ID:        cursor.ID,
	})
	if err != nil {
		return "", err
	}
	return base64.RawURLEncoding.EncodeToString(payload), nil
}
