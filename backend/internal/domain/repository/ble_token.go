package repository

import (
	"context"

	"hackathon/internal/domain/entity"
)

type BleTokenRepository interface {
	// Create persists a new BLE token.
	Create(ctx context.Context, token entity.BleToken) error

	// InvalidateByUserID immediately expires all active tokens for the user
	// by setting valid_to to now. Used for token rotation on re-issuance.
	InvalidateByUserID(ctx context.Context, userID string) error

	// FindLatestByUserID returns the most recently issued token for the user,
	// regardless of its validity. Callers are responsible for checking expiry.
	FindLatestByUserID(ctx context.Context, userID string) (entity.BleToken, error)

	// FindByToken returns the token record based on the UUID string emitted via BLE.
	FindByToken(ctx context.Context, tokenStr string) (entity.BleToken, error)
}
