package repository

import (
	"context"
	"time"

	"hackathon/internal/domain/entity"
)

type BlockCursor struct {
	CreatedAt time.Time
	ID        string
}

type BlockRepository interface {
	Create(ctx context.Context, block entity.Block) error
	Delete(ctx context.Context, blockerUserID, blockedUserID string) error
	ExistsByBlockerAndBlocked(ctx context.Context, blockerUserID, blockedUserID string) (bool, error)
	ExistsBetween(ctx context.Context, userID1, userID2 string) (bool, error)
	// ListBlockedUserIDs returns a set of user IDs that are blocked between requester and targets.
	ListBlockedUserIDs(ctx context.Context, requesterID string, targetUserIDs []string) (map[string]bool, error)
	// ListByBlockerUserID returns blocks created by the given user with cursor-based pagination.
	ListByBlockerUserID(ctx context.Context, blockerUserID string, limit int, cursor *BlockCursor) ([]entity.Block, *BlockCursor, bool, error)
}
