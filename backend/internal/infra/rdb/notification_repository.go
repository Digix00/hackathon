package rdb

import (
	"context"
	"errors"
	"time"

	"go.uber.org/zap"
	"gorm.io/gorm"

	"hackathon/internal/domain/entity"
	domainerrs "hackathon/internal/domain/errs"
	"hackathon/internal/domain/repository"
	"hackathon/internal/infra/rdb/model"
)

type notificationRepository struct {
	log *zap.Logger
	db  *gorm.DB
}

func NewNotificationRepository(log *zap.Logger, db *gorm.DB) repository.NotificationRepository {
	return &notificationRepository{log: log, db: db}
}

func (r *notificationRepository) ListByUserID(ctx context.Context, userID string, limit, offset int) ([]entity.Notification, error) {
	var records []model.OutboxNotification
	err := r.db.WithContext(ctx).
		Where("user_id = ? AND status = 'sent'", userID).
		Order("created_at DESC").
		Limit(limit).
		Offset(offset).
		Find(&records).Error
	if err != nil {
		return nil, err
	}
	notifications := make([]entity.Notification, len(records))
	for i, rec := range records {
		notifications[i] = toNotificationEntity(rec)
	}
	return notifications, nil
}

func (r *notificationRepository) CountByUserID(ctx context.Context, userID string) (int64, error) {
	var count int64
	err := r.db.WithContext(ctx).
		Model(&model.OutboxNotification{}).
		Where("user_id = ? AND status = 'sent'", userID).
		Count(&count).Error
	return count, err
}

func (r *notificationRepository) CountUnreadByUserID(ctx context.Context, userID string) (int64, error) {
	var count int64
	err := r.db.WithContext(ctx).
		Model(&model.OutboxNotification{}).
		Where("user_id = ? AND status = 'sent' AND read_at IS NULL", userID).
		Count(&count).Error
	return count, err
}

func (r *notificationRepository) FindByIDAndUserID(ctx context.Context, id, userID string) (entity.Notification, error) {
	var record model.OutboxNotification
	err := r.db.WithContext(ctx).
		Where("id = ? AND user_id = ? AND status = 'sent'", id, userID).
		First(&record).Error
	if errors.Is(err, gorm.ErrRecordNotFound) {
		return entity.Notification{}, domainerrs.NotFound("Notification was not found")
	}
	if err != nil {
		return entity.Notification{}, err
	}
	return toNotificationEntity(record), nil
}

func (r *notificationRepository) MarkAsRead(ctx context.Context, id, userID string) error {
	now := time.Now().UTC()
	result := r.db.WithContext(ctx).
		Model(&model.OutboxNotification{}).
		Where("id = ? AND user_id = ? AND status = 'sent' AND read_at IS NULL", id, userID).
		Update("read_at", now)
	if result.Error != nil {
		return result.Error
	}
	if result.RowsAffected == 0 {
		var count int64
		if err := r.db.WithContext(ctx).Model(&model.OutboxNotification{}).
			Where("id = ? AND user_id = ? AND status = 'sent'", id, userID).Count(&count).Error; err != nil {
			return err
		}
		if count == 0 {
			return domainerrs.NotFound("Notification was not found")
		}
	}
	return nil
}

func (r *notificationRepository) DeleteByIDAndUserID(ctx context.Context, id, userID string) error {
	result := r.db.WithContext(ctx).
		Where("id = ? AND user_id = ? AND status = 'sent'", id, userID).
		Delete(&model.OutboxNotification{})
	if result.Error != nil {
		return result.Error
	}
	if result.RowsAffected == 0 {
		return domainerrs.NotFound("Notification was not found")
	}
	return nil
}

func toNotificationEntity(rec model.OutboxNotification) entity.Notification {
	return entity.Notification{
		ID:          rec.ID,
		UserID:      rec.UserID,
		EncounterID: rec.EncounterID,
		Status:      rec.Status,
		RetryCount:  rec.RetryCount,
		ReadAt:      rec.ReadAt,
		CreatedAt:   rec.CreatedAt,
		ProcessedAt: rec.ProcessedAt,
	}
}
