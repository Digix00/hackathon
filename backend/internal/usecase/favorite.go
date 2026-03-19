package usecase

import (
	"context"
	"encoding/base64"
	"encoding/json"
	"time"

	domainerrs "hackathon/internal/domain/errs"
	"hackathon/internal/domain/repository"
	usecasedto "hackathon/internal/usecase/dto"
)

type FavoriteUsecase interface {
	// AddTrackFavorite adds a track to the authenticated user's favorites.
	// Returns (dto, isNew, error). isNew=false when already favorited.
	AddTrackFavorite(ctx context.Context, authUID, trackID string) (usecasedto.TrackFavoriteDTO, bool, error)

	// RemoveTrackFavorite removes a track from the authenticated user's favorites.
	RemoveTrackFavorite(ctx context.Context, authUID, trackID string) error

	// ListTrackFavorites returns the user's favorited tracks with cursor-based pagination.
	ListTrackFavorites(ctx context.Context, authUID string, limit int, cursor *string) (usecasedto.TrackFavoriteListDTO, error)

	// ListPlaylistFavorites returns the user's favorited playlists with cursor-based pagination.
	ListPlaylistFavorites(ctx context.Context, authUID string, limit int, cursor *string) (usecasedto.PlaylistFavoriteListDTO, error)
}

type favoriteUsecase struct {
	userRepo          repository.UserRepository
	trackFavoriteRepo repository.TrackFavoriteRepository
	playlistRepo      repository.PlaylistRepository
	trackCatalogRepo  repository.TrackCatalogRepository
}

func NewFavoriteUsecase(
	userRepo repository.UserRepository,
	trackFavoriteRepo repository.TrackFavoriteRepository,
	playlistRepo repository.PlaylistRepository,
	trackCatalogRepo repository.TrackCatalogRepository,
) FavoriteUsecase {
	return &favoriteUsecase{
		userRepo:          userRepo,
		trackFavoriteRepo: trackFavoriteRepo,
		playlistRepo:      playlistRepo,
		trackCatalogRepo:  trackCatalogRepo,
	}
}

func (u *favoriteUsecase) AddTrackFavorite(ctx context.Context, authUID, trackID string) (usecasedto.TrackFavoriteDTO, bool, error) {
	user, err := u.userRepo.FindByAuthProviderAndProviderUserID(ctx, firebaseProvider, authUID)
	if err != nil {
		return usecasedto.TrackFavoriteDTO{}, false, err
	}

	// Verify the track exists in the catalog.
	if _, err := u.trackCatalogRepo.FindByID(ctx, trackID); err != nil {
		return usecasedto.TrackFavoriteDTO{}, false, err
	}

	fav, isNew, err := u.trackFavoriteRepo.Upsert(ctx, user.ID, trackID)
	if err != nil {
		return usecasedto.TrackFavoriteDTO{}, false, err
	}

	return usecasedto.TrackFavoriteDTO{
		ResourceType: "track",
		ResourceID:   trackID,
		Favorited:    true,
		CreatedAt:    fav.CreatedAt,
	}, isNew, nil
}

func (u *favoriteUsecase) RemoveTrackFavorite(ctx context.Context, authUID, trackID string) error {
	user, err := u.userRepo.FindByAuthProviderAndProviderUserID(ctx, firebaseProvider, authUID)
	if err != nil {
		return err
	}
	return u.trackFavoriteRepo.DeleteByUserIDAndTrackID(ctx, user.ID, trackID)
}

func (u *favoriteUsecase) ListTrackFavorites(ctx context.Context, authUID string, limit int, cursor *string) (usecasedto.TrackFavoriteListDTO, error) {
	user, err := u.userRepo.FindByAuthProviderAndProviderUserID(ctx, firebaseProvider, authUID)
	if err != nil {
		return usecasedto.TrackFavoriteListDTO{}, err
	}

	if limit <= 0 {
		limit = 20
	}
	if limit > 50 {
		return usecasedto.TrackFavoriteListDTO{}, domainerrs.BadRequest("limit must be less than or equal to 50")
	}

	repoCursor, err := decodeTrackFavoriteCursor(cursor)
	if err != nil {
		return usecasedto.TrackFavoriteListDTO{}, err
	}

	favs, nextRepoCursor, hasMore, err := u.trackFavoriteRepo.ListByUserID(ctx, user.ID, limit, repoCursor)
	if err != nil {
		return usecasedto.TrackFavoriteListDTO{}, err
	}

	dtos := make([]usecasedto.UserTrackDTO, len(favs))
	for i, f := range favs {
		dto := usecasedto.UserTrackDTO{
			ID:        f.ID,
			CreatedAt: f.CreatedAt,
		}
		if f.Track != nil {
			dto.TrackID = f.Track.ID
			dto.Title = f.Track.Title
			dto.ArtistName = f.Track.ArtistName
			dto.ArtworkURL = f.Track.ArtworkURL
			dto.PreviewURL = f.Track.PreviewURL
		}
		dtos[i] = dto
	}

	var nextCursorStr *string
	if nextRepoCursor != nil {
		encoded, err := encodeTrackFavoriteCursor(nextRepoCursor)
		if err != nil {
			return usecasedto.TrackFavoriteListDTO{}, err
		}
		nextCursorStr = &encoded
	}

	return usecasedto.TrackFavoriteListDTO{
		Tracks:     dtos,
		NextCursor: nextCursorStr,
		HasMore:    hasMore,
	}, nil
}

