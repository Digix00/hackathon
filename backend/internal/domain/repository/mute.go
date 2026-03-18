package repository

import (
	"context"

	"hackathon/internal/domain/entity"
)

type MuteRepository interface {
	Create(ctx context.Context, mute entity.Mute) error
	Delete(ctx context.Context, userID, targetUserID string) error
	ExistsByUserAndTarget(ctx context.Context, userID, targetUserID string) (bool, error)
}
