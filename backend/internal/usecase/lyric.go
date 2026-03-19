package usecase

import (
	"context"

	"hackathon/internal/domain/repository"
	usecasedto "hackathon/internal/usecase/dto"
)

type LyricUsecase interface {
	SubmitLyric(ctx context.Context, authUID string, input usecasedto.SubmitLyricInput) (usecasedto.SubmitLyricResult, error)
	GetChainDetail(ctx context.Context, chainID string) (usecasedto.ChainDetailResult, error)
}

type lyricUsecase struct {
	userRepo  repository.UserRepository
	lyricRepo repository.LyricRepository
}

func NewLyricUsecase(userRepo repository.UserRepository, lyricRepo repository.LyricRepository) LyricUsecase {
	return &lyricUsecase{
		userRepo:  userRepo,
		lyricRepo: lyricRepo,
	}
}

func (u *lyricUsecase) SubmitLyric(ctx context.Context, authUID string, input usecasedto.SubmitLyricInput) (usecasedto.SubmitLyricResult, error) {
	user, err := u.userRepo.FindByAuthProviderAndProviderUserID(ctx, firebaseProvider, authUID)
	if err != nil {
		return usecasedto.SubmitLyricResult{}, err
	}

	res, err := u.lyricRepo.SubmitEntry(ctx, user.ID, input.EncounterID, input.Content)
	if err != nil {
		return usecasedto.SubmitLyricResult{}, err
	}

	return usecasedto.SubmitLyricResult{
		Entry: usecasedto.LyricEntryDTO{
			ID:          res.Entry.ID,
			ChainID:     res.Entry.ChainID,
			SequenceNum: res.Entry.SequenceNum,
			Content:     res.Entry.Content,
			CreatedAt:   res.Entry.CreatedAt,
		},
		Chain: usecasedto.LyricChainDTO{
			ID:               res.Chain.ID,
			ParticipantCount: res.Chain.ParticipantCount,
			Threshold:        res.Chain.Threshold,
			Status:           res.Chain.Status,
		},
	}, nil
}

func (u *lyricUsecase) GetChainDetail(ctx context.Context, chainID string) (usecasedto.ChainDetailResult, error) {
	detail, err := u.lyricRepo.GetChainWithDetails(ctx, chainID)
	if err != nil {
		return usecasedto.ChainDetailResult{}, err
	}

	entries := make([]usecasedto.LyricEntryWithUserDTO, 0, len(detail.Entries))
	for _, e := range detail.Entries {
		entries = append(entries, usecasedto.LyricEntryWithUserDTO{
			SequenceNum: e.Entry.SequenceNum,
			Content:     e.Entry.Content,
			UserID:      e.User.ID,
			DisplayName: e.User.Name,
			AvatarURL:   e.User.AvatarURL,
		})
	}

	result := usecasedto.ChainDetailResult{
		Chain: usecasedto.ChainDetailDTO{
			ID:               detail.Chain.ID,
			Status:           detail.Chain.Status,
			ParticipantCount: detail.Chain.ParticipantCount,
			Threshold:        detail.Chain.Threshold,
			CreatedAt:        detail.Chain.CreatedAt,
			CompletedAt:      detail.Chain.CompletedAt,
		},
		Entries: entries,
	}

	if detail.Song != nil {
		result.Song = &usecasedto.GeneratedSongDTO{
			ID:          detail.Song.ID,
			Title:       detail.Song.Title,
			AudioURL:    detail.Song.AudioURL,
			DurationSec: detail.Song.DurationSec,
			Mood:        detail.Song.Mood,
		}
	}

	return result, nil
}
