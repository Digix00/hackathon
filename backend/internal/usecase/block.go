package usecase

import (
	"context"

	"hackathon/internal/domain/entity"
	domainerrs "hackathon/internal/domain/errs"
	"hackathon/internal/domain/repository"
	usecasedto "hackathon/internal/usecase/dto"
)

type BlockUsecase interface {
	CreateBlock(ctx context.Context, authUID string, input usecasedto.CreateBlockInput) (usecasedto.BlockDTO, error)
	DeleteBlock(ctx context.Context, authUID string, blockedUserID string) error
}

type blockUsecase struct {
	userRepo  repository.UserRepository
	blockRepo repository.BlockRepository
}

func NewBlockUsecase(userRepo repository.UserRepository, blockRepo repository.BlockRepository) BlockUsecase {
	return &blockUsecase{
		userRepo:  userRepo,
		blockRepo: blockRepo,
	}
}

func (u *blockUsecase) CreateBlock(ctx context.Context, authUID string, input usecasedto.CreateBlockInput) (usecasedto.BlockDTO, error) {
	blocker, err := u.userRepo.FindByAuthProviderAndProviderUserID(ctx, firebaseProvider, authUID)
	if err != nil {
		return usecasedto.BlockDTO{}, err
	}

	if blocker.ID == input.BlockedUserID {
		return usecasedto.BlockDTO{}, domainerrs.BadRequest("cannot block yourself")
	}

	_, err = u.userRepo.FindByID(ctx, input.BlockedUserID)
	if err != nil {
		return usecasedto.BlockDTO{}, err
	}

	exists, err := u.blockRepo.ExistsByBlockerAndBlocked(ctx, blocker.ID, input.BlockedUserID)
	if err != nil {
		return usecasedto.BlockDTO{}, err
	}
	if exists {
		return usecasedto.BlockDTO{}, domainerrs.Conflict("block already exists")
	}

	block := entity.NewBlock(blocker.ID, input.BlockedUserID)
	if err := u.blockRepo.Create(ctx, block); err != nil {
		return usecasedto.BlockDTO{}, err
	}

	return usecasedto.BlockDTO{
		ID:            block.ID,
		BlockedUserID: block.BlockedUserID,
		CreatedAt:     block.CreatedAt,
	}, nil
}

func (u *blockUsecase) DeleteBlock(ctx context.Context, authUID string, blockedUserID string) error {
	blocker, err := u.userRepo.FindByAuthProviderAndProviderUserID(ctx, firebaseProvider, authUID)
	if err != nil {
		return err
	}
	return u.blockRepo.Delete(ctx, blocker.ID, blockedUserID)
}
