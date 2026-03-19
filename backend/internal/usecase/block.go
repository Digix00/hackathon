package usecase

import (
	"context"
	"encoding/base64"
	"encoding/json"
	"time"

	"hackathon/internal/domain/entity"
	domainerrs "hackathon/internal/domain/errs"
	"hackathon/internal/domain/repository"
	usecasedto "hackathon/internal/usecase/dto"
)

type BlockUsecase interface {
	CreateBlock(ctx context.Context, authUID string, input usecasedto.CreateBlockInput) (usecasedto.BlockDTO, error)
	DeleteBlock(ctx context.Context, authUID string, blockedUserID string) error
	ListBlocks(ctx context.Context, authUID string, limit int, cursor *string) (usecasedto.BlockListDTO, error)
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

func (u *blockUsecase) ListBlocks(ctx context.Context, authUID string, limit int, cursor *string) (usecasedto.BlockListDTO, error) {
	blocker, err := u.userRepo.FindByAuthProviderAndProviderUserID(ctx, firebaseProvider, authUID)
	if err != nil {
		return usecasedto.BlockListDTO{}, err
	}

	if limit <= 0 {
		limit = 20
	}
	if limit > 50 {
		return usecasedto.BlockListDTO{}, domainerrs.BadRequest("limit must be less than or equal to 50")
	}

	repoCursor, err := decodeBlockCursor(cursor)
	if err != nil {
		return usecasedto.BlockListDTO{}, err
	}

	blocks, nextRepoCursor, hasMore, err := u.blockRepo.ListByBlockerUserID(ctx, blocker.ID, limit, repoCursor)
	if err != nil {
		return usecasedto.BlockListDTO{}, err
	}

	dtos := make([]usecasedto.BlockDTO, len(blocks))
	for i, b := range blocks {
		dtos[i] = usecasedto.BlockDTO{
			ID:            b.ID,
			BlockedUserID: b.BlockedUserID,
			CreatedAt:     b.CreatedAt,
		}
	}

	var nextCursorStr *string
	if nextRepoCursor != nil {
		encoded, err := encodeBlockCursor(nextRepoCursor)
		if err != nil {
			return usecasedto.BlockListDTO{}, err
		}
		nextCursorStr = &encoded
	}

	return usecasedto.BlockListDTO{
		Blocks:     dtos,
		NextCursor: nextCursorStr,
		HasMore:    hasMore,
	}, nil
}

type blockCursorPayload struct {
	CreatedAt time.Time `json:"created_at"`
	ID        string    `json:"id"`
}

func decodeBlockCursor(raw *string) (*repository.BlockCursor, error) {
	if raw == nil || *raw == "" {
		return nil, nil
	}
	decoded, err := base64.RawURLEncoding.DecodeString(*raw)
	if err != nil {
		return nil, domainerrs.BadRequest("cursor is invalid")
	}
	var payload blockCursorPayload
	if err := json.Unmarshal(decoded, &payload); err != nil {
		return nil, domainerrs.BadRequest("cursor is invalid")
	}
	if payload.ID == "" || payload.CreatedAt.IsZero() {
		return nil, domainerrs.BadRequest("cursor is invalid")
	}
	return &repository.BlockCursor{
		CreatedAt: payload.CreatedAt,
		ID:        payload.ID,
	}, nil
}

func encodeBlockCursor(cursor *repository.BlockCursor) (string, error) {
	payload, err := json.Marshal(blockCursorPayload{
		CreatedAt: cursor.CreatedAt.UTC(),
		ID:        cursor.ID,
	})
	if err != nil {
		return "", err
	}
	return base64.RawURLEncoding.EncodeToString(payload), nil
}
