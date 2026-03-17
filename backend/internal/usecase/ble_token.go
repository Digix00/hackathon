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

	// GetBleUserByToken looks up and returns public profile info of the target user who broadcasted the token
	GetBleUserByToken(ctx context.Context, requesterAuthUID string, tokenStr string) (usecasedto.PublicUserDTO, error)
}

type bleTokenUsecase struct {
	bleTokenRepo repository.BleTokenRepository
	userRepo     repository.UserRepository
	userUsecase  UserUsecase
}

func NewBleTokenUsecase(
	bleTokenRepo repository.BleTokenRepository,
	userRepo repository.UserRepository,
	userUsecase UserUsecase,
) BleTokenUsecase {
	return &bleTokenUsecase{
		bleTokenRepo: bleTokenRepo,
		userRepo:     userRepo,
		userUsecase:  userUsecase,
	}
}

func (u *bleTokenUsecase) CreateBleToken(ctx context.Context, authUID string) (usecasedto.BleTokenDTO, error) {
	user, err := u.userRepo.FindByAuthProviderAndProviderUserID(ctx, firebaseProvider, authUID)
	if err != nil {
		return usecasedto.BleTokenDTO{}, err
	}

	// Token TTL 24 hours
	tokenEntity := entity.NewBleToken(user.ID, 24)

	err = u.bleTokenRepo.Create(ctx, tokenEntity)
	if err != nil {
		return usecasedto.BleTokenDTO{}, err
	}

	return usecasedto.BleTokenDTO{
		Token:     tokenEntity.Token,
		ValidFrom: tokenEntity.ValidFrom,
		ValidTo:   tokenEntity.ValidTo,
	}, nil
}

func (u *bleTokenUsecase) GetCurrentBleToken(ctx context.Context, authUID string) (usecasedto.BleTokenDTO, error) {
	user, err := u.userRepo.FindByAuthProviderAndProviderUserID(ctx, firebaseProvider, authUID)
	if err != nil {
		return usecasedto.BleTokenDTO{}, err
	}

	tokenEntity, err := u.bleTokenRepo.FindCurrentByUserID(ctx, user.ID)
	if err != nil {
		return usecasedto.BleTokenDTO{}, err
	}

	return usecasedto.BleTokenDTO{
		Token:     tokenEntity.Token,
		ValidFrom: tokenEntity.ValidFrom,
		ValidTo:   tokenEntity.ValidTo,
	}, nil
}

func (u *bleTokenUsecase) GetBleUserByToken(ctx context.Context, requesterAuthUID string, tokenStr string) (usecasedto.PublicUserDTO, error) {
	tokenEntity, err := u.bleTokenRepo.FindByToken(ctx, tokenStr)
	if err != nil {
		return usecasedto.PublicUserDTO{}, err
	}

	now := time.Now().UTC()
	if !tokenEntity.IsValid(now) {
		return usecasedto.PublicUserDTO{}, domainerrs.NotFound("BLE token has expired")
	}

	// Use UserUsecase to get public profile which handles visibility and blocks
	return u.userUsecase.GetUserByID(ctx, requesterAuthUID, tokenEntity.UserID)
}
