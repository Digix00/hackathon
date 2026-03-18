package repository

import (
	"context"
	"time"

	"hackathon/internal/domain/entity"
)

type UpsertMusicConnectionParams struct {
	UserID           string
	Provider         string
	ProviderUserID   string
	ProviderUsername *string
	AccessToken      string
	RefreshToken     *string
	ExpiresAt        *time.Time
}

type MusicConnectionRepository interface {
	ListByUserID(ctx context.Context, userID string) ([]entity.MusicConnection, error)
	FindByUserIDAndProvider(ctx context.Context, userID, provider string) (entity.MusicConnection, error)
	Upsert(ctx context.Context, params UpsertMusicConnectionParams) (entity.MusicConnection, error)
	DeleteByUserIDAndProvider(ctx context.Context, userID, provider string) error
}
