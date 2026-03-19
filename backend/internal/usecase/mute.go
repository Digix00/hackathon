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

type MuteUsecase interface {
	CreateMute(ctx context.Context, authUID string, input usecasedto.CreateMuteInput) (usecasedto.MuteDTO, error)
	DeleteMute(ctx context.Context, authUID string, targetUserID string) error
	ListMutes(ctx context.Context, authUID string, limit int, cursor *string) (usecasedto.MuteListDTO, error)
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

func (u *muteUsecase) ListMutes(ctx context.Context, authUID string, limit int, cursor *string) (usecasedto.MuteListDTO, error) {
	muter, err := u.userRepo.FindByAuthProviderAndProviderUserID(ctx, firebaseProvider, authUID)
	if err != nil {
		return usecasedto.MuteListDTO{}, err
	}

	if limit <= 0 {
		limit = 20
	}
	if limit > 50 {
		return usecasedto.MuteListDTO{}, domainerrs.BadRequest("limit must be less than or equal to 50")
	}

	repoCursor, err := decodeMuteCursor(cursor)
	if err != nil {
		return usecasedto.MuteListDTO{}, err
	}

	mutes, nextRepoCursor, hasMore, err := u.muteRepo.ListByUserID(ctx, muter.ID, limit, repoCursor)
	if err != nil {
		return usecasedto.MuteListDTO{}, err
	}

	dtos := make([]usecasedto.MuteDTO, len(mutes))
	for i, m := range mutes {
		dtos[i] = usecasedto.MuteDTO{
			ID:           m.ID,
			TargetUserID: m.TargetUserID,
			CreatedAt:    m.CreatedAt,
		}
	}

	var nextCursorStr *string
	if nextRepoCursor != nil {
		encoded, err := encodeMuteCursor(nextRepoCursor)
		if err != nil {
			return usecasedto.MuteListDTO{}, err
		}
		nextCursorStr = &encoded
	}

	return usecasedto.MuteListDTO{
		Mutes:      dtos,
		NextCursor: nextCursorStr,
		HasMore:    hasMore,
	}, nil
}

type muteCursorPayload struct {
	CreatedAt time.Time `json:"created_at"`
	ID        string    `json:"id"`
}

func decodeMuteCursor(raw *string) (*repository.MuteCursor, error) {
	if raw == nil || *raw == "" {
		return nil, nil
	}
	decoded, err := base64.RawURLEncoding.DecodeString(*raw)
	if err != nil {
		return nil, domainerrs.BadRequest("cursor is invalid")
	}
	var payload muteCursorPayload
	if err := json.Unmarshal(decoded, &payload); err != nil {
		return nil, domainerrs.BadRequest("cursor is invalid")
	}
	if payload.ID == "" || payload.CreatedAt.IsZero() {
		return nil, domainerrs.BadRequest("cursor is invalid")
	}
	return &repository.MuteCursor{
		CreatedAt: payload.CreatedAt,
		ID:        payload.ID,
	}, nil
}

func encodeMuteCursor(cursor *repository.MuteCursor) (string, error) {
	payload, err := json.Marshal(muteCursorPayload{
		CreatedAt: cursor.CreatedAt.UTC(),
		ID:        cursor.ID,
	})
	if err != nil {
		return "", err
	}
	return base64.RawURLEncoding.EncodeToString(payload), nil
}
