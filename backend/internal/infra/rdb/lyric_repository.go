package rdb

import (
	"context"
	"errors"
	"time"

	"github.com/google/uuid"
	"gorm.io/gorm"
	"gorm.io/gorm/clause"

	"hackathon/internal/domain/entity"
	domainerrs "hackathon/internal/domain/errs"
	"hackathon/internal/domain/repository"
	"hackathon/internal/domain/vo"
	"hackathon/internal/infra/rdb/converter"
	"hackathon/internal/infra/rdb/model"
)

// ─── LyricChainRepository ─────────────────────────────────────────────────────

type lyricChainRepository struct{ db *gorm.DB }

// NewLyricChainRepository は LyricChainRepository を生成する。
func NewLyricChainRepository(db *gorm.DB) repository.LyricChainRepository {
	return &lyricChainRepository{db: db}
}

func (r *lyricChainRepository) FindByID(ctx context.Context, id string) (entity.LyricChain, error) {
	var m model.LyricChain
	err := r.db.WithContext(ctx).First(&m, "id = ?", id).Error
	if errors.Is(err, gorm.ErrRecordNotFound) {
		return entity.LyricChain{}, domainerrs.NotFound("Lyric chain was not found")
	}
	return converter.ModelToEntityLyricChain(m), err
}

func (r *lyricChainRepository) FindPendingChain(ctx context.Context) (entity.LyricChain, error) {
	var m model.LyricChain
	err := r.db.WithContext(ctx).
		Where("status = ?", string(vo.LyricChainStatusPending)).
		Order("created_at ASC").
		First(&m).Error
	if errors.Is(err, gorm.ErrRecordNotFound) {
		return entity.LyricChain{}, domainerrs.NotFound("No pending lyric chain")
	}
	return converter.ModelToEntityLyricChain(m), err
}

func (r *lyricChainRepository) Create(ctx context.Context, chain entity.LyricChain) (entity.LyricChain, error) {
	m := model.LyricChain{
		ID:        chain.ID,
		Status:    string(chain.Status),
		Threshold: chain.Threshold,
	}
	if err := r.db.WithContext(ctx).Create(&m).Error; err != nil {
		return entity.LyricChain{}, err
	}
	return converter.ModelToEntityLyricChain(m), nil
}

func (r *lyricChainRepository) IncrementParticipantCount(ctx context.Context, chainID string, threshold int) (entity.LyricChain, bool, error) {
	var m model.LyricChain
	reached := false
	err := r.db.WithContext(ctx).Transaction(func(tx *gorm.DB) error {
		if err := tx.Set("gorm:query_option", "FOR UPDATE").First(&m, "id = ?", chainID).Error; err != nil {
			return err
		}
		m.ParticipantCount++
		if m.ParticipantCount >= threshold && m.Status == string(vo.LyricChainStatusPending) {
			m.Status = string(vo.LyricChainStatusGenerating)
			reached = true
		}
		return tx.Save(&m).Error
	})
	if err != nil {
		return entity.LyricChain{}, false, err
	}
	return converter.ModelToEntityLyricChain(m), reached, nil
}

func (r *lyricChainRepository) UpdateStatus(ctx context.Context, chainID string, status vo.LyricChainStatus) error {
	return r.db.WithContext(ctx).Model(&model.LyricChain{}).
		Where("id = ?", chainID).
		Update("status", string(status)).Error
}

func (r *lyricChainRepository) AppendEntry(ctx context.Context, params repository.AppendEntryParams) (entity.LyricChain, entity.LyricEntry, bool, error) {
	var chain model.LyricChain
	var entry model.LyricEntry
	reached := false

	err := r.db.WithContext(ctx).Transaction(func(tx *gorm.DB) error {
		// chain を FOR UPDATE でロックして他の同時リクエストをブロック
		if err := tx.Set("gorm:query_option", "FOR UPDATE").First(&chain, "id = ?", params.ChainID).Error; err != nil {
			return err
		}

		// 重複投稿チェック
		var count int64
		if err := tx.Model(&model.LyricEntry{}).
			Where("chain_id = ? AND user_id = ?", params.ChainID, params.UserID).
			Count(&count).Error; err != nil {
			return err
		}
		if count > 0 {
			return domainerrs.Conflict("Already posted to this lyric chain")
		}

		// sequence_num をトランザクション内で計算（同時投稿の衝突を防ぐ）
		var entryCount int64
		if err := tx.Model(&model.LyricEntry{}).
			Where("chain_id = ?", params.ChainID).
			Count(&entryCount).Error; err != nil {
			return err
		}

		entry = model.LyricEntry{
			ID:          uuid.NewString(),
			ChainID:     params.ChainID,
			UserID:      params.UserID,
			EncounterID: params.EncounterID,
			Content:     params.Content,
			SequenceNum: int(entryCount) + 1,
		}
		if err := tx.Create(&entry).Error; err != nil {
			return err
		}

		// participant_count をインクリメントして threshold チェック
		chain.ParticipantCount++
		if chain.ParticipantCount >= params.Threshold && chain.Status == string(vo.LyricChainStatusPending) {
			chain.Status = string(vo.LyricChainStatusGenerating)
			reached = true
		}
		return tx.Save(&chain).Error
	})
	if err != nil {
		return entity.LyricChain{}, entity.LyricEntry{}, false, err
	}
	return converter.ModelToEntityLyricChain(chain), converter.ModelToEntityLyricEntry(entry), reached, nil
}

