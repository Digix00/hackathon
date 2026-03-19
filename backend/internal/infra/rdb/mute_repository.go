package rdb

import (
	"context"

	"gorm.io/gorm"

	"hackathon/internal/domain/entity"
	domainerrs "hackathon/internal/domain/errs"
	"hackathon/internal/domain/repository"
	"hackathon/internal/infra/rdb/model"
)

type muteRepository struct {
	db *gorm.DB
}

func NewMuteRepository(db *gorm.DB) repository.MuteRepository {
	return &muteRepository{db: db}
}

func (r *muteRepository) Create(ctx context.Context, mute entity.Mute) error {
	m := model.Mute{
		ID:           mute.ID,
		UserID:       mute.UserID,
		TargetUserID: mute.TargetUserID,
	}
	return r.db.WithContext(ctx).Create(&m).Error
}

func (r *muteRepository) Delete(ctx context.Context, userID, targetUserID string) error {
	result := r.db.WithContext(ctx).
		Where("user_id = ? AND target_user_id = ?", userID, targetUserID).
		Delete(&model.Mute{})
	if result.Error != nil {
		return result.Error
	}
	if result.RowsAffected == 0 {
		return domainerrs.NotFound("mute not found")
	}
	return nil
}

func (r *muteRepository) ExistsByUserAndTarget(ctx context.Context, userID, targetUserID string) (bool, error) {
	var count int64
	err := r.db.WithContext(ctx).
		Model(&model.Mute{}).
		Where("user_id = ? AND target_user_id = ?", userID, targetUserID).
		Count(&count).Error
	if err != nil {
		return false, err
	}
	return count > 0, nil
}

func (r *muteRepository) ListByUserID(ctx context.Context, userID string, limit int, cursor *repository.MuteCursor) ([]entity.Mute, *repository.MuteCursor, bool, error) {
	if limit <= 0 {
		limit = 20
	}
	if limit > 50 {
		limit = 50
	}

	query := r.db.WithContext(ctx).
		Model(&model.Mute{}).
		Where("user_id = ?", userID)

	if cursor != nil {
		query = query.Where(
			"(created_at < ? OR (created_at = ? AND id < ?))",
			cursor.CreatedAt, cursor.CreatedAt, cursor.ID,
		)
	}

	var rows []model.Mute
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

	mutes := make([]entity.Mute, len(rows))
	for i, row := range rows {
		mutes[i] = entity.Mute{
			ID:           row.ID,
			UserID:       row.UserID,
			TargetUserID: row.TargetUserID,
			CreatedAt:    row.CreatedAt,
		}
	}

	var nextCursor *repository.MuteCursor
	if hasMore && len(rows) > 0 {
		last := rows[len(rows)-1]
		nextCursor = &repository.MuteCursor{
			CreatedAt: last.CreatedAt,
			ID:        last.ID,
		}
	}

	return mutes, nextCursor, hasMore, nil
}
