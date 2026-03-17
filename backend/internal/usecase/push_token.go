package usecase

import (
	"context"
	"errors"

	"github.com/google/uuid"

	"hackathon/internal/domain/entity"
	domainerrs "hackathon/internal/domain/errs"
	"hackathon/internal/domain/repository"
	"hackathon/internal/domain/vo"
	"hackathon/internal/usecase/dto"
)

type PushTokenUsecase interface {
	CreatePushToken(ctx context.Context, authUID string, input dto.CreatePushTokenInput) (dto.Device, bool, error)
	PatchPushToken(ctx context.Context, authUID string, id string, input dto.UpdatePushTokenInput) (dto.Device, error)
	DeletePushToken(ctx context.Context, authUID string, id string) error
}

type pushTokenUsecase struct {
	userRepo       repository.UserRepository
	userDeviceRepo repository.UserDeviceRepository
}

func NewPushTokenUsecase(userRepo repository.UserRepository, userDeviceRepo repository.UserDeviceRepository) PushTokenUsecase {
	return &pushTokenUsecase{userRepo: userRepo, userDeviceRepo: userDeviceRepo}
}

func (u *pushTokenUsecase) CreatePushToken(ctx context.Context, authUID string, input dto.CreatePushTokenInput) (dto.Device, bool, error) {
	if input.Platform == "" || input.DeviceID == "" || input.PushToken == "" {
		return dto.Device{}, false, domainerrs.BadRequest("platform, device_id and push_token are required")
	}
	platform, err := vo.ParsePlatform(input.Platform)
	if err != nil {
		return dto.Device{}, false, err
	}

	user, err := u.userRepo.FindByAuthProviderAndProviderUserID(ctx, firebaseProvider, authUID)
	if err != nil {
		return dto.Device{}, false, err
	}

	device, err := u.userDeviceRepo.FindByUserIDPlatformAndDeviceID(ctx, user.ID, platform, input.DeviceID)
	if err == nil {
		device.DeviceToken = input.PushToken
		device.AppVersion = input.AppVersion
		device.Enabled = true
		if err := u.userDeviceRepo.Update(ctx, &device); err != nil {
			return dto.Device{}, false, err
		}
		return toDeviceDTO(device), false, nil
	}
	if !errors.Is(err, domainerrs.ErrNotFound) {
		return dto.Device{}, false, err
	}

	device = entity.NewUserDevice(uuid.NewString(), user.ID, platform, input.DeviceID, input.PushToken, input.AppVersion)
	if err := u.userDeviceRepo.Create(ctx, &device); err != nil {
		return dto.Device{}, false, err
	}
	return toDeviceDTO(device), true, nil
}

func (u *pushTokenUsecase) PatchPushToken(ctx context.Context, authUID string, id string, input dto.UpdatePushTokenInput) (dto.Device, error) {
	user, err := u.userRepo.FindByAuthProviderAndProviderUserID(ctx, firebaseProvider, authUID)
	if err != nil {
		return dto.Device{}, err
	}

	device, err := u.userDeviceRepo.FindByIDAndUserID(ctx, id, user.ID)
	if err != nil {
		if errors.Is(err, domainerrs.ErrNotFound) {
			return dto.Device{}, domainerrs.NotFound("Device was not found")
		}
		return dto.Device{}, err
	}

	if input.PushToken != nil && *input.PushToken != "" {
		device.DeviceToken = *input.PushToken
	}
	if input.Enabled != nil {
		device.Enabled = *input.Enabled
	}
	if input.AppVersion != nil {
		device.AppVersion = input.AppVersion
	}

	if err := u.userDeviceRepo.Update(ctx, &device); err != nil {
		return dto.Device{}, err
	}
	return toDeviceDTO(device), nil
}

func (u *pushTokenUsecase) DeletePushToken(ctx context.Context, authUID string, id string) error {
	user, err := u.userRepo.FindByAuthProviderAndProviderUserID(ctx, firebaseProvider, authUID)
	if err != nil {
		return err
	}

	err = u.userDeviceRepo.DeleteByIDAndUserID(ctx, id, user.ID)
	if errors.Is(err, domainerrs.ErrNotFound) {
		return domainerrs.NotFound("Device was not found")
	}
	return err
}

func toDeviceDTO(device entity.UserDevice) dto.Device {
	return dto.Device{
		ID:        device.ID,
		Platform:  string(device.Platform),
		DeviceID:  device.DeviceID,
		Enabled:   device.Enabled,
		UpdatedAt: device.UpdatedAt,
	}
}
