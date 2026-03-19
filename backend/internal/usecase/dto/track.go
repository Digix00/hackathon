package dto

import "time"

type UserTrackDTO struct {
	ID         string
	TrackID    string // compound external ID e.g. "spotify:track:xxx"
	Title      string
	ArtistName string
	ArtworkURL *string
	PreviewURL *string
	CreatedAt  time.Time
}

type SharedTrackDTO struct {
	ID         string
	Title      string
	ArtistName string
	ArtworkURL *string
	PreviewURL *string
	UpdatedAt  time.Time
}

type UserTrackListDTO struct {
	Tracks     []UserTrackDTO
	NextCursor *string
	HasMore    bool
}