// ─── LyricEntryRepository ─────────────────────────────────────────────────────

type lyricEntryRepository struct{ db *gorm.DB }

// NewLyricEntryRepository は LyricEntryRepository を生成する。
func NewLyricEntryRepository(db *gorm.DB) repository.LyricEntryRepository {
	return &lyricEntryRepository{db: db}
}

func (r *lyricEntryRepository) FindByChainID(ctx context.Context, chainID string) ([]entity.LyricEntry, error) {
	var ms []model.LyricEntry
	if err := r.db.WithContext(ctx).
		Where("chain_id = ?", chainID).
		Order("sequence_num ASC").
		Find(&ms).Error; err != nil {
		return nil, err
	}
	result := make([]entity.LyricEntry, len(ms))
	for i, m := range ms {
		result[i] = converter.ModelToEntityLyricEntry(m)
	}
	return result, nil
}

func (r *lyricEntryRepository) ExistsByChainIDAndUserID(ctx context.Context, chainID, userID string) (bool, error) {
	var count int64
	err := r.db.WithContext(ctx).Model(&model.LyricEntry{}).
		Where("chain_id = ? AND user_id = ?", chainID, userID).
		Count(&count).Error
	return count > 0, err
}

func (r *lyricEntryRepository) Create(ctx context.Context, entry entity.LyricEntry) (entity.LyricEntry, error) {
	m := model.LyricEntry{
		ID:          entry.ID,
		ChainID:     entry.ChainID,
		UserID:      entry.UserID,
		EncounterID: entry.EncounterID,
		Content:     entry.Content,
		SequenceNum: entry.SequenceNum,
	}
	if err := r.db.WithContext(ctx).Create(&m).Error; err != nil {
		return entity.LyricEntry{}, err
	}
	return converter.ModelToEntityLyricEntry(m), nil
}

// ─── GeneratedSongRepository ──────────────────────────────────────────────────

type generatedSongRepository struct{ db *gorm.DB }

// NewGeneratedSongRepository は GeneratedSongRepository を生成する。
func NewGeneratedSongRepository(db *gorm.DB) repository.GeneratedSongRepository {
	return &generatedSongRepository{db: db}
}

func (r *generatedSongRepository) FindByChainID(ctx context.Context, chainID string) (entity.GeneratedSong, error) {
	var m model.GeneratedSong
	err := r.db.WithContext(ctx).Where("chain_id = ?", chainID).First(&m).Error
	if errors.Is(err, gorm.ErrRecordNotFound) {
		return entity.GeneratedSong{}, domainerrs.NotFound("Generated song was not found")
	}
	return converter.ModelToEntityGeneratedSong(m), err
}

func (r *generatedSongRepository) Create(ctx context.Context, song entity.GeneratedSong) (entity.GeneratedSong, error) {
	m := model.GeneratedSong{
		ID:          song.ID,
		ChainID:     song.ChainID,
		Title:       song.Title,
		AudioURL:    song.AudioURL,
		DurationSec: song.DurationSec,
		Mood:        song.Mood,
		Genre:       song.Genre,
		Status:      string(song.Status),
		GeneratedAt: song.GeneratedAt,
	}
	if err := r.db.WithContext(ctx).Create(&m).Error; err != nil {
		return entity.GeneratedSong{}, err
	}
	return converter.ModelToEntityGeneratedSong(m), nil
}

func (r *generatedSongRepository) Update(ctx context.Context, song entity.GeneratedSong) error {
	return r.db.WithContext(ctx).Model(&model.GeneratedSong{}).
		Where("id = ?", song.ID).
		Updates(map[string]any{
			"title":        song.Title,
			"audio_url":    song.AudioURL,
			"duration_sec": song.DurationSec,
			"mood":         song.Mood,
			"genre":        song.Genre,
			"status":       string(song.Status),
			"generated_at": song.GeneratedAt,
		}).Error
}

// ─── TrackRepository ──────────────────────────────────────────────────────────

type trackRepository struct{ db *gorm.DB }

// NewTrackRepository は TrackRepository を生成する。
func NewTrackRepository(db *gorm.DB) repository.TrackRepository {
	return &trackRepository{db: db}
}

