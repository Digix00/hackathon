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
	UserID    string         `gorm:"not null;index"`
	TrackID   string         `gorm:"not null;index"`
	CreatedAt time.Time      `gorm:"not null;autoCreateTime"`
	DeletedAt gorm.DeletedAt `gorm:"index"`
	// uq_user_tracks (user_id, track_id) WHERE deleted_at IS NULL は migrate.go で定義

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
	DeletedAt   gorm.DeletedAt `gorm:"index"` // #1 MUST

	Tracks []PlaylistTrack `gorm:"foreignKey:PlaylistID"`
}

type PlaylistTrack struct {
	ID         string         `gorm:"primaryKey"`
	PlaylistID string         `gorm:"not null;index"`
	TrackID    string         `gorm:"not null;index"`
	SortOrder  int            `gorm:"column:sort_order;not null"`
	CreatedAt  time.Time      `gorm:"not null;autoCreateTime"`
	UpdatedAt  time.Time      `gorm:"not null;autoUpdateTime"`
	DeletedAt  gorm.DeletedAt `gorm:"index"`
	// uq_playlist_tracks (playlist_id, track_id) WHERE deleted_at IS NULL は migrate.go で定義

	Track *Track `gorm:"foreignKey:TrackID"`
}

type TrackFavorite struct {
	ID        string         `gorm:"primaryKey"`
	UserID    string         `gorm:"not null;index"`
	TrackID   string         `gorm:"not null;index"`
	CreatedAt time.Time      `gorm:"not null;autoCreateTime"`
	DeletedAt gorm.DeletedAt `gorm:"index"`
	// uq_track_favorites (user_id, track_id) WHERE deleted_at IS NULL は migrate.go で定義

	Track *Track `gorm:"foreignKey:TrackID"`
}

type PlaylistFavorite struct {
	ID         string         `gorm:"primaryKey"`
	UserID     string         `gorm:"not null;index"`
	PlaylistID string         `gorm:"not null;index"`
	CreatedAt  time.Time      `gorm:"not null;autoCreateTime"`
	DeletedAt  gorm.DeletedAt `gorm:"index"`
	// uq_playlist_favorites (user_id, playlist_id) WHERE deleted_at IS NULL は migrate.go で定義

	Playlist *Playlist `gorm:"foreignKey:PlaylistID"`
}
