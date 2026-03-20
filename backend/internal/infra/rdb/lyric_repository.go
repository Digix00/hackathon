package rdb

import (
	"context"
	"encoding/base64"
	"errors"
	"strings"
	"time"

	"github.com/google/uuid"
	"go.uber.org/zap"
	"gorm.io/gorm"
	"gorm.io/gorm/clause"

	"hackathon/internal/domain/entity"
	domainerrs "hackathon/internal/domain/errs"
	"hackathon/internal/domain/repository"
	"hackathon/internal/infra/rdb/model"
)

type lyricRepository struct {
	log *zap.Logger
	db  *gorm.DB
}

func NewLyricRepository(log *zap.Logger, db *gorm.DB) repository.LyricRepository {
	return &lyricRepository{log: log, db: db}
}

func (r *lyricRepository) SubmitEntry(ctx context.Context, userID, encounterID, content string) (repository.SubmitLyricResult, error) {
	var result repository.SubmitLyricResult

	err := r.db.WithContext(ctx).Transaction(func(tx *gorm.DB) error {
		cutoff := time.Now().UTC().Add(-24 * time.Hour)
		var chain model.LyricChain
		err := tx.
			Clauses(clause.Locking{Strength: "UPDATE"}).
			Where(`status = 'pending'
				AND participant_count < threshold
				AND created_at > ?
				AND id NOT IN (
					SELECT chain_id FROM lyric_entries
					WHERE user_id = ? AND deleted_at IS NULL
				)`, cutoff, userID).
			Order("created_at ASC").
			First(&chain).Error

		if errors.Is(err, gorm.ErrRecordNotFound) {
			chain = model.LyricChain{
				ID:               uuid.NewString(),
				Status:           "pending",
				ParticipantCount: 0,
				Threshold:        4,
			}
			if err := tx.Create(&chain).Error; err != nil {
				return err
			}
		} else if err != nil {
			return err
		}

		entry := model.LyricEntry{
			ID:          uuid.NewString(),
			ChainID:     chain.ID,
			UserID:      userID,
			EncounterID: encounterID,
			Content:     content,
			SequenceNum: chain.ParticipantCount + 1,
		}
		if err := tx.Create(&entry).Error; err != nil {
			return err
		}

		chain.ParticipantCount++

		if chain.ParticipantCount >= chain.Threshold {
			chain.Status = "generating"
			job := model.OutboxLyriaJob{
				ID:      uuid.NewString(),
				ChainID: chain.ID,
				Status:  "pending",
			}
			if err := tx.Create(&job).Error; err != nil {
				return err
			}
		}

		if err := tx.Model(&model.LyricChain{}).Where("id = ?", chain.ID).Updates(map[string]any{
			"participant_count": chain.ParticipantCount,
			"status":            chain.Status,
		}).Error; err != nil {
			return err
		}

		result = repository.SubmitLyricResult{
			Entry: entity.LyricEntry{
				ID:          entry.ID,
				ChainID:     entry.ChainID,
				UserID:      entry.UserID,
				EncounterID: entry.EncounterID,
				Content:     entry.Content,
				SequenceNum: entry.SequenceNum,
				CreatedAt:   entry.CreatedAt,
			},
			Chain: entity.LyricChain{
				ID:               chain.ID,
				Status:           chain.Status,
				ParticipantCount: chain.ParticipantCount,
				Threshold:        chain.Threshold,
				CreatedAt:        chain.CreatedAt,
				CompletedAt:      chain.CompletedAt,
			},
		}
		return nil
	})

	return result, err
}

func (r *lyricRepository) ExistsEntryByUserAndEncounter(ctx context.Context, userID, encounterID string) (bool, error) {
	var count int64
	err := r.db.WithContext(ctx).
		Model(&model.LyricEntry{}).
		Where("user_id = ? AND encounter_id = ? AND deleted_at IS NULL", userID, encounterID).
		Count(&count).Error
	if err != nil {
		return false, err
	}
	return count > 0, nil
}

