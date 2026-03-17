package repository

import (
	"context"
	"time"

	"hackathon/internal/domain/entity"
	"hackathon/internal/domain/vo"
)

type EncounterCursor struct {
	OccurredAt time.Time
	ID         string
}

type EncounterRepository interface {
	CountByUserID(ctx context.Context, userID string) (int64, error)

	FindRecentByUsersAndType(
		ctx context.Context,
		userID1 string,
		userID2 string,
		encounterType vo.EncounterType,
		occurredAt time.Time,
		window time.Duration,
	) (entity.Encounter, bool, error)

	Create(ctx context.Context, encounter entity.Encounter) (entity.Encounter, error)

	CreateTracksFromCurrent(ctx context.Context, encounterID string, userIDs []string) error

	ListByUserID(ctx context.Context, userID string, limit int, cursor *EncounterCursor) ([]entity.Encounter, *EncounterCursor, bool, error)

	FindByID(ctx context.Context, encounterID string) (entity.Encounter, error)

	ListTracksByEncounterIDs(ctx context.Context, encounterIDs []string) (map[string][]entity.TrackInfo, error)

	GetReadStatusByEncounterIDs(ctx context.Context, userID string, encounterIDs []string) (map[string]bool, error)

	ExistsByUsersAndTypeOnDate(ctx context.Context, userID1, userID2 string, encounterType vo.EncounterType, date time.Time) (bool, error)

	IncrementDailyCountWithLimit(ctx context.Context, userID string, date time.Time, limit int) (int, error)

	CreateWithRateLimit(ctx context.Context, encounter entity.Encounter, userIDsForTracks []string, dailyLimitUserID string, date time.Time, limit int) (entity.Encounter, error)
}
