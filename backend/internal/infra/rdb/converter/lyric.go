package converter

import (
	"hackathon/internal/domain/entity"
	"hackathon/internal/domain/vo"
	"hackathon/internal/infra/rdb/model"
)

// ModelToEntityLyricChain は model.LyricChain をドメインエンティティに変換する。
// DB 値は既にバリデーション済みとして信頼し、強制キャストする。
func ModelToEntityLyricChain(m model.LyricChain) entity.LyricChain {
	return entity.LyricChain{
		ID:               m.ID,
		Status:           vo.LyricChainStatus(m.Status),
		ParticipantCount: m.ParticipantCount,
		Threshold:        m.Threshold,
		CreatedAt:        m.CreatedAt,
		CompletedAt:      m.CompletedAt,
	}
}

// ModelToEntityLyricEntry は model.LyricEntry をドメインエンティティに変換する。
func ModelToEntityLyricEntry(m model.LyricEntry) entity.LyricEntry {
	return entity.LyricEntry{
		ID:          m.ID,
		ChainID:     m.ChainID,
		UserID:      m.UserID,
		EncounterID: m.EncounterID,
		Content:     m.Content,
		SequenceNum: m.SequenceNum,
		CreatedAt:   m.CreatedAt,
	}
}

// ModelToEntityGeneratedSong は model.GeneratedSong をドメインエンティティに変換する。
func ModelToEntityGeneratedSong(m model.GeneratedSong) entity.GeneratedSong {
	return entity.GeneratedSong{
		ID:          m.ID,
		ChainID:     m.ChainID,
		Title:       m.Title,
		AudioURL:    m.AudioURL,
		DurationSec: m.DurationSec,
		Mood:        m.Mood,
		Genre:       m.Genre,
		Status:      vo.GeneratedSongStatus(m.Status),
		GeneratedAt: m.GeneratedAt,
	}
}

// ModelToEntityOutboxLyriaJob は model.OutboxLyriaJob をドメインエンティティに変換する。
func ModelToEntityOutboxLyriaJob(m model.OutboxLyriaJob) entity.OutboxLyriaJob {
	return entity.OutboxLyriaJob{
		ID:           m.ID,
		ChainID:      m.ChainID,
		Status:       vo.OutboxLyriaJobStatus(m.Status),
		RetryCount:   m.RetryCount,
		ErrorMessage: m.ErrorMessage,
		CreatedAt:    m.CreatedAt,
		ProcessedAt:  m.ProcessedAt,
	}
}
