package repository

import "context"

type BlockRepository interface {
	ExistsBetween(ctx context.Context, userID1, userID2 string) (bool, error)
}
