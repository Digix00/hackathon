package repository

import (
	"context"

	"hackathon/internal/domain/entity"
)

type UserCurrentTrackRepository interface {
	// FindCurrentByUserID returns (track, found, error)
	FindCurrentByUserID(ctx context.Context, userID string) (entity.TrackInfo, bool, error)
}
