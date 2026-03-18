package repository

import "context"

type BlockRepository interface {
	ExistsBetween(ctx context.Context, userID1, userID2 string) (bool, error)
	// ListBlockedUserIDs returns a set of user IDs that are blocked between requester and targets.
	ListBlockedUserIDs(ctx context.Context, requesterID string, targetUserIDs []string) (map[string]bool, error)
}
