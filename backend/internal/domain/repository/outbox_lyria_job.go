package repository

import (
	"context"
	"time"

	"hackathon/internal/domain/entity"
)

// OutboxLyriaJobRepository は Lyria ジョブのアウトボックス永続化インターフェース。
type OutboxLyriaJobRepository interface {
	// Create は Lyria ジョブをアウトボックスに追加する。
	Create(ctx context.Context, chainID string) (entity.OutboxLyriaJob, error)

	// ListPending は pending の未処理ジョブを limit 件返す。
	ListPending(ctx context.Context, limit int) ([]entity.OutboxLyriaJob, error)

	// SetProcessing は pending → processing に遷移する（楽観的ロック）。
	SetProcessing(ctx context.Context, id string) error

	// SetCompleted は processing → completed に遷移する。
	SetCompleted(ctx context.Context, id string, processedAt time.Time) error

	// SetFailed は processing → failed に遷移し、エラーメッセージを保存する。
	SetFailed(ctx context.Context, id string, errMsg string) error
}
