package repository

import (
	"context"

	"hackathon/internal/domain/entity"
)

type UserSettingsRepository interface {
	FindByUserID(ctx context.Context, userID string) (entity.UserSettings, error)
	Create(ctx context.Context, settings *entity.UserSettings) error
	Update(ctx context.Context, settings *entity.UserSettings) error
}