func (r *lyricRepository) GetChainWithDetails(ctx context.Context, chainID string) (repository.ChainDetailResult, error) {
	var chain model.LyricChain
	err := r.db.WithContext(ctx).
		Preload("Entries", func(db *gorm.DB) *gorm.DB {
			return db.Order("sequence_num ASC")
		}).
		Preload("GeneratedSong").
		First(&chain, "id = ?", chainID).Error
	if errors.Is(err, gorm.ErrRecordNotFound) {
		return repository.ChainDetailResult{}, domainerrs.NotFound("chain not found")
	}
	if err != nil {
		return repository.ChainDetailResult{}, err
	}

	userIDs := make([]string, 0, len(chain.Entries))
	for _, e := range chain.Entries {
		userIDs = append(userIDs, e.UserID)
	}
	userMap := make(map[string]model.User)
	if len(userIDs) > 0 {
		var users []model.User
		if err := r.db.WithContext(ctx).Preload("AvatarFile").Where("id IN ?", userIDs).Find(&users).Error; err != nil {
			return repository.ChainDetailResult{}, err
		}
		for _, u := range users {
			userMap[u.ID] = u
		}
	}

	entries := make([]repository.LyricEntryWithUser, 0, len(chain.Entries))
	for _, e := range chain.Entries {
		u := userMap[e.UserID]
		var avatarURL *string
		if u.AvatarFile != nil {
			avatarURL = &u.AvatarFile.FilePath
		}
		entries = append(entries, repository.LyricEntryWithUser{
			Entry: entity.LyricEntry{
				ID:          e.ID,
				ChainID:     e.ChainID,
				UserID:      e.UserID,
				EncounterID: e.EncounterID,
				Content:     e.Content,
				SequenceNum: e.SequenceNum,
				CreatedAt:   e.CreatedAt,
			},
			User: entity.User{
				ID:        u.ID,
				Name:      u.Name,
				AvatarURL: avatarURL,
			},
		})
	}

	result := repository.ChainDetailResult{
		Chain: entity.LyricChain{
			ID:               chain.ID,
			Status:           chain.Status,
			ParticipantCount: chain.ParticipantCount,
			Threshold:        chain.Threshold,
			CreatedAt:        chain.CreatedAt,
			CompletedAt:      chain.CompletedAt,
		},
		Entries: entries,
	}

	if chain.GeneratedSong != nil {
		s := chain.GeneratedSong
		result.Song = &entity.GeneratedSong{
			ID:          s.ID,
			ChainID:     s.ChainID,
			Title:       s.Title,
			AudioURL:    s.AudioURL,
			DurationSec: s.DurationSec,
			Mood:        s.Mood,
			Genre:       s.Genre,
			Status:      s.Status,
			GeneratedAt: s.GeneratedAt,
			CreatedAt:   s.CreatedAt,
		}
	}

	return result, nil
}

func (r *lyricRepository) FindSongByID(ctx context.Context, songID string) (entity.GeneratedSong, error) {
	var song model.GeneratedSong
	err := r.db.WithContext(ctx).First(&song, "id = ?", songID).Error
	if errors.Is(err, gorm.ErrRecordNotFound) {
		return entity.GeneratedSong{}, domainerrs.NotFound("song not found")
	}
	if err != nil {
		return entity.GeneratedSong{}, err
	}
	return entity.GeneratedSong{
		ID:          song.ID,
		ChainID:     song.ChainID,
		Title:       song.Title,
		AudioURL:    song.AudioURL,
		DurationSec: song.DurationSec,
		Mood:        song.Mood,
		Genre:       song.Genre,
		Status:      song.Status,
		GeneratedAt: song.GeneratedAt,
		CreatedAt:   song.CreatedAt,
	}, nil
}

