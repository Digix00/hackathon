package repository

import (
	"context"

	"hackathon/internal/domain/entity"
	"hackathon/internal/domain/vo"
)

type UserDeviceRepository interface {
	FindByUserIDPlatformAndDeviceID(ctx context.Context, userID string, platform vo.Platform, deviceID string) (entity.UserDevice, error)
	FindByIDAndUserID(ctx context.Context, id, userID string) (entity.UserDevice, error)
	Create(ctx context.Context, device *entity.UserDevice) error
	Update(ctx context.Context, device *entity.UserDevice) error
	DeleteByIDAndUserID(ctx context.Context, id, userID string) error
}
