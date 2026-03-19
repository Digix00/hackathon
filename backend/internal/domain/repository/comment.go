package repository

import (
	"context"
	"time"

	"hackathon/internal/domain/entity"
)

type CommentCursor struct {
	CreatedAt time.Time
	ID        string
}

type CommentRepository interface {
	Create(ctx context.Context, comment entity.Comment) error
	FindByID(ctx context.Context, id string) (entity.Comment, error)
	ListByEncounterID(ctx context.Context, encounterID string, limit int, cursor *CommentCursor) ([]entity.Comment, *CommentCursor, bool, error)
	SoftDelete(ctx context.Context, id string) error
}
