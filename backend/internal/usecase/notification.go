package usecase

import (
	"context"
	"errors"

	"go.uber.org/zap"

	domainerrs "hackathon/internal/domain/errs"
	"hackathon/internal/domain/repository"
	"hackathon/internal/usecase/dto"
)

type NotificationUsecase interface {
	ListNotifications(ctx context.Context, authUID string, limit, offset int) (dto.NotificationListOutput, error)
	MarkNotificationAsRead(ctx context.Context, authUID, id string) error
	DeleteNotification(ctx context.Context, authUID, id string) error
}

type notificationUsecase struct {
	log              *zap.Logger
	userRepo         repository.UserRepository
	notificationRepo repository.NotificationRepository
}

func NewNotificationUsecase(log *zap.Logger, userRepo repository.UserRepository, notificationRepo repository.NotificationRepository) NotificationUsecase {
	return &notificationUsecase{log: log, userRepo: userRepo, notificationRepo: notificationRepo}
}

func (u *notificationUsecase) ListNotifications(ctx context.Context, authUID string, limit, offset int) (dto.NotificationListOutput, error) {
	if limit <= 0 || limit > 100 {
		limit = 20
	}
	if offset < 0 {
		offset = 0
	}

	user, err := u.userRepo.FindByAuthProviderAndProviderUserID(ctx, firebaseProvider, authUID)
	if err != nil {
		return dto.NotificationListOutput{}, err
	}

	notifications, err := u.notificationRepo.ListByUserID(ctx, user.ID, limit, offset)
	if err != nil {
		return dto.NotificationListOutput{}, err
	}

	total, err := u.notificationRepo.CountByUserID(ctx, user.ID)
	if err != nil {
		return dto.NotificationListOutput{}, err
	}

	unread, err := u.notificationRepo.CountUnreadByUserID(ctx, user.ID)
	if err != nil {
		return dto.NotificationListOutput{}, err
	}

	items := make([]dto.NotificationOutput, len(notifications))
	for i, n := range notifications {
		items[i] = dto.NotificationOutput{
			ID:          n.ID,
			EncounterID: n.EncounterID,
			Status:      n.Status,
			ReadAt:      n.ReadAt,
			CreatedAt:   n.CreatedAt,
		}
	}

	return dto.NotificationListOutput{
		Notifications: items,
		UnreadCount:   unread,
		Total:         total,
	}, nil
}

func (u *notificationUsecase) MarkNotificationAsRead(ctx context.Context, authUID, id string) error {
	user, err := u.userRepo.FindByAuthProviderAndProviderUserID(ctx, firebaseProvider, authUID)
	if err != nil {
		return err
	}

	err = u.notificationRepo.MarkAsRead(ctx, id, user.ID)
	if errors.Is(err, domainerrs.ErrNotFound) {
		return domainerrs.NotFound("Notification was not found")
	}
	return err
}

func (u *notificationUsecase) DeleteNotification(ctx context.Context, authUID, id string) error {
	user, err := u.userRepo.FindByAuthProviderAndProviderUserID(ctx, firebaseProvider, authUID)
	if err != nil {
		return err
	}

	err = u.notificationRepo.DeleteByIDAndUserID(ctx, id, user.ID)
	if errors.Is(err, domainerrs.ErrNotFound) {
		return domainerrs.NotFound("Notification was not found")
	}
	return err
}
