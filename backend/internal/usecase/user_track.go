package usecase

import (
	"context"
	"encoding/base64"
	"encoding/json"
	"time"

	"hackathon/internal/domain/entity"
	domainerrs "hackathon/internal/domain/errs"
	"hackathon/internal/domain/repository"
	usecasedto "hackathon/internal/usecase/dto"
)

type UserTrackUsecase interface {
	// AddTrack adds a track to the authenticated user's saved tracks.
	// Returns (dto, isNew, error). isNew=false when track was already saved.
	AddTrack(ctx context.Context, authUID, trackID string) (usecasedto.UserTrackDTO, bool, error)

	// ListTracks returns the user's saved tracks with cursor-based pagination.
	ListTracks(ctx context.Context, authUID string, limit int, cursor *string) (usecasedto.UserTrackListDTO, error)

	// DeleteTrack removes a track from the user's saved tracks.
	DeleteTrack(ctx context.Context, authUID, trackID string) error

	// GetSharedTrack returns the user's current shared track. Returns nil if not set.
	GetSharedTrack(ctx context.Context, authUID string) (*usecasedto.SharedTrackDTO, error)

	// UpsertSharedTrack sets or updates the user's current shared track.
	// Returns (dto, isNew, error). isNew=false when a shared track was already set.
	UpsertSharedTrack(ctx context.Context, authUID, trackID string) (usecasedto.SharedTrackDTO, bool, error)

	// DeleteSharedTrack removes the user's current shared track.
	DeleteSharedTrack(ctx context.Context, authUID string) error
}

type userTrackUsecase struct {
	userRepo         repository.UserRepository
	userTrackRepo    repository.UserTrackRepository
	sharedTrackRepo  repository.UserCurrentTrackRepository
	trackCatalogRepo repository.TrackCatalogRepository
}

func NewUserTrackUsecase(
	userRepo repository.UserRepository,
	userTrackRepo repository.UserTrackRepository,
	sharedTrackRepo repository.UserCurrentTrackRepository,
	trackCatalogRepo repository.TrackCatalogRepository,
) UserTrackUsecase {
	return &userTrackUsecase{
		userRepo:         userRepo,
		userTrackRepo:    userTrackRepo,
		sharedTrackRepo:  sharedTrackRepo,
		trackCatalogRepo: trackCatalogRepo,
	}
}

func (u *userTrackUsecase) AddTrack(ctx context.Context, authUID, trackID string) (usecasedto.UserTrackDTO, bool, error) {
	user, err := u.userRepo.FindByAuthProviderAndProviderUserID(ctx, firebaseProvider, authUID)
	if err != nil {
		return usecasedto.UserTrackDTO{}, false, err
	}

	// Verify the track exists in the catalog.
	if _, err := u.trackCatalogRepo.FindByID(ctx, trackID); err != nil {
		return usecasedto.UserTrackDTO{}, false, err
	}

	ut, isNew, err := u.userTrackRepo.Upsert(ctx, user.ID, trackID)
	if err != nil {
		return usecasedto.UserTrackDTO{}, false, err
	}

	return userTrackToDTO(ut), isNew, nil
}

func (u *userTrackUsecase) ListTracks(ctx context.Context, authUID string, limit int, cursor *string) (usecasedto.UserTrackListDTO, error) {
	user, err := u.userRepo.FindByAuthProviderAndProviderUserID(ctx, firebaseProvider, authUID)
	if err != nil {
		return usecasedto.UserTrackListDTO{}, err
	}

	if limit <= 0 {
		limit = 20
	}
	if limit > 50 {
		return usecasedto.UserTrackListDTO{}, domainerrs.BadRequest("limit must be less than or equal to 50")
	}

	repoCursor, err := decodeUserTrackCursor(cursor)
	if err != nil {
		return usecasedto.UserTrackListDTO{}, err
	}

	tracks, nextRepoCursor, hasMore, err := u.userTrackRepo.ListByUserID(ctx, user.ID, limit, repoCursor)
	if err != nil {
		return usecasedto.UserTrackListDTO{}, err
	}

	dtos := make([]usecasedto.UserTrackDTO, len(tracks))
	for i, t := range tracks {
		dtos[i] = userTrackToDTO(t)
	}

	var nextCursorStr *string
	if nextRepoCursor != nil {
		encoded, err := encodeUserTrackCursor(nextRepoCursor)
		if err != nil {
			return usecasedto.UserTrackListDTO{}, err
		}
		nextCursorStr = &encoded
	}

	return usecasedto.UserTrackListDTO{
		Tracks:     dtos,
		NextCursor: nextCursorStr,
		HasMore:    hasMore,
	}, nil
}

