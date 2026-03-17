package repository

import (
	"context"

	"hackathon/internal/domain/entity"
)

// LyricChainRepository は歌詞チェーンの永続化インターフェース。
type LyricChainRepository interface {
	// FindByID はチェーンを ID で取得する。
	FindByID(ctx context.Context, id string) (entity.LyricChain, error)

	// FindPendingChain は参加可能な pending チェーンを1件返す（なければ ErrNotFound）。
	FindPendingChain(ctx context.Context) (entity.LyricChain, error)

	// Create は新規チェーンを作成する。
	Create(ctx context.Context, chain entity.LyricChain) (entity.LyricChain, error)

	// IncrementParticipantCount は participant_count をインクリメントし、threshold 到達時に status を generating に変更する。
	// 返り値の bool は threshold に到達したかどうかを示す。
	IncrementParticipantCount(ctx context.Context, chainID string, threshold int) (entity.LyricChain, bool, error)
}
