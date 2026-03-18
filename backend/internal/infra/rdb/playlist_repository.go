package rdb

import (
	"context"
	"errors"
	"time"

	"github.com/jackc/pgx/v5/pgconn"
	"gorm.io/gorm"

	"hackathon/internal/domain/entity"
	domainerrs "hackathon/internal/domain/errs"
	"hackathon/internal/domain/repository"
	"hackathon/internal/infra/rdb/model"
)

type playlistRepository struct {
	db *gorm.DB
}

func NewPlaylistRepository(db *gorm.DB) repository.PlaylistRepository {
	return &playlistRepository{db: db}
}

func (r *playlistRepository) Create(ctx context.Context, p entity.Playlist) error {
	m := model.Playlist{
		ID:          p.ID,
		UserID:      p.UserID,
		Name:        p.Name,
		Description: p.Description,
		IsPublic:    p.IsPublic,
	}
	// Explicitly select all columns to ensure zero-value bools (e.g. is_public=false) are saved.
	return r.db.WithContext(ctx).Select("id", "user_id", "name", "description", "is_public", "created_at", "updated_at").Create(&m).Error
}

func (r *playlistRepository) FindByID(ctx context.Context, id string) (entity.Playlist, error) {
	var m model.Playlist
	err := r.db.WithContext(ctx).
		First(&m, "id = ?", id).Error
	if err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			return entity.Playlist{}, domainerrs.NotFound("Playlist was not found")
		}
		return entity.Playlist{}, err
	}
	return modelToEntityPlaylist(m, nil), nil
}

func (r *playlistRepository) FindByIDWithTracks(ctx context.Context, id string) (entity.Playlist, error) {
	var m model.Playlist
	err := r.db.WithContext(ctx).
		Preload("Tracks", func(db *gorm.DB) *gorm.DB {
			return db.Where("deleted_at IS NULL").Order("sort_order ASC")
		}).
		Preload("Tracks.Track").
		First(&m, "id = ?", id).Error
	if err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			return entity.Playlist{}, domainerrs.NotFound("Playlist was not found")
		}
		return entity.Playlist{}, err
	}
	return modelToEntityPlaylistWithTracks(m), nil
}

func (r *playlistRepository) ListByUserID(ctx context.Context, userID string) ([]entity.Playlist, error) {
	var ms []model.Playlist
	err := r.db.WithContext(ctx).
		Where("user_id = ? AND deleted_at IS NULL", userID).
		Order("created_at DESC").
		Find(&ms).Error
	if err != nil {
		return nil, err
	}

	playlists := make([]entity.Playlist, len(ms))
	for i, m := range ms {
		playlists[i] = modelToEntityPlaylist(m, nil)
	}
	return playlists, nil
}

func (r *playlistRepository) Update(ctx context.Context, id string, params repository.UpdatePlaylistParams) (entity.Playlist, error) {
	updates := map[string]any{}
	if params.Name != nil {
		updates["name"] = *params.Name
	}
	if params.Description != nil {
		updates["description"] = *params.Description
	}
	if params.IsPublic != nil {
		updates["is_public"] = *params.IsPublic
	}
	updates["updated_at"] = time.Now().UTC()

	if err := r.db.WithContext(ctx).Model(&model.Playlist{}).
		Where("id = ? AND deleted_at IS NULL", id).
		Updates(updates).Error; err != nil {
		return entity.Playlist{}, err
	}

	return r.FindByID(ctx, id)
}

func (r *playlistRepository) Delete(ctx context.Context, id string) error {
	return r.db.WithContext(ctx).
		Where("id = ?", id).
		Delete(&model.Playlist{}).Error
}

func (r *playlistRepository) AddTrack(ctx context.Context, pt entity.PlaylistTrack) error {
	m := model.PlaylistTrack{
		ID:         pt.ID,
		PlaylistID: pt.PlaylistID,
		TrackID:    pt.TrackID,
		SortOrder:  pt.SortOrder,
	}
	err := r.db.WithContext(ctx).Create(&m).Error
	if err != nil {
		if isUniqueConstraintViolation(err) {
			return domainerrs.Conflict("Track already exists in playlist")
		}
		return err
	}
	return nil
}

func (r *playlistRepository) RemoveTrack(ctx context.Context, playlistID, trackID string) error {
	result := r.db.WithContext(ctx).
		Where("playlist_id = ? AND track_id = ? AND deleted_at IS NULL", playlistID, trackID).
		Delete(&model.PlaylistTrack{})
	if result.Error != nil {
		return result.Error
	}
	if result.RowsAffected == 0 {
		return domainerrs.NotFound("Track not found in playlist")
	}
	return nil
}

func (r *playlistRepository) AddFavorite(ctx context.Context, id, userID, playlistID string) error {
	m := model.PlaylistFavorite{
		ID:         id,
		UserID:     userID,
		PlaylistID: playlistID,
	}
	err := r.db.WithContext(ctx).Create(&m).Error
	if err != nil {
		if isUniqueConstraintViolation(err) {
			return domainerrs.Conflict("Already favorited")
		}
		return err
	}
	return nil
}

func (r *playlistRepository) RemoveFavorite(ctx context.Context, userID, playlistID string) error {
	result := r.db.WithContext(ctx).
		Where("user_id = ? AND playlist_id = ? AND deleted_at IS NULL", userID, playlistID).
		Delete(&model.PlaylistFavorite{})
	if result.Error != nil {
		return result.Error
	}
	if result.RowsAffected == 0 {
		return domainerrs.NotFound("Favorite not found")
	}
	return nil
}

func modelToEntityPlaylist(m model.Playlist, tracks []entity.PlaylistTrack) entity.Playlist {
	return entity.Playlist{
		ID:          m.ID,
		UserID:      m.UserID,
		Name:        m.Name,
		Description: m.Description,
		IsPublic:    m.IsPublic,
		CreatedAt:   m.CreatedAt,
		UpdatedAt:   m.UpdatedAt,
		Tracks:      tracks,
	}
}

func modelToEntityPlaylistWithTracks(m model.Playlist) entity.Playlist {
	tracks := make([]entity.PlaylistTrack, len(m.Tracks))
	for i, t := range m.Tracks {
		pt := entity.PlaylistTrack{
			ID:         t.ID,
			PlaylistID: t.PlaylistID,
			TrackID:    t.TrackID,
			SortOrder:  t.SortOrder,
			CreatedAt:  t.CreatedAt,
		}
		if t.Track != nil {
			pt.Track = &entity.TrackInfo{
				ID:         t.Track.ID,
				Title:      t.Track.Title,
				ArtistName: t.Track.ArtistName,
				ArtworkURL: t.Track.AlbumArtURL,
			}
		}
		tracks[i] = pt
	}
	return modelToEntityPlaylist(m, tracks)
}

func isUniqueConstraintViolation(err error) bool {
	var pgErr *pgconn.PgError
	if errors.As(err, &pgErr) {
		return pgErr.Code == "23505"
	}
	return false
}