func (u *favoriteUsecase) ListPlaylistFavorites(ctx context.Context, authUID string, limit int, cursor *string) (usecasedto.PlaylistFavoriteListDTO, error) {
	user, err := u.userRepo.FindByAuthProviderAndProviderUserID(ctx, firebaseProvider, authUID)
	if err != nil {
		return usecasedto.PlaylistFavoriteListDTO{}, err
	}

	if limit <= 0 {
		limit = 20
	}
	if limit > 50 {
		return usecasedto.PlaylistFavoriteListDTO{}, domainerrs.BadRequest("limit must be less than or equal to 50")
	}

	repoCursor, err := decodePlaylistFavoriteCursor(cursor)
	if err != nil {
		return usecasedto.PlaylistFavoriteListDTO{}, err
	}

	playlists, nextRepoCursor, hasMore, err := u.playlistRepo.ListFavoritesByUserID(ctx, user.ID, limit, repoCursor)
	if err != nil {
		return usecasedto.PlaylistFavoriteListDTO{}, err
	}

	dtos := make([]usecasedto.PlaylistDTO, len(playlists))
	for i, p := range playlists {
		dtos[i] = playlistToDTO(p)
	}

	var nextCursorStr *string
	if nextRepoCursor != nil {
		encoded, err := encodePlaylistFavoriteCursor(nextRepoCursor)
		if err != nil {
			return usecasedto.PlaylistFavoriteListDTO{}, err
		}
		nextCursorStr = &encoded
	}

	return usecasedto.PlaylistFavoriteListDTO{
		Playlists:  dtos,
		NextCursor: nextCursorStr,
		HasMore:    hasMore,
	}, nil
}

type trackFavoriteCursorPayload struct {
	CreatedAt time.Time `json:"created_at"`
	ID        string    `json:"id"`
}

func decodeTrackFavoriteCursor(raw *string) (*repository.TrackFavoriteCursor, error) {
	if raw == nil || *raw == "" {
		return nil, nil
	}
	decoded, err := base64.RawURLEncoding.DecodeString(*raw)
	if err != nil {
		return nil, domainerrs.BadRequest("cursor is invalid")
	}
	var payload trackFavoriteCursorPayload
	if err := json.Unmarshal(decoded, &payload); err != nil {
		return nil, domainerrs.BadRequest("cursor is invalid")
	}
	if payload.ID == "" || payload.CreatedAt.IsZero() {
		return nil, domainerrs.BadRequest("cursor is invalid")
	}
	return &repository.TrackFavoriteCursor{
		CreatedAt: payload.CreatedAt,
		ID:        payload.ID,
	}, nil
}

func encodeTrackFavoriteCursor(cursor *repository.TrackFavoriteCursor) (string, error) {
	payload, err := json.Marshal(trackFavoriteCursorPayload{
		CreatedAt: cursor.CreatedAt.UTC(),
		ID:        cursor.ID,
	})
	if err != nil {
		return "", err
	}
	return base64.RawURLEncoding.EncodeToString(payload), nil
}

type playlistFavoriteCursorPayload struct {
	CreatedAt time.Time `json:"created_at"`
	ID        string    `json:"id"`
}

func decodePlaylistFavoriteCursor(raw *string) (*repository.PlaylistFavoriteCursor, error) {
	if raw == nil || *raw == "" {
		return nil, nil
	}
	decoded, err := base64.RawURLEncoding.DecodeString(*raw)
	if err != nil {
		return nil, domainerrs.BadRequest("cursor is invalid")
	}
	var payload playlistFavoriteCursorPayload
	if err := json.Unmarshal(decoded, &payload); err != nil {
		return nil, domainerrs.BadRequest("cursor is invalid")
	}
	if payload.ID == "" || payload.CreatedAt.IsZero() {
		return nil, domainerrs.BadRequest("cursor is invalid")
	}
	return &repository.PlaylistFavoriteCursor{
		CreatedAt: payload.CreatedAt,
		ID:        payload.ID,
	}, nil
}

func encodePlaylistFavoriteCursor(cursor *repository.PlaylistFavoriteCursor) (string, error) {
	payload, err := json.Marshal(playlistFavoriteCursorPayload{
		CreatedAt: cursor.CreatedAt.UTC(),
		ID:        cursor.ID,
	})
	if err != nil {
		return "", err
	}
	return base64.RawURLEncoding.EncodeToString(payload), nil
}
