package repository

import (
	"context"

	"hackathon/internal/domain/entity"
)

type UserCurrentTrackRepository interface {
	// FindCurrentByUserID returns (track, found, error)
	FindCurrentByUserID(ctx context.Context, userID string) (entity.TrackInfo, bool, error)
}

// UpsertTrackParams はトラックキャッシュの upsert パラメータ。
type UpsertTrackParams struct {
	ID         string
	ExternalID string
	Provider   string
	Title      string
	ArtistName string
	AlbumName  *string
	ArtworkURL *string
	PreviewURL *string // DB には保存しないが entity で使う
	DurationMs *int
}

// TrackRepository は Track キャッシュの永続化インターフェース。
type TrackRepository interface {
	// FindByProviderAndExternalID はプロバイダー+外部 ID でトラックを返す。
	FindByProviderAndExternalID(ctx context.Context, provider, externalID string) (entity.TrackInfo, bool, error)

	// Upsert はトラック情報をキャッシュする。
	Upsert(ctx context.Context, params UpsertTrackParams) (entity.TrackInfo, error)
}
