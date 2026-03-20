package rdb

import (
	"context"
	"errors"

	"github.com/google/uuid"
	"go.uber.org/zap"
	"gorm.io/gorm"

	"hackathon/internal/domain/entity"
	domainerrs "hackathon/internal/domain/errs"
	"hackathon/internal/domain/repository"
	"hackathon/internal/infra/rdb/model"
)

type trackFavoriteRepository struct {
	log *zap.Logger
	db  *gorm.DB
}

func NewTrackFavoriteRepository(log *zap.Logger, db *gorm.DB) repository.TrackFavoriteRepository {
	return &trackFavoriteRepository{log: log, db: db}
}

func (r *trackFavoriteRepository) Upsert(ctx context.Context, userID, externalTrackID string) (entity.TrackFavorite, bool, error) {
	internalTrackID, err := resolveCurrentTrackInternalID(r.db, ctx, externalTrackID)
	if err != nil {
		return entity.TrackFavorite{}, false, err
	}

	// Check if an active record already exists.
	var existing model.TrackFavorite
	err = r.db.WithContext(ctx).
		Preload("Track").
		Where("user_id = ? AND track_id = ? AND deleted_at IS NULL", userID, internalTrackID).
		First(&existing).Error
	if err == nil {
		return modelToEntityTrackFavorite(existing), false, nil
	}
	if !errors.Is(err, gorm.ErrRecordNotFound) {
		return entity.TrackFavorite{}, false, err
	}

	// Create new record.
	m := model.TrackFavorite{
		ID:      uuid.NewString(),
		UserID:  userID,
		TrackID: internalTrackID,
	}
	if err := r.db.WithContext(ctx).Create(&m).Error; err != nil {
		if isUniqueConstraintViolation(err) {
			// Race condition: another request created it first.
			var found model.TrackFavorite
			if err2 := r.db.WithContext(ctx).Preload("Track").
				Where("user_id = ? AND track_id = ? AND deleted_at IS NULL", userID, internalTrackID).
				First(&found).Error; err2 != nil {
				return entity.TrackFavorite{}, false, err2
			}
			return modelToEntityTrackFavorite(found), false, nil
		}
		return entity.TrackFavorite{}, false, err
	}

	// Reload with track preloaded.
	if err := r.db.WithContext(ctx).Preload("Track").First(&m, "id = ?", m.ID).Error; err != nil {
		return entity.TrackFavorite{}, false, err
	}
	return modelToEntityTrackFavorite(m), true, nil
}

func (r *trackFavoriteRepository) DeleteByUserIDAndTrackID(ctx context.Context, userID, externalTrackID string) error {
	internalTrackID, err := resolveCurrentTrackInternalID(r.db, ctx, externalTrackID)
	if err != nil {
		return err
	}

	result := r.db.WithContext(ctx).
		Where("user_id = ? AND track_id = ? AND deleted_at IS NULL", userID, internalTrackID).
		Delete(&model.TrackFavorite{})
	if result.Error != nil {
		return result.Error
	}
	if result.RowsAffected == 0 {
		return domainerrs.NotFound("track favorite was not found")
	}
	return nil
}

func (r *trackFavoriteRepository) ListByUserID(ctx context.Context, userID string, limit int, cursor *repository.TrackFavoriteCursor) ([]entity.TrackFavorite, *repository.TrackFavoriteCursor, bool, error) {
	if limit <= 0 {
		limit = 20
	}
	if limit > 50 {
		limit = 50
	}

	query := r.db.WithContext(ctx).
		Preload("Track").
		Where("user_id = ? AND deleted_at IS NULL", userID)

	if cursor != nil {
		query = query.Where(
			"(created_at < ? OR (created_at = ? AND id < ?))",
			cursor.CreatedAt, cursor.CreatedAt, cursor.ID,
		)
	}

	// Fetch one extra to determine hasMore.
	var rows []model.TrackFavorite
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

	favs := make([]entity.TrackFavorite, len(rows))
	for i, row := range rows {
		favs[i] = modelToEntityTrackFavorite(row)
	}

	var nextCursor *repository.TrackFavoriteCursor
	if hasMore && len(rows) > 0 {
		last := rows[len(rows)-1]
		nextCursor = &repository.TrackFavoriteCursor{
			CreatedAt: last.CreatedAt,
			ID:        last.ID,
		}
	}

	return favs, nextCursor, hasMore, nil
}

func modelToEntityTrackFavorite(m model.TrackFavorite) entity.TrackFavorite {
	fav := entity.TrackFavorite{
		ID:        m.ID,
		UserID:    m.UserID,
		CreatedAt: m.CreatedAt,
	}
	if m.Track != nil {
		track := modelTrackToEntity(*m.Track)
		fav.Track = &track
	}
	return fav
}
