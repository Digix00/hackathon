package repository

import (
	"context"
	"time"

	"hackathon/internal/domain/entity"
)

type TrackFavoriteCursor struct {
	CreatedAt time.Time
	ID        string
}

type TrackFavoriteRepository interface {
	// Upsert adds a track to the user's favorites.
	// Returns (trackFavorite, isNew, error). If already favorited, isNew=false.
	Upsert(ctx context.Context, userID, trackID string) (entity.TrackFavorite, bool, error)

	// DeleteByUserIDAndTrackID removes a track from the user's favorites.
	DeleteByUserIDAndTrackID(ctx context.Context, userID, trackID string) error

	// ListByUserID returns the user's favorited tracks with cursor-based pagination.
	ListByUserID(ctx context.Context, userID string, limit int, cursor *TrackFavoriteCursor) ([]entity.TrackFavorite, *TrackFavoriteCursor, bool, error)
}

type PlaylistFavoriteCursor struct {
	CreatedAt time.Time
	ID        string
}
