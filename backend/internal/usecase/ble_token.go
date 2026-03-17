package usecase

import (
	"context"
	"time"

	"hackathon/internal/domain/entity"
	domainerrs "hackathon/internal/domain/errs"
	"hackathon/internal/domain/repository"
	usecasedto "hackathon/internal/usecase/dto"
)

type BleTokenUsecase interface {
	// CreateBleToken issues a new BLE token for the authenticated user
	CreateBleToken(ctx context.Context, authUID string) (usecasedto.BleTokenDTO, error)

	// GetCurrentBleToken retrieves the currently valid BLE token for the user
	GetCurrentBleToken(ctx context.Context, authUID string) (usecasedto.BleTokenDTO, error)

	// GetBleUserByToken looks up and returns the minimal public info of the user who broadcasted the token
	GetBleUserByToken(ctx context.Context, requesterAuthUID string, tokenStr string) (usecasedto.BleUserDTO, error)
}

type bleTokenUsecase struct {
	bleTokenRepo repository.BleTokenRepository
	userRepo     repository.UserRepository
	blockRepo    repository.BlockRepository
}

func NewBleTokenUsecase(
	bleTokenRepo repository.BleTokenRepository,
	userRepo repository.UserRepository,
	blockRepo repository.BlockRepository,
) BleTokenUsecase {
	return &bleTokenUsecase{
		bleTokenRepo: bleTokenRepo,
		userRepo:     userRepo,
		blockRepo:    blockRepo,
	}
}

func (u *bleTokenUsecase) CreateBleToken(ctx context.Context, authUID string) (usecasedto.BleTokenDTO, error) {
	user, err := u.userRepo.FindByAuthProviderAndProviderUserID(ctx, firebaseProvider, authUID)
	if err != nil {
		return usecasedto.BleTokenDTO{}, err
	}

	// Token TTL 24 hours
	tokenEntity := entity.NewBleToken(user.ID, 24)

	// Atomically invalidate existing tokens and create the new one
	if err = u.bleTokenRepo.RotateToken(ctx, tokenEntity); err != nil {
		return usecasedto.BleTokenDTO{}, err
	}

	return usecasedto.BleTokenDTO{
		Token:   tokenEntity.Token,
		ValidTo: tokenEntity.ValidTo,
	}, nil
}

func (u *bleTokenUsecase) GetCurrentBleToken(ctx context.Context, authUID string) (usecasedto.BleTokenDTO, error) {
	user, err := u.userRepo.FindByAuthProviderAndProviderUserID(ctx, firebaseProvider, authUID)
	if err != nil {
		return usecasedto.BleTokenDTO{}, err
	}

	tokenEntity, err := u.bleTokenRepo.FindLatestByUserID(ctx, user.ID)
	if err != nil {
		return usecasedto.BleTokenDTO{}, err
	}

	now := time.Now().UTC()
	if !tokenEntity.IsValid(now) {
		return usecasedto.BleTokenDTO{}, domainerrs.NotFound("No valid ble-token found for user")
	}

	return usecasedto.BleTokenDTO{
		Token:   tokenEntity.Token,
		ValidTo: tokenEntity.ValidTo,
	}, nil
}

func (u *bleTokenUsecase) GetBleUserByToken(ctx context.Context, requesterAuthUID string, tokenStr string) (usecasedto.BleUserDTO, error) {
	tokenEntity, err := u.bleTokenRepo.FindByToken(ctx, tokenStr)
	if err != nil {
		return usecasedto.BleUserDTO{}, err
	}

	now := time.Now().UTC()
	if !tokenEntity.IsValid(now) {
		return usecasedto.BleUserDTO{}, domainerrs.NotFound("BLE token has expired")
	}

	requester, err := u.userRepo.FindByAuthProviderAndProviderUserID(ctx, firebaseProvider, requesterAuthUID)
	if err != nil {
		return usecasedto.BleUserDTO{}, err
	}

	blocked, err := u.blockRepo.ExistsBetween(ctx, requester.ID, tokenEntity.UserID)
	if err != nil {
		return usecasedto.BleUserDTO{}, err
	}
	if blocked {
		return usecasedto.BleUserDTO{}, domainerrs.NotFound("User was not found")
	}

	target, err := u.userRepo.FindByID(ctx, tokenEntity.UserID)
	if err != nil {
		return usecasedto.BleUserDTO{}, err
	}

	displayName := ""
	if target.Name != nil {
		displayName = *target.Name
	}

	return usecasedto.BleUserDTO{
		ID:          target.ID,
		DisplayName: displayName,
		AvatarURL:   target.AvatarURL,
	}, nil
}
