package entity

import "time"

type TrackInfo struct {
	ID         string
	Title      string
	ArtistName string
	ArtworkURL *string
	PreviewURL *string
	AlbumName  *string
	DurationMs *int
}

type UserTrack struct {
	ID        string
	UserID    string
	TrackID   string // internal UUID in DB
	Track     *TrackInfo
	CreatedAt time.Time
}

type UserCurrentTrack struct {
	ID        string
	UserID    string
	TrackID   string // internal UUID in DB
	Track     *TrackInfo
	UpdatedAt time.Time
}
