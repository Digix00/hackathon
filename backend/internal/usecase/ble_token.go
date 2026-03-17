package usecase

import (
	"context"
	"errors"
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
	bleTokenRepo     repository.BleTokenRepository
	userRepo         repository.UserRepository
	blockRepo        repository.BlockRepository
	userSettingsRepo repository.UserSettingsRepository
	encounterRepo    repository.EncounterRepository
	trackRepo        repository.UserCurrentTrackRepository
}

func NewBleTokenUsecase(
	bleTokenRepo repository.BleTokenRepository,
	userRepo repository.UserRepository,
	blockRepo repository.BlockRepository,
	userSettingsRepo repository.UserSettingsRepository,
	encounterRepo repository.EncounterRepository,
	trackRepo repository.UserCurrentTrackRepository,
) BleTokenUsecase {
	return &bleTokenUsecase{
		bleTokenRepo:     bleTokenRepo,
		userRepo:         userRepo,
		blockRepo:        blockRepo,
		userSettingsRepo: userSettingsRepo,
		encounterRepo:    encounterRepo,
		trackRepo:        trackRepo,
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

	tokenEntity, err := u.bleTokenRepo.FindLatestByUserID(ctx, user.ID)
	if err != nil {
		return usecasedto.BleTokenDTO{}, err
	}

	now := time.Now().UTC()
	if !tokenEntity.IsValid(now) {
		return usecasedto.BleTokenDTO{}, domainerrs.NotFound("No valid ble-token found for user")
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

	requester, err := u.userRepo.FindByAuthProviderAndProviderUserID(ctx, firebaseProvider, requesterAuthUID)
	if err != nil {
		return usecasedto.PublicUserDTO{}, err
	}

	blocked, err := u.blockRepo.ExistsBetween(ctx, requester.ID, tokenEntity.UserID)
	if err != nil {
		return usecasedto.PublicUserDTO{}, err
	}
	if blocked {
		return usecasedto.PublicUserDTO{}, domainerrs.NotFound("User was not found")
	}

	target, err := u.userRepo.FindByID(ctx, tokenEntity.UserID)
	if err != nil {
		return usecasedto.PublicUserDTO{}, err
	}

	profileVisible := true
	trackVisible := true
	settings, settingsErr := u.userSettingsRepo.FindByUserID(ctx, target.ID)
	if settingsErr == nil {
		profileVisible = settings.ProfileVisible
		trackVisible = settings.TrackVisible
	} else if !errors.Is(settingsErr, domainerrs.ErrNotFound) {
		return usecasedto.PublicUserDTO{}, settingsErr
	}

	encounterCount, err := u.encounterRepo.CountByUserID(ctx, target.ID)
	if err != nil {
		return usecasedto.PublicUserDTO{}, err
	}

	displayName := ""
	if target.Name != nil {
		displayName = *target.Name
	}

	ageRange := userCalcAgeRange(target.Birthdate, target.AgeVisibility)

	pub := usecasedto.PublicUserDTO{
		ID:             target.ID,
		DisplayName:    displayName,
		AvatarURL:      target.AvatarURL,
		Bio:            target.Bio,
		Birthplace:     target.PrefectureName,
		AgeRange:       ageRange,
		EncounterCount: encounterCount,
		UpdatedAt:      target.UpdatedAt,
	}

	if !profileVisible {
		pub.Bio = nil
		pub.Birthplace = nil
		pub.AgeRange = nil
	}

	if trackVisible {
		track, found, trackErr := u.trackRepo.FindCurrentByUserID(ctx, target.ID)
		if trackErr != nil {
			return usecasedto.PublicUserDTO{}, trackErr
		}
		if found {
			pub.SharedTrack = &usecasedto.TrackInfoDTO{
				ID:         track.ID,
				Title:      track.Title,
				ArtistName: track.ArtistName,
				ArtworkURL: track.ArtworkURL,
			}
		}
	}

	return pub, nil
}
