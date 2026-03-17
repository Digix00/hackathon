package rdb

import (
	"context"
	"errors"
	"time"

	"gorm.io/gorm"

	"hackathon/internal/domain/entity"
	domainerrs "hackathon/internal/domain/errs"
	"hackathon/internal/domain/repository"
	"hackathon/internal/infra/rdb/model"
)

type bleTokenRepository struct {
	db *gorm.DB
}

func NewBleTokenRepository(db *gorm.DB) repository.BleTokenRepository {
	return &bleTokenRepository{db: db}
}

func (r *bleTokenRepository) Create(ctx context.Context, e entity.BleToken) error {
	m := model.BleToken{
		ID:        e.ID,
		UserID:    e.UserID,
		Token:     e.Token,
		ValidFrom: e.ValidFrom,
		ValidTo:   e.ValidTo,
	}

	if err := r.db.WithContext(ctx).Create(&m).Error; err != nil {
		return err
	}
	return nil
}

func (r *bleTokenRepository) InvalidateByUserID(ctx context.Context, userID string) error {
	now := time.Now().UTC()
	return r.db.WithContext(ctx).
		Model(&model.BleToken{}).
		Where("user_id = ? AND valid_to > ?", userID, now).
		Update("valid_to", now).Error
}

func (r *bleTokenRepository) FindLatestByUserID(ctx context.Context, userID string) (entity.BleToken, error) {
	var m model.BleToken

	err := r.db.WithContext(ctx).
		Where("user_id = ?", userID).
		Order("created_at DESC").
		First(&m).Error

	if err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			return entity.BleToken{}, domainerrs.NotFound("No ble-token found for user")
		}
		return entity.BleToken{}, err
	}

	return entity.BleToken{
		ID:        m.ID,
		UserID:    m.UserID,
		Token:     m.Token,
		ValidFrom: m.ValidFrom,
		ValidTo:   m.ValidTo,
		CreatedAt: m.CreatedAt,
	}, nil
}

func (r *bleTokenRepository) FindByToken(ctx context.Context, tokenStr string) (entity.BleToken, error) {
	var m model.BleToken

	err := r.db.WithContext(ctx).
		Where("token = ?", tokenStr).
		First(&m).Error

	if err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			return entity.BleToken{}, domainerrs.NotFound("BLE token not found")
		}
		return entity.BleToken{}, err
	}

	return entity.BleToken{
		ID:        m.ID,
		UserID:    m.UserID,
		Token:     m.Token,
		ValidFrom: m.ValidFrom,
		ValidTo:   m.ValidTo,
		CreatedAt: m.CreatedAt,
	}, nil
}
