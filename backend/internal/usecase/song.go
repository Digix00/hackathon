package usecase

import (
	"context"

	"hackathon/internal/domain/entity"
	domainerrs "hackathon/internal/domain/errs"
	"hackathon/internal/domain/repository"
	usecasedto "hackathon/internal/usecase/dto"
)

type SongUsecase interface {
	ListMySongs(ctx context.Context, authUID string, cursor string, limit int) (usecasedto.ListUserSongsResult, error)
	LikeSong(ctx context.Context, authUID string, songID string) error
	UnlikeSong(ctx context.Context, authUID string, songID string) error
}

type songUsecase struct {
	userRepo  repository.UserRepository
	lyricRepo repository.LyricRepository
}

func NewSongUsecase(userRepo repository.UserRepository, lyricRepo repository.LyricRepository) SongUsecase {
	return &songUsecase{
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
		dtos = append(dtos, usecasedto.UserSongDTO{
			ID:               s.Song.ID,
			Title:            s.Song.Title,
			AudioURL:         s.Song.AudioURL,
			ParticipantCount: s.ParticipantCount,
			MyLyric:          s.MyLyric,
			GeneratedAt:      s.Song.GeneratedAt,
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

	exists, err := u.lyricRepo.ExistsSongLike(ctx, user.ID, songID)
	if err != nil {
		return err
	}
	if exists {
		return domainerrs.Conflict("already liked")
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
