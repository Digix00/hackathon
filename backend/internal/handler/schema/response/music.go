package response

import "time"

// @name MusicAuthorizeResponse
// MusicAuthorizeResponse は OAuth 認可 URL レスポンス。
type MusicAuthorizeResponse struct {
	AuthorizeURL string `json:"authorize_url"`
	State        string `json:"state"`
}

// @name MusicConnectionItem
// MusicConnectionItem は音楽サービス連携の1件。
type MusicConnectionItem struct {
	Provider         string     `json:"provider" enums:"spotify,apple_music"`
	ProviderUserID   string     `json:"provider_user_id"`
	ProviderUsername *string    `json:"provider_username"`
	ExpiresAt        *time.Time `json:"expires_at"`
	UpdatedAt        time.Time  `json:"updated_at"`
}

// @name MusicConnectionsResponse
// MusicConnectionsResponse は音楽サービス連携一覧レスポンス。
type MusicConnectionsResponse struct {
	MusicConnections []MusicConnectionItem `json:"music_connections"`
}

// @name TrackItem
// TrackItem はトラックの基本情報。
type TrackItem struct {
	ID         string  `json:"id"`
	Title      string  `json:"title"`
	ArtistName string  `json:"artist_name"`
	ArtworkURL *string `json:"artwork_url"`
	PreviewURL *string `json:"preview_url"`
}

// @name TrackDetailItem
// TrackDetailItem はトラックの詳細情報。
type TrackDetailItem struct {
	TrackItem
	AlbumName  *string `json:"album_name,omitempty"`
	DurationMs *int    `json:"duration_ms,omitempty"`
}

// @name TrackSearchResponse
// TrackSearchResponse はトラック検索レスポンス。
type TrackSearchResponse struct {
	Tracks     []TrackItem     `json:"tracks"`
	Pagination PaginationResult `json:"pagination"`
}

// @name TrackDetailResponse
// TrackDetailResponse はトラック詳細レスポンス。
type TrackDetailResponse struct {
	Track TrackDetailItem `json:"track"`
}

// @name PaginationResult
// PaginationResult はページネーション情報。
type PaginationResult struct {
	NextCursor *string `json:"next_cursor"`
	HasMore    bool    `json:"has_more"`
}
