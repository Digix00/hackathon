package dto

import "time"

type TrackFavoriteDTO struct {
	ResourceType string
	ResourceID   string // compound external ID e.g. "spotify:track:xxx"
	Favorited    bool
	CreatedAt    time.Time
}

type TrackFavoriteListDTO struct {
	Tracks     []UserTrackDTO
	NextCursor *string
	HasMore    bool
}

type PlaylistFavoriteListDTO struct {
	Playlists  []PlaylistDTO
	NextCursor *string
	HasMore    bool
}
