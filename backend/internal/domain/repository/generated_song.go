package repository

import (
	"context"

	"hackathon/internal/domain/entity"
)

// GeneratedSongRepository は生成楽曲の永続化インターフェース。
type GeneratedSongRepository interface {
	// FindByChainID はチェーン ID に紐付く楽曲を返す。
	FindByChainID(ctx context.Context, chainID string) (entity.GeneratedSong, error)

	// Create は生成楽曲レコードを作成する。
	Create(ctx context.Context, song entity.GeneratedSong) (entity.GeneratedSong, error)

	// Update は楽曲レコードを更新する（生成完了・失敗時）。
	Update(ctx context.Context, song entity.GeneratedSong) error
}
