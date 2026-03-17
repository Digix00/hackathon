package usecase

import (
	"context"
	"errors"

	"github.com/google/uuid"

	domainerrs "hackathon/internal/domain/errs"
	"hackathon/internal/domain/entity"
	"hackathon/internal/domain/repository"
	"hackathon/internal/domain/vo"
	usecasedto "hackathon/internal/usecase/dto"
)

// LyricUsecase は歌詞チェーンと楽曲生成のビジネスロジック。
type LyricUsecase interface {
	// PostLyric は歌詞チェーンへ1行を投稿する。
	// 参加可能な pending チェーンがなければ新規作成する。
	PostLyric(ctx context.Context, authUID string, input PostLyricInput) (usecasedto.PostLyricResultDTO, error)

	// GetChain はチェーン詳細（エントリ・生成楽曲）を返す。
	GetChain(ctx context.Context, chainID string) (usecasedto.LyricChainDetailDTO, error)
}

// PostLyricInput は歌詞投稿の入力。
type PostLyricInput struct {
	EncounterID string
	Content     string
}

type lyricUsecase struct {
	userRepo       repository.UserRepository
	chainRepo      repository.LyricChainRepository
	entryRepo      repository.LyricEntryRepository
	songRepo       repository.GeneratedSongRepository
	outboxRepo     repository.OutboxLyriaJobRepository
	lyricThreshold int
}

// NewLyricUsecase は LyricUsecase を生成する。
func NewLyricUsecase(
	userRepo repository.UserRepository,
	chainRepo repository.LyricChainRepository,
	entryRepo repository.LyricEntryRepository,
	songRepo repository.GeneratedSongRepository,
	outboxRepo repository.OutboxLyriaJobRepository,
) LyricUsecase {
	return &lyricUsecase{
		userRepo:       userRepo,
		chainRepo:      chainRepo,
		entryRepo:      entryRepo,
		songRepo:       songRepo,
		outboxRepo:     outboxRepo,
		lyricThreshold: 4,
	}
}

func (u *lyricUsecase) PostLyric(ctx context.Context, authUID string, input PostLyricInput) (usecasedto.PostLyricResultDTO, error) {
	if input.Content == "" {
		return usecasedto.PostLyricResultDTO{}, domainerrs.BadRequest("content is required")
	}
	if len([]rune(input.Content)) > 100 {
		return usecasedto.PostLyricResultDTO{}, domainerrs.BadRequest("content must be at most 100 characters")
	}

	user, err := u.userRepo.FindByAuthProviderAndProviderUserID(ctx, firebaseProvider, authUID)
	if err != nil {
		return usecasedto.PostLyricResultDTO{}, err
	}

	// pending チェーンを探す、なければ新規作成
	chain, err := u.chainRepo.FindPendingChain(ctx)
	if err != nil {
		if !errors.Is(err, domainerrs.ErrNotFound) {
			return usecasedto.PostLyricResultDTO{}, err
		}
		chain, err = u.chainRepo.Create(ctx, entity.LyricChain{
			ID:        uuid.NewString(),
			Status:    vo.LyricChainStatusPending,
			Threshold: u.lyricThreshold,
		})
		if err != nil {
			return usecasedto.PostLyricResultDTO{}, err
		}
	}

	// 同一チェーンへの重複投稿チェック
	exists, err := u.entryRepo.ExistsByChainIDAndUserID(ctx, chain.ID, user.ID)
	if err != nil {
		return usecasedto.PostLyricResultDTO{}, err
	}
	if exists {
		return usecasedto.PostLyricResultDTO{}, domainerrs.Conflict("Already posted to this lyric chain")
	}

	// 現在のエントリ数で sequence_num を決める
	existingEntries, err := u.entryRepo.FindByChainID(ctx, chain.ID)
	if err != nil {
		return usecasedto.PostLyricResultDTO{}, err
	}
	seqNum := len(existingEntries) + 1

	entry, err := u.entryRepo.Create(ctx, entity.LyricEntry{
		ID:          uuid.NewString(),
		ChainID:     chain.ID,
		UserID:      user.ID,
		EncounterID: input.EncounterID,
		Content:     input.Content,
		SequenceNum: seqNum,
	})
	if err != nil {
		return usecasedto.PostLyricResultDTO{}, err
	}

	// participant_count をインクリメント、threshold 到達時に Lyria ジョブを登録
	updatedChain, reached, err := u.chainRepo.IncrementParticipantCount(ctx, chain.ID, u.lyricThreshold)
	if err != nil {
		return usecasedto.PostLyricResultDTO{}, err
	}

	if reached {
		// GeneratedSong レコードを先行作成（processing 状態）
		_, _ = u.songRepo.Create(ctx, entity.GeneratedSong{
			ID:      uuid.NewString(),
			ChainID: chain.ID,
			Status:  vo.GeneratedSongStatusProcessing,
		})
		// Lyria ジョブをアウトボックスに登録（エラーはベストエフォート）
		_, _ = u.outboxRepo.Create(ctx, chain.ID)
	}

	return usecasedto.PostLyricResultDTO{
		Entry: usecasedto.LyricEntryDTO{
			ID:          entry.ID,
			ChainID:     entry.ChainID,
			SequenceNum: entry.SequenceNum,
			Content:     entry.Content,
			CreatedAt:   entry.CreatedAt,
		},
		Chain: usecasedto.LyricChainDTO{
			ID:               updatedChain.ID,
			Status:           string(updatedChain.Status),
			ParticipantCount: updatedChain.ParticipantCount,
			Threshold:        updatedChain.Threshold,
		},
	}, nil
}

func (u *lyricUsecase) GetChain(ctx context.Context, chainID string) (usecasedto.LyricChainDetailDTO, error) {
	chain, err := u.chainRepo.FindByID(ctx, chainID)
	if err != nil {
		return usecasedto.LyricChainDetailDTO{}, err
	}

	entries, err := u.entryRepo.FindByChainID(ctx, chainID)
	if err != nil {
		return usecasedto.LyricChainDetailDTO{}, err
	}

	entryDTOs := make([]usecasedto.LyricEntryWithUserDTO, len(entries))
	for i, e := range entries {
		user, userErr := u.userRepo.FindByID(ctx, e.UserID)
		displayName := "削除済みユーザー"
		var avatarURL *string
		if userErr == nil {
			if user.Name != nil {
				displayName = *user.Name
			}
			avatarURL = user.AvatarURL
		}
		entryDTOs[i] = usecasedto.LyricEntryWithUserDTO{
			SequenceNum: e.SequenceNum,
			Content:     e.Content,
			UserID:      e.UserID,
			DisplayName: displayName,
			AvatarURL:   avatarURL,
		}
	}

	detail := usecasedto.LyricChainDetailDTO{
		Chain: usecasedto.LyricChainDTO{
			ID:               chain.ID,
			Status:           string(chain.Status),
			ParticipantCount: chain.ParticipantCount,
			Threshold:        chain.Threshold,
		},
		Entries: entryDTOs,
	}

	if chain.Status == vo.LyricChainStatusCompleted {
		song, songErr := u.songRepo.FindByChainID(ctx, chainID)
		if songErr == nil {
			detail.Song = &usecasedto.GeneratedSongDTO{
				ID:          song.ID,
				Title:       song.Title,
				AudioURL:    song.AudioURL,
				DurationSec: song.DurationSec,
				Mood:        song.Mood,
			}
		}
	}

	return detail, nil
}
