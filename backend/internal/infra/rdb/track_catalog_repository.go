package rdb

import (
	"context"
	"errors"
	"strings"
	"time"

	"github.com/google/uuid"
	"gorm.io/gorm"
	"gorm.io/gorm/clause"

	"hackathon/internal/domain/entity"
	domainerrs "hackathon/internal/domain/errs"
	"hackathon/internal/domain/repository"
	"hackathon/internal/infra/rdb/model"
)

type trackCatalogRepository struct {
	db *gorm.DB
}

func NewTrackCatalogRepository(db *gorm.DB) repository.TrackCatalogRepository {
	return &trackCatalogRepository{db: db}
}

func (r *trackCatalogRepository) Upsert(ctx context.Context, track entity.TrackInfo) (entity.TrackInfo, error) {
	provider, externalID, err := splitTrackID(track.ID)
	if err != nil {
		return entity.TrackInfo{}, err
	}
	row := model.Track{
		ID:          uuid.NewString(),
		ExternalID:  externalID,
		Provider:    provider,
		Title:       track.Title,
		ArtistName:  track.ArtistName,
		AlbumName:   track.AlbumName,
		AlbumArtURL: track.ArtworkURL,
		PreviewURL:  track.PreviewURL,
		DurationMs:  track.DurationMs,
		CachedAt:    time.Now().UTC(),
	}
	if err := r.db.WithContext(ctx).Clauses(clause.OnConflict{
		Columns:   []clause.Column{{Name: "external_id"}, {Name: "provider"}},
		DoUpdates: clause.AssignmentColumns([]string{"title", "artist_name", "album_name", "album_art_url", "preview_url", "duration_ms", "cached_at"}),
	}).Create(&row).Error; err != nil {
		return entity.TrackInfo{}, err
	}
	return r.FindByProviderAndExternalID(ctx, provider, externalID)
}

func (r *trackCatalogRepository) FindByProviderAndExternalID(ctx context.Context, provider, externalID string) (entity.TrackInfo, error) {
	var row model.Track
	if err := r.db.WithContext(ctx).Where("provider = ? AND external_id = ?", provider, externalID).First(&row).Error; err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			return entity.TrackInfo{}, domainerrs.NotFound("track was not found")
		}
		return entity.TrackInfo{}, err
	}
	return modelTrackToEntity(row), nil
}

func modelTrackToEntity(track model.Track) entity.TrackInfo {
	return entity.TrackInfo{
		ID:         track.Provider + ":track:" + track.ExternalID,
		Title:      track.Title,
		ArtistName: track.ArtistName,
		ArtworkURL: track.AlbumArtURL,
		PreviewURL: track.PreviewURL,
		AlbumName:  track.AlbumName,
		DurationMs: track.DurationMs,
	}
}

func splitTrackID(trackID string) (string, string, error) {
	parts := strings.Split(trackID, ":")
	if len(parts) != 3 || parts[1] != "track" || parts[0] == "" || parts[2] == "" {
		return "", "", domainerrs.BadRequest("track id must be <provider>:track:<external_id>")
	}
	return parts[0], parts[2], nil
}
