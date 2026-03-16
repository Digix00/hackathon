package model

import (
	"time"

	"gorm.io/gorm"
)

type Track struct {
	ID          string    `gorm:"primaryKey"`
	ExternalID  string    `gorm:"not null;uniqueIndex:uq_tracks_external"`
	Provider    string    `gorm:"not null;uniqueIndex:uq_tracks_external"` // 'spotify' | 'apple_music'
	Title       string    `gorm:"not null"`
	ArtistName  string    `gorm:"not null"`
	AlbumName   *string
	AlbumArtURL *string
	DurationMs  *int
	CachedAt    time.Time `gorm:"not null;autoCreateTime"`
}

type UserTrack struct {
	ID        string         `gorm:"primaryKey"`
	UserID    string         `gorm:"not null;index;uniqueIndex:uq_user_tracks,where:deleted_at IS NULL"`
	TrackID   string         `gorm:"not null;index;uniqueIndex:uq_user_tracks,where:deleted_at IS NULL"`
	CreatedAt time.Time      `gorm:"not null;autoCreateTime"`
	DeletedAt gorm.DeletedAt `gorm:"index"`

	Track *Track `gorm:"foreignKey:TrackID"`
}

type UserCurrentTrack struct {
	ID        string    `gorm:"primaryKey"`
	UserID    string    `gorm:"not null;uniqueIndex"`
	TrackID   string    `gorm:"not null"`
	UpdatedAt time.Time `gorm:"not null;autoUpdateTime"`

	Track *Track `gorm:"foreignKey:TrackID"`
}

type Playlist struct {
	ID          string         `gorm:"primaryKey"`
	UserID      string         `gorm:"not null;index"`
	Name        string         `gorm:"not null"`
	Description *string
	IsPublic    bool           `gorm:"not null;default:true;index"`
	CreatedAt   time.Time      `gorm:"not null;autoCreateTime"`
	UpdatedAt   time.Time      `gorm:"not null;autoUpdateTime"`
	DeletedAt   gorm.DeletedAt `gorm:"index"`

	Tracks []PlaylistTrack `gorm:"foreignKey:PlaylistID"`
}

type PlaylistTrack struct {
	ID         string         `gorm:"primaryKey"`
	PlaylistID string         `gorm:"not null;index;uniqueIndex:uq_playlist_tracks,where:deleted_at IS NULL"`
	TrackID    string         `gorm:"not null;index;uniqueIndex:uq_playlist_tracks,where:deleted_at IS NULL"`
	SortOrder  int            `gorm:"column:sort_order;not null"`
	CreatedAt  time.Time      `gorm:"not null;autoCreateTime"`
	UpdatedAt  time.Time      `gorm:"not null;autoUpdateTime"`
	DeletedAt  gorm.DeletedAt `gorm:"index"`

	Track *Track `gorm:"foreignKey:TrackID"`
}

type TrackFavorite struct {
	ID        string         `gorm:"primaryKey"`
	UserID    string         `gorm:"not null;index;uniqueIndex:uq_track_favorites,where:deleted_at IS NULL"`
	TrackID   string         `gorm:"not null;index;uniqueIndex:uq_track_favorites,where:deleted_at IS NULL"`
	CreatedAt time.Time      `gorm:"not null;autoCreateTime"`
	DeletedAt gorm.DeletedAt `gorm:"index"`

	Track *Track `gorm:"foreignKey:TrackID"`
}

type PlaylistFavorite struct {
	ID         string         `gorm:"primaryKey"`
	UserID     string         `gorm:"not null;index;uniqueIndex:uq_playlist_favorites,where:deleted_at IS NULL"`
	PlaylistID string         `gorm:"not null;index;uniqueIndex:uq_playlist_favorites,where:deleted_at IS NULL"`
	CreatedAt  time.Time      `gorm:"not null;autoCreateTime"`
	DeletedAt  gorm.DeletedAt `gorm:"index"`

	Playlist *Playlist `gorm:"foreignKey:PlaylistID"`
}
