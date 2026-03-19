package rdb

import (
	"context"
	"errors"

	"github.com/google/uuid"
	"gorm.io/gorm"

	"hackathon/internal/domain/entity"
	domainerrs "hackathon/internal/domain/errs"
	"hackathon/internal/domain/repository"
	"hackathon/internal/infra/rdb/model"
)

type userTrackRepository struct {
	db *gorm.DB
}

func NewUserTrackRepository(db *gorm.DB) repository.UserTrackRepository {
	return &userTrackRepository{db: db}
}

// resolveCurrentTrackInternalID looks up the internal DB UUID for a compound external track ID.
// This helper is shared by both user_track_repository and user_current_track_repository (same package).
func resolveCurrentTrackInternalID(db *gorm.DB, ctx context.Context, externalTrackID string) (string, error) {
	provider, externalID, err := splitTrackID(externalTrackID)
	if err != nil {
		return "", err
	}
	var track model.Track
	if err := db.WithContext(ctx).Select("id").
		Where("provider = ? AND external_id = ?", provider, externalID).
		First(&track).Error; err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			return "", domainerrs.NotFound("track was not found")
		}
		return "", err
	}
	return track.ID, nil
}

func (r *userTrackRepository) Upsert(ctx context.Context, userID, externalTrackID string) (entity.UserTrack, bool, error) {
	internalTrackID, err := resolveCurrentTrackInternalID(r.db, ctx, externalTrackID)
	if err != nil {
		return entity.UserTrack{}, false, err
	}

	// Check if the active record already exists.
	var existing model.UserTrack
	err = r.db.WithContext(ctx).
		Preload("Track").
		Where("user_id = ? AND track_id = ? AND deleted_at IS NULL", userID, internalTrackID).
		First(&existing).Error
	if err == nil {
		return modelToEntityUserTrack(existing), false, nil
	}
	if !errors.Is(err, gorm.ErrRecordNotFound) {
		return entity.UserTrack{}, false, err
	}

	// Create new record.
	m := model.UserTrack{
		ID:      uuid.NewString(),
		UserID:  userID,
		TrackID: internalTrackID,
	}
	if err := r.db.WithContext(ctx).Create(&m).Error; err != nil {
		if isUniqueConstraintViolation(err) {
			// Race condition: another request created it first.
			var found model.UserTrack
			if err2 := r.db.WithContext(ctx).Preload("Track").
				Where("user_id = ? AND track_id = ? AND deleted_at IS NULL", userID, internalTrackID).
				First(&found).Error; err2 != nil {
				return entity.UserTrack{}, false, err2
			}
			return modelToEntityUserTrack(found), false, nil
		}
		return entity.UserTrack{}, false, err
	}

	// Reload with track preloaded.
	if err := r.db.WithContext(ctx).Preload("Track").First(&m, "id = ?", m.ID).Error; err != nil {
		return entity.UserTrack{}, false, err
	}
	return modelToEntityUserTrack(m), true, nil
}

func (r *userTrackRepository) ListByUserID(ctx context.Context, userID string, limit int, cursor *repository.UserTrackCursor) ([]entity.UserTrack, *repository.UserTrackCursor, bool, error) {
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
	var rows []model.UserTrack
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

	tracks := make([]entity.UserTrack, len(rows))
	for i, row := range rows {
		tracks[i] = modelToEntityUserTrack(row)
	}

	var nextCursor *repository.UserTrackCursor
	if hasMore && len(rows) > 0 {
		last := rows[len(rows)-1]
		nextCursor = &repository.UserTrackCursor{
			CreatedAt: last.CreatedAt,
			ID:        last.ID,
		}
	}

	return tracks, nextCursor, hasMore, nil
}

func (r *userTrackRepository) DeleteByUserIDAndTrackID(ctx context.Context, userID, externalTrackID string) error {
	internalTrackID, err := resolveCurrentTrackInternalID(r.db, ctx, externalTrackID)
	if err != nil {
		return err
	}

	result := r.db.WithContext(ctx).
		Where("user_id = ? AND track_id = ? AND deleted_at IS NULL", userID, internalTrackID).
		Delete(&model.UserTrack{})
	if result.Error != nil {
		return result.Error
	}
	if result.RowsAffected == 0 {
		return domainerrs.NotFound("track was not found in your tracks")
	}
	return nil
}

func modelToEntityUserTrack(m model.UserTrack) entity.UserTrack {
	ut := entity.UserTrack{
		ID:        m.ID,
		UserID:    m.UserID,
		TrackID:   m.TrackID,
		CreatedAt: m.CreatedAt,
	}
	if m.Track != nil {
		track := modelTrackToEntity(*m.Track)
		ut.Track = &track
	}
	return ut
}
