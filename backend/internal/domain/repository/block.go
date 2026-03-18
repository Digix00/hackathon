package repository

import (
	"context"

	"hackathon/internal/domain/entity"
)

type BlockRepository interface {
	Create(ctx context.Context, block entity.Block) error
	Delete(ctx context.Context, blockerUserID, blockedUserID string) error
	ExistsByBlockerAndBlocked(ctx context.Context, blockerUserID, blockedUserID string) (bool, error)
	ExistsBetween(ctx context.Context, userID1, userID2 string) (bool, error)
	// ListBlockedUserIDs returns a set of user IDs that are blocked between requester and targets.
	ListBlockedUserIDs(ctx context.Context, requesterID string, targetUserIDs []string) (map[string]bool, error)
}
