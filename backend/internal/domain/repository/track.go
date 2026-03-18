package repository

import (
	"context"

	"hackathon/internal/domain/entity"
)

type UserCurrentTrackRepository interface {
	// FindCurrentByUserID returns (track, found, error)
	FindCurrentByUserID(ctx context.Context, userID string) (entity.TrackInfo, bool, error)
}

type TrackCatalogRepository interface {
	Upsert(ctx context.Context, track entity.TrackInfo) (entity.TrackInfo, error)
	FindByProviderAndExternalID(ctx context.Context, provider, externalID string) (entity.TrackInfo, error)
}
