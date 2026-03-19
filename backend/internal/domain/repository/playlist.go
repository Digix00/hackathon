package repository

import (
	"context"

	"hackathon/internal/domain/entity"
)

// UpdatePlaylistParams はプレイリスト更新の変更意図をまとめた構造体。ポインタ型フィールドが nil の場合は変更なし。
type UpdatePlaylistParams struct {
	Name        *string
	Description *string
	IsPublic    *bool
}

type PlaylistRepository interface {
	// Create persists a new playlist.
	Create(ctx context.Context, playlist entity.Playlist) error

	// FindByID returns a playlist by its ID (without tracks).
	FindByID(ctx context.Context, id string) (entity.Playlist, error)

	// FindByIDWithTracks returns a playlist by its ID with all its tracks.
	FindByIDWithTracks(ctx context.Context, id string) (entity.Playlist, error)

	// ListByUserID returns all playlists owned by the user (without tracks).
	ListByUserID(ctx context.Context, userID string) ([]entity.Playlist, error)

	// Update updates the playlist metadata.
	Update(ctx context.Context, id string, params UpdatePlaylistParams) (entity.Playlist, error)

	// Delete soft-deletes the playlist.
	Delete(ctx context.Context, id string) error

	// AddTrack adds a track to the playlist.
	AddTrack(ctx context.Context, playlistTrack entity.PlaylistTrack) error

	// RemoveTrack removes a track from the playlist.
	RemoveTrack(ctx context.Context, playlistID, trackID string) error

	// AddFavorite adds a playlist to the user's favorites.
	AddFavorite(ctx context.Context, id, userID, playlistID string) error

	// RemoveFavorite removes a playlist from the user's favorites.
	RemoveFavorite(ctx context.Context, userID, playlistID string) error

	// ListFavoritesByUserID returns the playlists favorited by the user with cursor-based pagination.
	ListFavoritesByUserID(ctx context.Context, userID string, limit int, cursor *PlaylistFavoriteCursor) ([]entity.Playlist, *PlaylistFavoriteCursor, bool, error)
}