func (r *trackRepository) FindByProviderAndExternalID(ctx context.Context, provider, externalID string) (entity.TrackInfo, bool, error) {
	var m model.Track
	err := r.db.WithContext(ctx).
		Where("provider = ? AND external_id = ?", provider, externalID).
		First(&m).Error
	if errors.Is(err, gorm.ErrRecordNotFound) {
		return entity.TrackInfo{}, false, nil
	}
	if err != nil {
		return entity.TrackInfo{}, false, err
	}
	return entity.TrackInfo{
		ID:         provider + ":track:" + externalID,
		Title:      m.Title,
		ArtistName: m.ArtistName,
		ArtworkURL: m.AlbumArtURL,
	}, true, nil
}

func (r *trackRepository) Upsert(ctx context.Context, params repository.UpsertTrackParams) (entity.TrackInfo, error) {
	m := model.Track{
		ID:          params.ID,
		ExternalID:  params.ExternalID,
		Provider:    params.Provider,
		Title:       params.Title,
		ArtistName:  params.ArtistName,
		AlbumName:   params.AlbumName,
		AlbumArtURL: params.ArtworkURL,
		DurationMs:  params.DurationMs,
	}
	err := r.db.WithContext(ctx).
		Clauses(clause.OnConflict{
			Columns: []clause.Column{{Name: "external_id"}, {Name: "provider"}},
			DoUpdates: clause.AssignmentColumns([]string{
				"title", "artist_name", "album_name", "album_art_url", "duration_ms",
			}),
		}).
		Create(&m).Error
	if err != nil {
		return entity.TrackInfo{}, err
	}

	var saved model.Track
	if err := r.db.WithContext(ctx).
		Where("provider = ? AND external_id = ?", params.Provider, params.ExternalID).
		First(&saved).Error; err != nil {
		return entity.TrackInfo{}, err
	}
	return entity.TrackInfo{
		ID:         params.Provider + ":track:" + params.ExternalID,
		Title:      saved.Title,
		ArtistName: saved.ArtistName,
		ArtworkURL: saved.AlbumArtURL,
	}, nil
}

// ─── OutboxLyriaJobRepository ─────────────────────────────────────────────────

type outboxLyriaJobRepository struct{ db *gorm.DB }

// NewOutboxLyriaJobRepository は OutboxLyriaJobRepository を生成する。
func NewOutboxLyriaJobRepository(db *gorm.DB) repository.OutboxLyriaJobRepository {
	return &outboxLyriaJobRepository{db: db}
}

func (r *outboxLyriaJobRepository) Create(ctx context.Context, chainID string) (entity.OutboxLyriaJob, error) {
	m := model.OutboxLyriaJob{
		ID:      uuid.NewString(),
		ChainID: chainID,
		Status:  string(vo.OutboxLyriaJobStatusPending),
	}
	if err := r.db.WithContext(ctx).Create(&m).Error; err != nil {
		return entity.OutboxLyriaJob{}, err
	}
	return converter.ModelToEntityOutboxLyriaJob(m), nil
}

func (r *outboxLyriaJobRepository) ListPending(ctx context.Context, limit int) ([]entity.OutboxLyriaJob, error) {
	var ms []model.OutboxLyriaJob
	if err := r.db.WithContext(ctx).
		Where("status = ?", string(vo.OutboxLyriaJobStatusPending)).
		Order("created_at ASC").
		Limit(limit).
		Find(&ms).Error; err != nil {
		return nil, err
	}
	result := make([]entity.OutboxLyriaJob, len(ms))
	for i, m := range ms {
		result[i] = converter.ModelToEntityOutboxLyriaJob(m)
	}
	return result, nil
}

func (r *outboxLyriaJobRepository) SetProcessing(ctx context.Context, id string) error {
	return r.db.WithContext(ctx).Model(&model.OutboxLyriaJob{}).
		Where("id = ? AND status = ?", id, string(vo.OutboxLyriaJobStatusPending)).
		Update("status", string(vo.OutboxLyriaJobStatusProcessing)).Error
}

func (r *outboxLyriaJobRepository) SetCompleted(ctx context.Context, id string, processedAt time.Time) error {
	return r.db.WithContext(ctx).Model(&model.OutboxLyriaJob{}).
		Where("id = ?", id).
		Updates(map[string]any{
			"status":       string(vo.OutboxLyriaJobStatusCompleted),
			"processed_at": processedAt,
		}).Error
}

func (r *outboxLyriaJobRepository) SetFailed(ctx context.Context, id string, errMsg string) error {
	return r.db.WithContext(ctx).Model(&model.OutboxLyriaJob{}).
		Where("id = ?", id).
		Updates(map[string]any{
			"status":        string(vo.OutboxLyriaJobStatusFailed),
			"error_message": errMsg,
		}).Error
}
