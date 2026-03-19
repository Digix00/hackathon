package repository

import (
	"context"

	"hackathon/internal/domain/entity"
)

type NotificationRepository interface {
	ListByUserID(ctx context.Context, userID string, limit, offset int) ([]entity.Notification, error)
	CountByUserID(ctx context.Context, userID string) (int64, error)
	CountUnreadByUserID(ctx context.Context, userID string) (int64, error)
	FindByIDAndUserID(ctx context.Context, id, userID string) (entity.Notification, error)
	MarkAsRead(ctx context.Context, id, userID string) error
}
