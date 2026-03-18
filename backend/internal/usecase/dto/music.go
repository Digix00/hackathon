package dto

import "time"

type MusicAuthorizeResult struct {
	AuthorizeURL string
	State        string
}

type MusicConnectionDTO struct {
	Provider         string
	ProviderUserID   string
	ProviderUsername *string
	ExpiresAt        *time.Time
	UpdatedAt        time.Time
}

type TrackDTO struct {
	ID         string
	Title      string
	ArtistName string
	ArtworkURL *string
	PreviewURL *string
	AlbumName  *string
	DurationMs *int
}

type TrackSearchResultDTO struct {
	Tracks     []TrackDTO
	NextCursor *string
	HasMore    bool
}
