package repository

import (
	"context"

	"hackathon/internal/domain/entity"
)

type BleTokenRepository interface {
	// Create persists a new BLE token. If a user only needs one active token,
	// older tokens can be deleted or soft-deleted periodically by a worker.
	Create(ctx context.Context, token entity.BleToken) error

	// FindLatestByUserID returns the most recently issued token for the user,
	// regardless of its validity. Callers are responsible for checking expiry.
	FindLatestByUserID(ctx context.Context, userID string) (entity.BleToken, error)

	// FindByToken returns the token record based on the UUID string emitted via BLE.
	FindByToken(ctx context.Context, tokenStr string) (entity.BleToken, error)
}
