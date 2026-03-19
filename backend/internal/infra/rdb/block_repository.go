package rdb

import (
	"context"

	"gorm.io/gorm"

	"hackathon/internal/domain/entity"
	domainerrs "hackathon/internal/domain/errs"
	"hackathon/internal/domain/repository"
	"hackathon/internal/infra/rdb/model"
)

type blockRepository struct {
	db *gorm.DB
}

func NewBlockRepository(db *gorm.DB) repository.BlockRepository {
	return &blockRepository{db: db}
}

func (r *blockRepository) Create(ctx context.Context, block entity.Block) error {
	m := model.Block{
		ID:            block.ID,
		BlockerUserID: block.BlockerUserID,
		BlockedUserID: block.BlockedUserID,
	}
	return r.db.WithContext(ctx).Create(&m).Error
}

func (r *blockRepository) Delete(ctx context.Context, blockerUserID, blockedUserID string) error {
	result := r.db.WithContext(ctx).
		Where("blocker_user_id = ? AND blocked_user_id = ?", blockerUserID, blockedUserID).
		Delete(&model.Block{})
	if result.Error != nil {
		return result.Error
	}
	if result.RowsAffected == 0 {
		return domainerrs.NotFound("block not found")
	}
	return nil
}

func (r *blockRepository) ExistsByBlockerAndBlocked(ctx context.Context, blockerUserID, blockedUserID string) (bool, error) {
	var count int64
	err := r.db.WithContext(ctx).
		Model(&model.Block{}).
		Where("blocker_user_id = ? AND blocked_user_id = ?", blockerUserID, blockedUserID).
		Count(&count).Error
	if err != nil {
		return false, err
	}
	return count > 0, nil
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

func (r *blockRepository) ListByBlockerUserID(ctx context.Context, blockerUserID string, limit int, cursor *repository.BlockCursor) ([]entity.Block, *repository.BlockCursor, bool, error) {
	if limit <= 0 {
		limit = 20
	}
	if limit > 50 {
		limit = 50
	}

	query := r.db.WithContext(ctx).
		Model(&model.Block{}).
		Where("blocker_user_id = ?", blockerUserID)

	if cursor != nil {
		query = query.Where(
			"(created_at < ? OR (created_at = ? AND id < ?))",
			cursor.CreatedAt, cursor.CreatedAt, cursor.ID,
		)
	}

	var rows []model.Block
	if err := query.
		Order("created_at DESC, id DESC").
		Limit(limit + 1).
		Find(&rows).Error; err != nil {
		return nil, nil, false, err
	}

	hasMore := len(rows) > limit
	if hasMore {
		rows = rows[:limit]
	}

	blocks := make([]entity.Block, len(rows))
	for i, row := range rows {
		blocks[i] = entity.Block{
			ID:            row.ID,
			BlockerUserID: row.BlockerUserID,
			BlockedUserID: row.BlockedUserID,
			CreatedAt:     row.CreatedAt,
		}
	}

	var nextCursor *repository.BlockCursor
	if hasMore && len(rows) > 0 {
		last := rows[len(rows)-1]
		nextCursor = &repository.BlockCursor{
			CreatedAt: last.CreatedAt,
			ID:        last.ID,
		}
	}

	return blocks, nextCursor, hasMore, nil
}
