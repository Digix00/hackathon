package repository

import (
	"context"
	"time"

	"hackathon/internal/domain/entity"
)

type UserCurrentTrackRepository interface {
	// FindCurrentByUserID returns (track, found, error)
	FindCurrentByUserID(ctx context.Context, userID string) (entity.TrackInfo, bool, error)

	// FindCurrentWithTimestampByUserID returns the full UserCurrentTrack including updated_at.
	FindCurrentWithTimestampByUserID(ctx context.Context, userID string) (entity.UserCurrentTrack, bool, error)

	// Upsert sets or replaces the user's current shared track.
	// Returns (userCurrentTrack, isNew, error).
	Upsert(ctx context.Context, userID, trackID string) (entity.UserCurrentTrack, bool, error)

	// DeleteByUserID removes the user's current shared track.
	DeleteByUserID(ctx context.Context, userID string) error
}

type TrackCatalogRepository interface {
	Upsert(ctx context.Context, track entity.TrackInfo) (entity.TrackInfo, error)
	FindByProviderAndExternalID(ctx context.Context, provider, externalID string) (entity.TrackInfo, error)
	FindByID(ctx context.Context, id string) (entity.TrackInfo, error)
}

type UserTrackCursor struct {
	CreatedAt time.Time
	ID        string
}

type UserTrackRepository interface {
	// Upsert adds a track to the user's saved tracks.
	// Returns (userTrack, isNew, error). If the track is already saved, isNew=false.
	Upsert(ctx context.Context, userID, trackID string) (entity.UserTrack, bool, error)

	// ListByUserID returns the user's saved tracks with cursor-based pagination.
	ListByUserID(ctx context.Context, userID string, limit int, cursor *UserTrackCursor) ([]entity.UserTrack, *UserTrackCursor, bool, error)

	// DeleteByUserIDAndTrackID soft-deletes a saved track.
	DeleteByUserIDAndTrackID(ctx context.Context, userID, trackID string) error
}
