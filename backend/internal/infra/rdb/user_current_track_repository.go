package rdb

import (
	"context"
	"errors"

	"github.com/google/uuid"
	"gorm.io/gorm"
	"gorm.io/gorm/clause"

	"hackathon/internal/domain/entity"
	domainerrs "hackathon/internal/domain/errs"
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

func (r *userCurrentTrackRepository) FindCurrentWithTimestampByUserID(ctx context.Context, userID string) (entity.UserCurrentTrack, bool, error) {
	var current model.UserCurrentTrack
	err := r.db.WithContext(ctx).
		Preload("Track").
		Where("user_id = ?", userID).
		First(&current).Error
	if errors.Is(err, gorm.ErrRecordNotFound) {
		return entity.UserCurrentTrack{}, false, nil
	}
	if err != nil {
		return entity.UserCurrentTrack{}, false, err
	}
	if current.Track == nil {
		return entity.UserCurrentTrack{}, false, nil
	}
	track := modelTrackToEntity(*current.Track)
	return entity.UserCurrentTrack{
		ID:        current.ID,
		UserID:    current.UserID,
		TrackID:   current.TrackID,
		Track:     &track,
		UpdatedAt: current.UpdatedAt,
	}, true, nil
}

func (r *userCurrentTrackRepository) Upsert(ctx context.Context, userID, externalTrackID string) (entity.UserCurrentTrack, bool, error) {
	internalTrackID, err := resolveCurrentTrackInternalID(r.db, ctx, externalTrackID)
	if err != nil {
		return entity.UserCurrentTrack{}, false, err
	}

	// Check if already set with the same track.
	var existing model.UserCurrentTrack
	findErr := r.db.WithContext(ctx).Where("user_id = ?", userID).First(&existing).Error
	isNew := errors.Is(findErr, gorm.ErrRecordNotFound)
	if findErr != nil && !isNew {
		return entity.UserCurrentTrack{}, false, findErr
	}

	if !isNew && existing.TrackID == internalTrackID {
		// Same track already set — idempotent
		if err2 := r.db.WithContext(ctx).Preload("Track").First(&existing, "user_id = ?", userID).Error; err2 != nil {
			return entity.UserCurrentTrack{}, false, err2
		}
		if existing.Track == nil {
			return entity.UserCurrentTrack{}, false, domainerrs.NotFound("track was not found")
		}
		track := modelTrackToEntity(*existing.Track)
		return entity.UserCurrentTrack{
			ID:        existing.ID,
			UserID:    existing.UserID,
			TrackID:   existing.TrackID,
			Track:     &track,
			UpdatedAt: existing.UpdatedAt,
		}, false, nil
	}

	row := model.UserCurrentTrack{
		ID:      uuid.NewString(),
		UserID:  userID,
		TrackID: internalTrackID,
	}
	if err := r.db.WithContext(ctx).Clauses(clause.OnConflict{
		Columns:   []clause.Column{{Name: "user_id"}},
		DoUpdates: clause.AssignmentColumns([]string{"track_id", "updated_at"}),
	}).Create(&row).Error; err != nil {
		return entity.UserCurrentTrack{}, false, err
	}

	var saved model.UserCurrentTrack
	if err := r.db.WithContext(ctx).Preload("Track").Where("user_id = ?", userID).First(&saved).Error; err != nil {
		return entity.UserCurrentTrack{}, false, err
	}
	if saved.Track == nil {
		return entity.UserCurrentTrack{}, false, domainerrs.NotFound("track was not found")
	}
	track := modelTrackToEntity(*saved.Track)
	return entity.UserCurrentTrack{
		ID:        saved.ID,
		UserID:    saved.UserID,
		TrackID:   saved.TrackID,
		Track:     &track,
		UpdatedAt: saved.UpdatedAt,
	}, isNew, nil
}

func (r *userCurrentTrackRepository) DeleteByUserID(ctx context.Context, userID string) error {
	result := r.db.WithContext(ctx).Where("user_id = ?", userID).Delete(&model.UserCurrentTrack{})
	if result.Error != nil {
		return result.Error
	}
	if result.RowsAffected == 0 {
		return domainerrs.NotFound("shared track was not found")
	}
	return nil
}