func (u *userTrackUsecase) DeleteTrack(ctx context.Context, authUID, trackID string) error {
	user, err := u.userRepo.FindByAuthProviderAndProviderUserID(ctx, firebaseProvider, authUID)
	if err != nil {
		return err
	}
	return u.userTrackRepo.DeleteByUserIDAndTrackID(ctx, user.ID, trackID)
}

func (u *userTrackUsecase) GetSharedTrack(ctx context.Context, authUID string) (*usecasedto.SharedTrackDTO, error) {
	user, err := u.userRepo.FindByAuthProviderAndProviderUserID(ctx, firebaseProvider, authUID)
	if err != nil {
		return nil, err
	}

	current, found, err := u.sharedTrackRepo.FindCurrentWithTimestampByUserID(ctx, user.ID)
	if err != nil {
		return nil, err
	}
	if !found || current.Track == nil {
		return nil, nil
	}

	dto := &usecasedto.SharedTrackDTO{
		ID:         current.Track.ID,
		Title:      current.Track.Title,
		ArtistName: current.Track.ArtistName,
		ArtworkURL: current.Track.ArtworkURL,
		PreviewURL: current.Track.PreviewURL,
		UpdatedAt:  current.UpdatedAt,
	}
	return dto, nil
}

func (u *userTrackUsecase) UpsertSharedTrack(ctx context.Context, authUID, trackID string) (usecasedto.SharedTrackDTO, bool, error) {
	user, err := u.userRepo.FindByAuthProviderAndProviderUserID(ctx, firebaseProvider, authUID)
	if err != nil {
		return usecasedto.SharedTrackDTO{}, false, err
	}

	// Verify the track exists in the catalog.
	if _, err := u.trackCatalogRepo.FindByID(ctx, trackID); err != nil {
		return usecasedto.SharedTrackDTO{}, false, err
	}

	current, isNew, err := u.sharedTrackRepo.Upsert(ctx, user.ID, trackID)
	if err != nil {
		return usecasedto.SharedTrackDTO{}, false, err
	}
	if current.Track == nil {
		return usecasedto.SharedTrackDTO{}, false, domainerrs.NotFound("track was not found")
	}

	dto := usecasedto.SharedTrackDTO{
		ID:         current.Track.ID,
		Title:      current.Track.Title,
		ArtistName: current.Track.ArtistName,
		ArtworkURL: current.Track.ArtworkURL,
		PreviewURL: current.Track.PreviewURL,
		UpdatedAt:  current.UpdatedAt,
	}
	return dto, isNew, nil
}

func (u *userTrackUsecase) DeleteSharedTrack(ctx context.Context, authUID string) error {
	user, err := u.userRepo.FindByAuthProviderAndProviderUserID(ctx, firebaseProvider, authUID)
	if err != nil {
		return err
	}
	return u.sharedTrackRepo.DeleteByUserID(ctx, user.ID)
}

func userTrackToDTO(ut entity.UserTrack) usecasedto.UserTrackDTO {
	dto := usecasedto.UserTrackDTO{
		ID:        ut.ID,
		CreatedAt: ut.CreatedAt,
	}
	if ut.Track != nil {
		dto.TrackID = ut.Track.ID
		dto.Title = ut.Track.Title
		dto.ArtistName = ut.Track.ArtistName
		dto.ArtworkURL = ut.Track.ArtworkURL
		dto.PreviewURL = ut.Track.PreviewURL
	}
	return dto
}

type userTrackCursorPayload struct {
	CreatedAt time.Time `json:"created_at"`
	ID        string    `json:"id"`
}

func decodeUserTrackCursor(raw *string) (*repository.UserTrackCursor, error) {
	if raw == nil || *raw == "" {
		return nil, nil
	}
	decoded, err := base64.RawURLEncoding.DecodeString(*raw)
	if err != nil {
		return nil, domainerrs.BadRequest("cursor is invalid")
	}
	var payload userTrackCursorPayload
	if err := json.Unmarshal(decoded, &payload); err != nil {
		return nil, domainerrs.BadRequest("cursor is invalid")
	}
	if payload.ID == "" || payload.CreatedAt.IsZero() {
		return nil, domainerrs.BadRequest("cursor is invalid")
	}
	return &repository.UserTrackCursor{
		CreatedAt: payload.CreatedAt,
		ID:        payload.ID,
	}, nil
}

func encodeUserTrackCursor(cursor *repository.UserTrackCursor) (string, error) {
	payload, err := json.Marshal(userTrackCursorPayload{
		CreatedAt: cursor.CreatedAt.UTC(),
		ID:        cursor.ID,
	})
	if err != nil {
		return "", err
	}
	return base64.RawURLEncoding.EncodeToString(payload), nil
}
