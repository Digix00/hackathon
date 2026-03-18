package rdb

import (
	"context"
	"errors"

	"gorm.io/gorm"

	"hackathon/internal/domain/entity"
	"hackathon/internal/domain/repository"
	"hackathon/internal/infra/rdb/model"
)

type userCurrentTrackRepository struct {
	db *gorm.DB
}

func NewUserCurrentTrackRepository(db *gorm.DB) repository.UserCurrentTrackRepository {
	return &userCurrentTrackRepository{db: db}
}

func (r *userCurrentTrackRepository) FindCurrentByUserID(ctx context.Context, userID string) (entity.TrackInfo, bool, error) {
	var current model.UserCurrentTrack
	err := r.db.WithContext(ctx).
		Preload("Track").
		Where("user_id = ?", userID).
		First(&current).Error
	if errors.Is(err, gorm.ErrRecordNotFound) {
		return entity.TrackInfo{}, false, nil
	}
	if err != nil {
		return entity.TrackInfo{}, false, err
	}
	if current.Track == nil {
		return entity.TrackInfo{}, false, nil
	}
	return modelTrackToEntity(*current.Track), true, nil
}
