package repository

import (
	"context"

	"hackathon/internal/domain/entity"
)

// LyricEntryRepository は歌詞エントリの永続化インターフェース。
type LyricEntryRepository interface {
	// FindByChainID はチェーン内の全エントリを sequence_num 昇順で返す。
	FindByChainID(ctx context.Context, chainID string) ([]entity.LyricEntry, error)

	// ExistsByChainIDAndUserID はユーザーが既にそのチェーンに投稿済みかを確認する。
	ExistsByChainIDAndUserID(ctx context.Context, chainID, userID string) (bool, error)

	// Create は歌詞エントリを作成する。
	Create(ctx context.Context, entry entity.LyricEntry) (entity.LyricEntry, error)
}
