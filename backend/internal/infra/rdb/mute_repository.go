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
