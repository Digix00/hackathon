package rdb

import (
	"context"
	"errors"

	"gorm.io/gorm"
	"gorm.io/gorm/clause"

	domainerrs "hackathon/internal/domain/errs"
	"hackathon/internal/domain/entity"
	"hackathon/internal/domain/repository"
	"hackathon/internal/infra/rdb/converter"
	"hackathon/internal/infra/rdb/model"
)

type musicConnectionRepository struct {
	db *gorm.DB
}

// NewMusicConnectionRepository は MusicConnectionRepository を生成する。
func NewMusicConnectionRepository(db *gorm.DB) repository.MusicConnectionRepository {
	return &musicConnectionRepository{db: db}
}

func (r *musicConnectionRepository) FindByUserIDAndProvider(ctx context.Context, userID, provider string) (entity.MusicConnection, error) {
	var m model.MusicConnection
	err := r.db.WithContext(ctx).
		Where("user_id = ? AND provider = ?", userID, provider).
		First(&m).Error
	if errors.Is(err, gorm.ErrRecordNotFound) {
		return entity.MusicConnection{}, domainerrs.NotFound("Music connection was not found")
	}
	if err != nil {
		return entity.MusicConnection{}, err
	}
	return converter.ModelToEntityMusicConnection(m), nil
}

func (r *musicConnectionRepository) ListByUserID(ctx context.Context, userID string) ([]entity.MusicConnection, error) {
	var ms []model.MusicConnection
	if err := r.db.WithContext(ctx).Where("user_id = ?", userID).Find(&ms).Error; err != nil {
		return nil, err
	}
	result := make([]entity.MusicConnection, len(ms))
	for i, m := range ms {
		result[i] = converter.ModelToEntityMusicConnection(m)
	}
	return result, nil
}

func (r *musicConnectionRepository) Upsert(ctx context.Context, params repository.UpsertMusicConnectionParams) (entity.MusicConnection, error) {
	m := model.MusicConnection{
		ID:               params.ID,
		UserID:           params.UserID,
		Provider:         string(params.Provider),
		ProviderUserID:   params.ProviderUserID,
		ProviderUsername: params.ProviderUsername,
		AccessToken:      params.AccessToken,
		RefreshToken:     params.RefreshToken,
		ExpiresAt:        params.ExpiresAt,
	}

	err := r.db.WithContext(ctx).
		Clauses(clause.OnConflict{
			Columns: []clause.Column{{Name: "user_id"}, {Name: "provider"}},
			DoUpdates: clause.AssignmentColumns([]string{
				"provider_user_id", "provider_username",
				"access_token", "refresh_token", "expires_at",
			}),
		}).
		Create(&m).Error
	if err != nil {
		return entity.MusicConnection{}, err
	}

	var saved model.MusicConnection
	if err := r.db.WithContext(ctx).
		Where("user_id = ? AND provider = ?", params.UserID, string(params.Provider)).
		First(&saved).Error; err != nil {
		return entity.MusicConnection{}, err
	}
	return converter.ModelToEntityMusicConnection(saved), nil
}

func (r *musicConnectionRepository) DeleteByUserIDAndProvider(ctx context.Context, userID, provider string) error {
	result := r.db.WithContext(ctx).
		Where("user_id = ? AND provider = ?", userID, provider).
		Delete(&model.MusicConnection{})
	if result.Error != nil {
		return result.Error
	}
	if result.RowsAffected == 0 {
		return domainerrs.NotFound("Music connection was not found")
	}
	return nil
}
