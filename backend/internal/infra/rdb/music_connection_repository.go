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
	"hackathon/internal/infra/rdb/converter"
	"hackathon/internal/infra/rdb/model"
)

type musicConnectionRepository struct {
	db *gorm.DB
}

func NewMusicConnectionRepository(db *gorm.DB) repository.MusicConnectionRepository {
	return &musicConnectionRepository{db: db}
}

func (r *musicConnectionRepository) ListByUserID(ctx context.Context, userID string) ([]entity.MusicConnection, error) {
	var rows []model.MusicConnection
	if err := r.db.WithContext(ctx).Where("user_id = ?", userID).Order("updated_at desc").Find(&rows).Error; err != nil {
		return nil, err
	}
	result := make([]entity.MusicConnection, 0, len(rows))
	for _, row := range rows {
		result = append(result, converter.ModelToEntityMusicConnection(row))
	}
	return result, nil
}

func (r *musicConnectionRepository) FindByUserIDAndProvider(ctx context.Context, userID, provider string) (entity.MusicConnection, error) {
	var row model.MusicConnection
	if err := r.db.WithContext(ctx).Where("user_id = ? AND provider = ?", userID, provider).First(&row).Error; err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			return entity.MusicConnection{}, domainerrs.NotFound("music connection was not found")
		}
		return entity.MusicConnection{}, err
	}
	return converter.ModelToEntityMusicConnection(row), nil
}

func (r *musicConnectionRepository) Upsert(ctx context.Context, params repository.UpsertMusicConnectionParams) (entity.MusicConnection, error) {
	row := model.MusicConnection{
		ID:               uuid.NewString(),
		UserID:           params.UserID,
		Provider:         params.Provider,
		ProviderUserID:   params.ProviderUserID,
		ProviderUsername: params.ProviderUsername,
		AccessToken:      params.AccessToken,
		RefreshToken:     params.RefreshToken,
		ExpiresAt:        params.ExpiresAt,
	}
	if err := r.db.WithContext(ctx).Clauses(clause.OnConflict{
		Columns:   []clause.Column{{Name: "user_id"}, {Name: "provider"}},
		DoUpdates: clause.AssignmentColumns([]string{"provider_user_id", "provider_username", "access_token", "refresh_token", "expires_at", "updated_at"}),
	}).Create(&row).Error; err != nil {
		return entity.MusicConnection{}, err
	}
	return r.FindByUserIDAndProvider(ctx, params.UserID, params.Provider)
}

func (r *musicConnectionRepository) DeleteByUserIDAndProvider(ctx context.Context, userID, provider string) error {
	result := r.db.WithContext(ctx).Where("user_id = ? AND provider = ?", userID, provider).Delete(&model.MusicConnection{})
	if result.Error != nil {
		return result.Error
	}
	if result.RowsAffected == 0 {
		return domainerrs.NotFound("music connection was not found")
	}
	return nil
}
