package dto

import "time"

type PlaylistTrackDTO struct {
	ID         string
	TrackID    string
	Title      string
	ArtistName string
	ArtworkURL *string
	SortOrder  int
	CreatedAt  time.Time
}

type PlaylistDTO struct {
	ID          string
	UserID      string
	Name        string
	Description *string
	IsPublic    bool
	CreatedAt   time.Time
	UpdatedAt   time.Time
	Tracks      []PlaylistTrackDTO
}

type CreatePlaylistInput struct {
	Name        string
	Description *string
	IsPublic    bool
}

type UpdatePlaylistInput struct {
	Name        *string
	Description *string
	IsPublic    *bool
}
