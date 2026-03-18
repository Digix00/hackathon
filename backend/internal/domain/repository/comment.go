package repository

import (
	"context"

	"hackathon/internal/domain/entity"
)

type CommentRepository interface {
	Create(ctx context.Context, comment entity.Comment) error
	FindByID(ctx context.Context, id string) (entity.Comment, error)
	ListByEncounterID(ctx context.Context, encounterID string, limit int, cursor string) ([]entity.Comment, string, bool, error)
	SoftDelete(ctx context.Context, id string) error
}
