package repository

import (
	"context"
	"time"

	"hackathon/internal/domain/entity"
	"hackathon/internal/domain/vo"
)

// UpsertMusicConnectionParams は music_connections の upsert パラメータ。
type UpsertMusicConnectionParams struct {
	ID               string
	UserID           string
	Provider         vo.MusicProvider
	ProviderUserID   string
	ProviderUsername *string
	AccessToken      string
	RefreshToken     *string
	ExpiresAt        *time.Time
}

// MusicConnectionRepository は音楽サービス連携情報の永続化インターフェース。
type MusicConnectionRepository interface {
	// FindByUserIDAndProvider は (user_id, provider) で連携情報を取得する。
	FindByUserIDAndProvider(ctx context.Context, userID, provider string) (entity.MusicConnection, error)

	// ListByUserID はユーザーの全連携情報を返す。
	ListByUserID(ctx context.Context, userID string) ([]entity.MusicConnection, error)

	// Upsert は連携情報を新規作成または更新する。
	Upsert(ctx context.Context, params UpsertMusicConnectionParams) (entity.MusicConnection, error)

	// DeleteByUserIDAndProvider は連携情報を削除する。
	DeleteByUserIDAndProvider(ctx context.Context, userID, provider string) error
}
