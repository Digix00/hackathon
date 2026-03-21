package usecase

import (
	"context"
	"time"

	"go.uber.org/zap"

	"hackathon/internal/domain/entity"
	"hackathon/internal/domain/repository"
	usecasedto "hackathon/internal/usecase/dto"
)

type SongUsecase interface {
	ListMySongs(ctx context.Context, authUID string, cursor string, limit int) (usecasedto.ListUserSongsResult, error)
	LikeSong(ctx context.Context, authUID string, songID string) error
	UnlikeSong(ctx context.Context, authUID string, songID string) error
}

type songUsecase struct {
	log       *zap.Logger
	userRepo  repository.UserRepository
	lyricRepo repository.LyricRepository
}

func NewSongUsecase(log *zap.Logger, userRepo repository.UserRepository, lyricRepo repository.LyricRepository) SongUsecase {
	return &songUsecase{
		log:       log,
		userRepo:  userRepo,
		lyricRepo: lyricRepo,
	}
}

func (u *songUsecase) ListMySongs(ctx context.Context, authUID string, cursor string, limit int) (usecasedto.ListUserSongsResult, error) {
	user, err := u.userRepo.FindByAuthProviderAndProviderUserID(ctx, firebaseProvider, authUID)
	if err != nil {
		return usecasedto.ListUserSongsResult{}, err
	}

	songs, nextCursor, hasMore, err := u.lyricRepo.ListUserSongs(ctx, user.ID, cursor, limit)
	if err != nil {
		return usecasedto.ListUserSongsResult{}, err
	}

	dtos := make([]usecasedto.UserSongDTO, 0, len(songs))
	for _, s := range songs {
		var generatedAt *string
		if s.Song.GeneratedAt != nil {
			formatted := s.Song.GeneratedAt.UTC().Format(time.RFC3339)
			generatedAt = &formatted
		}
		dtos = append(dtos, usecasedto.UserSongDTO{
			ID:               s.Song.ID,
			ChainID:          s.Song.ChainID,
			Title:            s.Song.Title,
			AudioURL:         s.Song.AudioURL,
			DurationSec:      s.Song.DurationSec,
			Mood:             s.Song.Mood,
			ParticipantCount: s.ParticipantCount,
			MyLyric:          s.MyLyric,
			GeneratedAt:      generatedAt,
		})
	}

	var nc *string
	if nextCursor != "" {
		nc = &nextCursor
	}

	return usecasedto.ListUserSongsResult{
		Songs:      dtos,
		NextCursor: nc,
		HasMore:    hasMore,
	}, nil
}

func (u *songUsecase) LikeSong(ctx context.Context, authUID string, songID string) error {
	user, err := u.userRepo.FindByAuthProviderAndProviderUserID(ctx, firebaseProvider, authUID)
	if err != nil {
		return err
	}

	if _, err := u.lyricRepo.FindSongByID(ctx, songID); err != nil {
		return err
	}

	like := entity.NewSongLike(songID, user.ID)
	return u.lyricRepo.CreateSongLike(ctx, like)
}

func (u *songUsecase) UnlikeSong(ctx context.Context, authUID string, songID string) error {
	user, err := u.userRepo.FindByAuthProviderAndProviderUserID(ctx, firebaseProvider, authUID)
	if err != nil {
		return err
	}
	return u.lyricRepo.DeleteSongLike(ctx, user.ID, songID)
}
