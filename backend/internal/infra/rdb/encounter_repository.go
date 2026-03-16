package rdb

import (
	"context"

	"gorm.io/gorm"

	"hackathon/internal/domain/repository"
	"hackathon/internal/infra/rdb/model"
)

type encounterRepository struct {
	db *gorm.DB
}

func NewEncounterRepository(db *gorm.DB) repository.EncounterRepository {
	return &encounterRepository{db: db}
}

func (r *encounterRepository) CountByUserID(ctx context.Context, userID string) (int64, error) {
	var count int64
	err := r.db.WithContext(ctx).
		Model(&model.Encounter{}).
		Where("user_id1 = ? OR user_id2 = ?", userID, userID).
		Count(&count).Error
	if err != nil {
		return 0, err
	}
	return count, nil
}
