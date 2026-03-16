package rdb

import (
	"context"
	"errors"

	"gorm.io/gorm"

	"hackathon/internal/domain/entity"
	domainerrs "hackathon/internal/domain/errs"
	"hackathon/internal/domain/repository"
	"hackathon/internal/domain/vo"
	"hackathon/internal/infra/rdb/model"
)

type userDeviceRepository struct {
	db *gorm.DB
}

func NewUserDeviceRepository(db *gorm.DB) repository.UserDeviceRepository {
	return &userDeviceRepository{db: db}
}

func (r *userDeviceRepository) FindByUserIDPlatformAndDeviceID(ctx context.Context, userID string, platform vo.Platform, deviceID string) (entity.UserDevice, error) {
	var device model.UserDevice
	err := r.db.WithContext(ctx).
		Where("user_id = ? AND platform = ? AND device_id = ?", userID, string(platform), deviceID).
		First(&device).Error
	if errors.Is(err, gorm.ErrRecordNotFound) {
		return entity.UserDevice{}, domainerrs.NotFound("Device was not found")
	}
	if err != nil {
		return entity.UserDevice{}, err
	}
	return toUserDeviceEntity(device), nil
}

func (r *userDeviceRepository) FindByIDAndUserID(ctx context.Context, id, userID string) (entity.UserDevice, error) {
	var device model.UserDevice
	err := r.db.WithContext(ctx).Where("id = ? AND user_id = ?", id, userID).First(&device).Error
	if errors.Is(err, gorm.ErrRecordNotFound) {
		return entity.UserDevice{}, domainerrs.NotFound("Device was not found")
	}
	if err != nil {
		return entity.UserDevice{}, err
	}
	return toUserDeviceEntity(device), nil
}

func (r *userDeviceRepository) Create(ctx context.Context, device *entity.UserDevice) error {
	record := model.UserDevice{
		ID:          device.ID,
		UserID:      device.UserID,
		Platform:    string(device.Platform),
		DeviceID:    device.DeviceID,
		DeviceToken: device.DeviceToken,
		AppVersion:  device.AppVersion,
		Enabled:     device.Enabled,
	}
	if err := r.db.WithContext(ctx).Create(&record).Error; err != nil {
		return err
	}
	*device = toUserDeviceEntity(record)
	return nil
}

func (r *userDeviceRepository) Update(ctx context.Context, device *entity.UserDevice) error {
	err := r.db.WithContext(ctx).
		Model(&model.UserDevice{}).
		Where("id = ? AND user_id = ?", device.ID, device.UserID).
		Updates(map[string]any{
			"device_token": device.DeviceToken,
			"app_version":  device.AppVersion,
			"enabled":      device.Enabled,
		}).Error
	if err != nil {
		return err
	}
	updated, err := r.FindByIDAndUserID(ctx, device.ID, device.UserID)
	if err != nil {
		return err
	}
	*device = updated
	return nil
}

func (r *userDeviceRepository) DeleteByIDAndUserID(ctx context.Context, id, userID string) error {
	result := r.db.WithContext(ctx).Where("id = ? AND user_id = ?", id, userID).Delete(&model.UserDevice{})
	if result.Error != nil {
		return result.Error
	}
	if result.RowsAffected == 0 {
		return domainerrs.NotFound("Device was not found")
	}
	return nil
}

func toUserDeviceEntity(device model.UserDevice) entity.UserDevice {
	return entity.UserDevice{
		ID:          device.ID,
		UserID:      device.UserID,
		Platform:    vo.Platform(device.Platform),
		DeviceID:    device.DeviceID,
		DeviceToken: device.DeviceToken,
		AppVersion:  device.AppVersion,
		Enabled:     device.Enabled,
		CreatedAt:   device.CreatedAt,
		UpdatedAt:   device.UpdatedAt,
	}
}
