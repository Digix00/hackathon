package usecase

import (
	"context"

	"hackathon/internal/domain/entity"
	domainerrs "hackathon/internal/domain/errs"
	"hackathon/internal/domain/repository"
	usecasedto "hackathon/internal/usecase/dto"
)

type MuteUsecase interface {
	CreateMute(ctx context.Context, authUID string, input usecasedto.CreateMuteInput) (usecasedto.MuteDTO, error)
	DeleteMute(ctx context.Context, authUID string, targetUserID string) error
}

type muteUsecase struct {
	userRepo repository.UserRepository
	muteRepo repository.MuteRepository
}

func NewMuteUsecase(userRepo repository.UserRepository, muteRepo repository.MuteRepository) MuteUsecase {
	return &muteUsecase{
		userRepo: userRepo,
		muteRepo: muteRepo,
	}
}

func (u *muteUsecase) CreateMute(ctx context.Context, authUID string, input usecasedto.CreateMuteInput) (usecasedto.MuteDTO, error) {
	muter, err := u.userRepo.FindByAuthProviderAndProviderUserID(ctx, firebaseProvider, authUID)
	if err != nil {
		return usecasedto.MuteDTO{}, err
	}

	if muter.ID == input.TargetUserID {
		return usecasedto.MuteDTO{}, domainerrs.BadRequest("cannot mute yourself")
	}

	_, err = u.userRepo.FindByID(ctx, input.TargetUserID)
	if err != nil {
		return usecasedto.MuteDTO{}, err
	}

	exists, err := u.muteRepo.ExistsByUserAndTarget(ctx, muter.ID, input.TargetUserID)
	if err != nil {
		return usecasedto.MuteDTO{}, err
	}
	if exists {
		return usecasedto.MuteDTO{}, domainerrs.Conflict("mute already exists")
	}

	mute := entity.NewMute(muter.ID, input.TargetUserID)
	if err := u.muteRepo.Create(ctx, mute); err != nil {
		return usecasedto.MuteDTO{}, err
	}

	return usecasedto.MuteDTO{
		ID:           mute.ID,
		TargetUserID: mute.TargetUserID,
		CreatedAt:    mute.CreatedAt,
	}, nil
}

func (u *muteUsecase) DeleteMute(ctx context.Context, authUID string, targetUserID string) error {
	muter, err := u.userRepo.FindByAuthProviderAndProviderUserID(ctx, firebaseProvider, authUID)
	if err != nil {
		return err
	}
	return u.muteRepo.Delete(ctx, muter.ID, targetUserID)
}
