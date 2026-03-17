package dto

import "time"

// MusicConnectionDTO は音楽サービス連携情報のDTO。
type MusicConnectionDTO struct {
	Provider         string
	ProviderUserID   string
	ProviderUsername *string
	ExpiresAt        *time.Time
	UpdatedAt        time.Time
}

// TrackDTO はトラック情報のDTO。
type TrackDTO struct {
	ID         string // "<provider>:track:<external_id>"
	Title      string
	ArtistName string
	ArtworkURL *string
	PreviewURL *string
	AlbumName  *string
	DurationMs *int
}

// TrackSearchResultDTO はトラック検索結果のDTO。
type TrackSearchResultDTO struct {
	Tracks     []TrackDTO
	NextCursor *string
	HasMore    bool
}
