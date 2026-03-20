package rdb

import (
	"context"
	"time"

	"github.com/google/uuid"
	"gorm.io/gorm"
	"gorm.io/gorm/clause"

	"hackathon/internal/domain/repository"
	"hackathon/internal/infra/rdb/model"
)

const maxRetryCount = 3

type lyriaJobRepository struct {
	db *gorm.DB
}

// NewLyriaJobRepository は LyriaJobRepository の実装を返す
func NewLyriaJobRepository(db *gorm.DB) repository.LyriaJobRepository {
	return &lyriaJobRepository{db: db}
}

// ClaimPendingJobs は pending 状態のジョブを最大 limit 件取得し processing に遷移させる
func (r *lyriaJobRepository) ClaimPendingJobs(ctx context.Context, limit int) ([]repository.OutboxLyriaJobDetail, error) {
	var results []repository.OutboxLyriaJobDetail

	err := r.db.WithContext(ctx).Transaction(func(tx *gorm.DB) error {
		var jobs []model.OutboxLyriaJob
		if err := tx.
			Clauses(clause.Locking{Strength: "UPDATE", Options: "SKIP LOCKED"}).
			Where("status = 'pending'").
			Order("created_at ASC").
			Limit(limit).
			Find(&jobs).Error; err != nil {
			return err
		}

		if len(jobs) == 0 {
			return nil
		}

		jobIDs := make([]string, len(jobs))
		for i, j := range jobs {
			jobIDs[i] = j.ID
		}

		if err := tx.Model(&model.OutboxLyriaJob{}).
			Where("id IN ?", jobIDs).
			Update("status", "processing").Error; err != nil {
			return err
		}

		for _, job := range jobs {
			var entries []model.LyricEntry
			if err := tx.
				Where("chain_id = ? AND deleted_at IS NULL", job.ChainID).
				Order("sequence_num ASC").
				Find(&entries).Error; err != nil {
				return err
			}

			lyrics := make([]string, len(entries))
			for i, e := range entries {
				lyrics[i] = e.Content
			}

			results = append(results, repository.OutboxLyriaJobDetail{
				JobID:   job.ID,
				ChainID: job.ChainID,
				Lyrics:  lyrics,
			})
		}

		return nil
	})

	return results, err
}

// CompleteJob はジョブを completed に更新し、生成楽曲を保存してチェーンを completed に更新する
func (r *lyriaJobRepository) CompleteJob(ctx context.Context, jobID, chainID string, song repository.SaveSongInput) error {
	now := time.Now().UTC()

	return r.db.WithContext(ctx).Transaction(func(tx *gorm.DB) error {
		songID := song.ID
		if songID == "" {
			songID = uuid.NewString()
		}

		generatedSong := model.GeneratedSong{
			ID:          songID,
			ChainID:     chainID,
			Title:       &song.Title,
			AudioURL:    &song.AudioURL,
			DurationSec: &song.DurationSec,
			Mood:        &song.Mood,
			Genre:       &song.Genre,
			Status:      "completed",
			GeneratedAt: &now,
		}
		if err := tx.Create(&generatedSong).Error; err != nil {
			return err
		}

		if err := tx.Model(&model.LyricChain{}).
			Where("id = ?", chainID).
			Updates(map[string]any{
				"status":       "completed",
				"completed_at": now,
			}).Error; err != nil {
			return err
		}

		if err := tx.Model(&model.OutboxLyriaJob{}).
			Where("id = ?", jobID).
			Updates(map[string]any{
				"status":       "completed",
				"processed_at": now,
			}).Error; err != nil {
			return err
		}

		return nil
	})
}

// FailJob はジョブ失敗を記録する。permanent=true またはリトライ回数が閾値に達した場合は
// ジョブを failed に遷移させ、関連する LyricChain も failed に更新する。
// それ以外はリトライのため pending に戻す。
func (r *lyriaJobRepository) FailJob(ctx context.Context, jobID string, errMsg string, permanent bool) error {
	now := time.Now().UTC()

	return r.db.WithContext(ctx).Transaction(func(tx *gorm.DB) error {
		var job model.OutboxLyriaJob
		if err := tx.First(&job, "id = ?", jobID).Error; err != nil {
			return err
		}

		job.RetryCount++
		job.ErrorMessage = &errMsg
		job.ProcessedAt = &now

		if permanent || job.RetryCount >= maxRetryCount {
			job.Status = "failed"
			if err := tx.Model(&model.LyricChain{}).
				Where("id = ?", job.ChainID).
				Update("status", "failed").Error; err != nil {
				return err
			}
		} else {
			job.Status = "pending"
		}

		return tx.Save(&job).Error
	})
}
