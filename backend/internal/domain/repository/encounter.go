package repository

import "context"

type EncounterRepository interface {
	CountByUserID(ctx context.Context, userID string) (int64, error)
}
