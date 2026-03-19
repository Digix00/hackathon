package repository

import (
	"context"
	"time"

	"hackathon/internal/domain/entity"
)

type MuteCursor struct {
	CreatedAt time.Time
	ID        string
}

type MuteRepository interface {
	Create(ctx context.Context, mute entity.Mute) error
	Delete(ctx context.Context, userID, targetUserID string) error
	ExistsByUserAndTarget(ctx context.Context, userID, targetUserID string) (bool, error)
	// ListByUserID returns mutes created by the given user with cursor-based pagination.
	ListByUserID(ctx context.Context, userID string, limit int, cursor *MuteCursor) ([]entity.Mute, *MuteCursor, bool, error)
}