func (r *lyricRepository) ListUserSongs(ctx context.Context, userID string, cursor string, limit int) ([]repository.UserSongResult, string, bool, error) {
	if limit <= 0 {
		limit = 20
	}

	type row struct {
		ID               string     `gorm:"column:id"`
		ChainID          string     `gorm:"column:chain_id"`
		Title            *string    `gorm:"column:title"`
		AudioURL         *string    `gorm:"column:audio_url"`
		DurationSec      *int       `gorm:"column:duration_sec"`
		Mood             *string    `gorm:"column:mood"`
		GeneratedAt      *time.Time `gorm:"column:generated_at"`
		ParticipantCount int        `gorm:"column:participant_count"`
		MyLyric          string     `gorm:"column:my_lyric"`
	}

	query := r.db.WithContext(ctx).
		Table("generated_songs gs").
		Select(`gs.id, gs.chain_id, gs.title, gs.audio_url, gs.duration_sec, gs.mood, gs.generated_at,
			lc.participant_count,
			le.content as my_lyric`).
		Joins("JOIN lyric_chains lc ON lc.id = gs.chain_id AND lc.deleted_at IS NULL").
		Joins("JOIN lyric_entries le ON le.chain_id = gs.chain_id AND le.user_id = ? AND le.deleted_at IS NULL", userID).
		Where("gs.status = 'completed' AND gs.deleted_at IS NULL")

	if cursor != "" {
		decoded, err := base64.StdEncoding.DecodeString(cursor)
		if err == nil {
			parts := strings.SplitN(string(decoded), "|", 2)
			if len(parts) == 2 {
				t, err := time.Parse(time.RFC3339Nano, parts[0])
				if err == nil {
					query = query.Where("(gs.generated_at, gs.id) < (?, ?)", t, parts[1])
				}
			}
		}
	}

	query = query.Order("gs.generated_at DESC, gs.id DESC").Limit(limit + 1)

	var rows []row
	if err := query.Scan(&rows).Error; err != nil {
		return nil, "", false, err
	}

	hasMore := len(rows) > limit
	if hasMore {
		rows = rows[:limit]
	}

	results := make([]repository.UserSongResult, 0, len(rows))
	for _, row := range rows {
		results = append(results, repository.UserSongResult{
			Song: entity.GeneratedSong{
				ID:          row.ID,
				ChainID:     row.ChainID,
				Title:       row.Title,
				AudioURL:    row.AudioURL,
				DurationSec: row.DurationSec,
				Mood:        row.Mood,
				GeneratedAt: row.GeneratedAt,
			},
			ParticipantCount: row.ParticipantCount,
			MyLyric:          row.MyLyric,
		})
	}

	var nextCursor string
	if hasMore && len(results) > 0 {
		last := results[len(results)-1]
		var ts time.Time
		if last.Song.GeneratedAt != nil {
			ts = *last.Song.GeneratedAt
		}
		nextCursor = base64.StdEncoding.EncodeToString([]byte(ts.Format(time.RFC3339Nano) + "|" + last.Song.ID))
	}

	return results, nextCursor, hasMore, nil
}

func (r *lyricRepository) CreateSongLike(ctx context.Context, like entity.SongLike) error {
	m := model.SongLike{
		ID:     like.ID,
		SongID: like.SongID,
		UserID: like.UserID,
	}
	if err := r.db.WithContext(ctx).Create(&m).Error; err != nil {
		if isUniqueConstraintViolation(err) {
			return domainerrs.Conflict("already liked")
		}
		return err
	}
	return nil
}

func (r *lyricRepository) DeleteSongLike(ctx context.Context, userID, songID string) error {
	result := r.db.WithContext(ctx).
		Where("user_id = ? AND song_id = ?", userID, songID).
		Delete(&model.SongLike{})
	if result.Error != nil {
		return result.Error
	}
	if result.RowsAffected == 0 {
		return domainerrs.NotFound("like not found")
	}
	return nil
}

func (r *lyricRepository) ExistsSongLike(ctx context.Context, userID, songID string) (bool, error) {
	var count int64
	err := r.db.WithContext(ctx).
		Model(&model.SongLike{}).
		Where("user_id = ? AND song_id = ?", userID, songID).
		Count(&count).Error
	if err != nil {
		return false, err
	}
	return count > 0, nil
}
