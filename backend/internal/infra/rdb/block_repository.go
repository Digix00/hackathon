package rdb

import (
	"context"

	"gorm.io/gorm"

	"hackathon/internal/domain/repository"
	"hackathon/internal/infra/rdb/model"
)

type blockRepository struct {
	db *gorm.DB
}

func NewBlockRepository(db *gorm.DB) repository.BlockRepository {
	return &blockRepository{db: db}
}

func (r *blockRepository) ExistsBetween(ctx context.Context, userID1, userID2 string) (bool, error) {
	var count int64
	err := r.db.WithContext(ctx).
		Model(&model.Block{}).
		Where(
			"(blocker_user_id = ? AND blocked_user_id = ?) OR (blocker_user_id = ? AND blocked_user_id = ?)",
			userID1, userID2, userID2, userID1,
		).
		Count(&count).Error
	if err != nil {
		return false, err
	}
	return count > 0, nil
}

func (r *blockRepository) ListBlockedUserIDs(ctx context.Context, requesterID string, targetUserIDs []string) (map[string]bool, error) {
	if len(targetUserIDs) == 0 {
		return map[string]bool{}, nil
	}

	var blocks []model.Block
	err := r.db.WithContext(ctx).
		Where(
			"(blocker_user_id = ? AND blocked_user_id IN ?) OR (blocked_user_id = ? AND blocker_user_id IN ?)",
			requesterID, targetUserIDs, requesterID, targetUserIDs,
		).
		Find(&blocks).Error
	if err != nil {
		return nil, err
	}

	blocked := make(map[string]bool, len(blocks))
	for _, b := range blocks {
		if b.BlockerUserID == requesterID {
			blocked[b.BlockedUserID] = true
		} else if b.BlockedUserID == requesterID {
			blocked[b.BlockerUserID] = true
		}
	}
	return blocked, nil
}
