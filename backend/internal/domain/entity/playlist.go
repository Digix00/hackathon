package entity

import (
	"time"

	"github.com/google/uuid"
)

type Playlist struct {
	ID          string
	UserID      string
	Name        string
	Description *string
	IsPublic    bool
	CreatedAt   time.Time
	UpdatedAt   time.Time
	Tracks      []PlaylistTrack
}

type PlaylistTrack struct {
	ID         string
	PlaylistID string
	TrackID    string
	SortOrder  int
	Track      *TrackInfo
	CreatedAt  time.Time
}

func NewPlaylist(userID, name string, description *string, isPublic bool) Playlist {
	now := time.Now().UTC()
	return Playlist{
		ID:          uuid.NewString(),
		UserID:      userID,
		Name:        name,
		Description: description,
		IsPublic:    isPublic,
		CreatedAt:   now,
		UpdatedAt:   now,
	}
}

func NewPlaylistTrack(playlistID, trackID string, sortOrder int) PlaylistTrack {
	return PlaylistTrack{
		ID:         uuid.NewString(),
		PlaylistID: playlistID,
		TrackID:    trackID,
		SortOrder:  sortOrder,
		CreatedAt:  time.Now().UTC(),
	}
}
