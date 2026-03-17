package port

import (
	"context"
	"time"
)

// MusicProvider は音楽サービスの種別。
type MusicProvider string

const (
	MusicProviderSpotify    MusicProvider = "spotify"
	MusicProviderAppleMusic MusicProvider = "apple_music"
)

// MusicOAuthClient は音楽サービスの OAuth 連携インターフェース。
type MusicOAuthClient interface {
	// AuthorizeURL は OAuth 認可 URL と CSRF state を生成する。
	AuthorizeURL(ctx context.Context, userFirebaseUID string) (authorizeURL string, state string, err error)

	// ExchangeCode は認可コードをアクセストークンに交換し、ユーザー情報を返す。
	ExchangeCode(ctx context.Context, code string) (*MusicTokenResult, error)

	// RefreshToken はアクセストークンをリフレッシュする。
	RefreshToken(ctx context.Context, refreshToken string) (*MusicTokenResult, error)

	// ValidateState は state の署名を検証し、埋め込まれた Firebase UID を返す。
	ValidateState(state string) (firebaseUID string, err error)
}

// MusicTrackClient は音楽サービスのトラック検索インターフェース。
type MusicTrackClient interface {
	// SearchTracks はアクセストークンを使ってトラックを検索する。
	SearchTracks(ctx context.Context, accessToken string, query string, limit int, cursor string) (*MusicTrackSearchResult, error)

	// GetTrack は単一のトラック詳細を返す。
	GetTrack(ctx context.Context, accessToken string, externalID string) (*MusicTrackDetail, error)
}

// MusicTokenResult はトークン交換・リフレッシュの結果。
type MusicTokenResult struct {
	AccessToken      string
	RefreshToken     *string
	ExpiresAt        *time.Time
	ProviderUserID   string
	ProviderUsername *string
}

// MusicTrackSearchResult はトラック検索結果。
type MusicTrackSearchResult struct {
	Tracks     []MusicTrackInfo
	NextCursor *string
	HasMore    bool
}

// MusicTrackInfo はトラックの基本情報。
type MusicTrackInfo struct {
	ExternalID string
	Title      string
	ArtistName string
	ArtworkURL *string
	PreviewURL *string
	AlbumName  *string
	DurationMs *int
}

// MusicTrackDetail はトラックの詳細情報。
type MusicTrackDetail struct {
	ExternalID string
	Title      string
	ArtistName string
	ArtworkURL *string
	PreviewURL *string
	AlbumName  *string
	DurationMs *int
}
