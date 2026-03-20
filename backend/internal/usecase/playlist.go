package usecase

import (
	"context"

	"github.com/google/uuid"
	"go.uber.org/zap"

	"hackathon/internal/domain/entity"
	domainerrs "hackathon/internal/domain/errs"
	"hackathon/internal/domain/repository"
	usecasedto "hackathon/internal/usecase/dto"
)

type PlaylistUsecase interface {
	// CreatePlaylist creates a new playlist for the authenticated user.
	CreatePlaylist(ctx context.Context, authUID string, input usecasedto.CreatePlaylistInput) (usecasedto.PlaylistDTO, error)

	// GetPlaylist returns a playlist by ID with its tracks.
	// Public playlists are accessible to any authenticated user; private ones only to the owner.
	GetPlaylist(ctx context.Context, authUID string, playlistID string) (usecasedto.PlaylistDTO, error)

	// ListMyPlaylists returns all playlists owned by the authenticated user.
	ListMyPlaylists(ctx context.Context, authUID string) ([]usecasedto.PlaylistDTO, error)

	// UpdatePlaylist updates a playlist's metadata. Only the owner can update.
	UpdatePlaylist(ctx context.Context, authUID string, playlistID string, input usecasedto.UpdatePlaylistInput) (usecasedto.PlaylistDTO, error)

	// DeletePlaylist deletes a playlist. Only the owner can delete.
	DeletePlaylist(ctx context.Context, authUID string, playlistID string) error

	// AddTrack adds a track to a playlist. Only the owner can add tracks.
	AddTrack(ctx context.Context, authUID string, playlistID string, trackID string) error

	// RemoveTrack removes a track from a playlist. Only the owner can remove tracks.
	RemoveTrack(ctx context.Context, authUID string, playlistID string, trackID string) error

	// AddFavorite favorites a playlist for the authenticated user.
	AddFavorite(ctx context.Context, authUID string, playlistID string) error

	// RemoveFavorite removes a playlist from the authenticated user's favorites.
	RemoveFavorite(ctx context.Context, authUID string, playlistID string) error
}

type playlistUsecase struct {
	log          *zap.Logger
	playlistRepo repository.PlaylistRepository
	userRepo     repository.UserRepository
}

func NewPlaylistUsecase(
	log *zap.Logger,
	playlistRepo repository.PlaylistRepository,
	userRepo repository.UserRepository,
) PlaylistUsecase {
	return &playlistUsecase{
		log:          log,
		playlistRepo: playlistRepo,
		userRepo:     userRepo,
	}
}

func (u *playlistUsecase) CreatePlaylist(ctx context.Context, authUID string, input usecasedto.CreatePlaylistInput) (usecasedto.PlaylistDTO, error) {
	user, err := u.userRepo.FindByAuthProviderAndProviderUserID(ctx, firebaseProvider, authUID)
	if err != nil {
		return usecasedto.PlaylistDTO{}, err
	}

	isPublic := true
	if input.IsPublic != nil {
		isPublic = *input.IsPublic
	}

	playlist := entity.NewPlaylist(user.ID, input.Name, input.Description, isPublic)
	if err := u.playlistRepo.Create(ctx, playlist); err != nil {
		return usecasedto.PlaylistDTO{}, err
	}

	return playlistToDTO(playlist), nil
}

func (u *playlistUsecase) GetPlaylist(ctx context.Context, authUID string, playlistID string) (usecasedto.PlaylistDTO, error) {
	user, err := u.userRepo.FindByAuthProviderAndProviderUserID(ctx, firebaseProvider, authUID)
	if err != nil {
		return usecasedto.PlaylistDTO{}, err
	}

	playlist, err := u.playlistRepo.FindByIDWithTracks(ctx, playlistID)
	if err != nil {
		return usecasedto.PlaylistDTO{}, err
	}

	if !playlist.IsPublic && playlist.UserID != user.ID {
		return usecasedto.PlaylistDTO{}, domainerrs.NotFound("Playlist was not found")
	}

	return playlistToDTO(playlist), nil
}

func (u *playlistUsecase) ListMyPlaylists(ctx context.Context, authUID string) ([]usecasedto.PlaylistDTO, error) {
	user, err := u.userRepo.FindByAuthProviderAndProviderUserID(ctx, firebaseProvider, authUID)
	if err != nil {
		return nil, err
	}

	playlists, err := u.playlistRepo.ListByUserID(ctx, user.ID)
	if err != nil {
		return nil, err
	}

	dtos := make([]usecasedto.PlaylistDTO, len(playlists))
	for i, p := range playlists {
		dtos[i] = playlistToDTO(p)
	}
	return dtos, nil
}

func (u *playlistUsecase) UpdatePlaylist(ctx context.Context, authUID string, playlistID string, input usecasedto.UpdatePlaylistInput) (usecasedto.PlaylistDTO, error) {
	user, err := u.userRepo.FindByAuthProviderAndProviderUserID(ctx, firebaseProvider, authUID)
	if err != nil {
		return usecasedto.PlaylistDTO{}, err
	}

	playlist, err := u.playlistRepo.FindByID(ctx, playlistID)
	if err != nil {
		return usecasedto.PlaylistDTO{}, err
	}

	if playlist.UserID != user.ID {
		return usecasedto.PlaylistDTO{}, domainerrs.Forbidden("You do not have permission to update this playlist")
	}

	updated, err := u.playlistRepo.Update(ctx, playlistID, repository.UpdatePlaylistParams{
		Name:        input.Name,
		Description: input.Description,
		IsPublic:    input.IsPublic,
	})
	if err != nil {
		return usecasedto.PlaylistDTO{}, err
	}

	return playlistToDTO(updated), nil
}

func (u *playlistUsecase) DeletePlaylist(ctx context.Context, authUID string, playlistID string) error {
	user, err := u.userRepo.FindByAuthProviderAndProviderUserID(ctx, firebaseProvider, authUID)
	if err != nil {
		return err
	}

	playlist, err := u.playlistRepo.FindByID(ctx, playlistID)
	if err != nil {
		return err
	}

	if playlist.UserID != user.ID {
		return domainerrs.Forbidden("You do not have permission to delete this playlist")
	}

	return u.playlistRepo.Delete(ctx, playlistID)
}

func (u *playlistUsecase) AddTrack(ctx context.Context, authUID string, playlistID string, trackID string) error {
	user, err := u.userRepo.FindByAuthProviderAndProviderUserID(ctx, firebaseProvider, authUID)
	if err != nil {
		return err
	}

	playlist, err := u.playlistRepo.FindByID(ctx, playlistID)
	if err != nil {
		return err
	}

	if playlist.UserID != user.ID {
		return domainerrs.Forbidden("You do not have permission to modify this playlist")
	}

	pt := entity.NewPlaylistTrack(playlistID, trackID, 0)
	return u.playlistRepo.AddTrack(ctx, pt)
}

func (u *playlistUsecase) RemoveTrack(ctx context.Context, authUID string, playlistID string, trackID string) error {
	user, err := u.userRepo.FindByAuthProviderAndProviderUserID(ctx, firebaseProvider, authUID)
	if err != nil {
		return err
	}

	playlist, err := u.playlistRepo.FindByID(ctx, playlistID)
	if err != nil {
		return err
	}

	if playlist.UserID != user.ID {
		return domainerrs.Forbidden("You do not have permission to modify this playlist")
	}

	return u.playlistRepo.RemoveTrack(ctx, playlistID, trackID)
}

func (u *playlistUsecase) AddFavorite(ctx context.Context, authUID string, playlistID string) error {
	user, err := u.userRepo.FindByAuthProviderAndProviderUserID(ctx, firebaseProvider, authUID)
	if err != nil {
		return err
	}

	playlist, err := u.playlistRepo.FindByID(ctx, playlistID)
	if err != nil {
		return err
	}

	if !playlist.IsPublic && playlist.UserID != user.ID {
		return domainerrs.NotFound("Playlist was not found")
	}

	id := uuid.NewString()
	return u.playlistRepo.AddFavorite(ctx, id, user.ID, playlistID)
}

func (u *playlistUsecase) RemoveFavorite(ctx context.Context, authUID string, playlistID string) error {
	user, err := u.userRepo.FindByAuthProviderAndProviderUserID(ctx, firebaseProvider, authUID)
	if err != nil {
		return err
	}

	return u.playlistRepo.RemoveFavorite(ctx, user.ID, playlistID)
}

func playlistToDTO(p entity.Playlist) usecasedto.PlaylistDTO {
	tracks := make([]usecasedto.PlaylistTrackDTO, len(p.Tracks))
	for i, t := range p.Tracks {
		dto := usecasedto.PlaylistTrackDTO{
			ID:        t.ID,
			TrackID:   t.TrackID,
			SortOrder: t.SortOrder,
			CreatedAt: t.CreatedAt,
		}
		if t.Track != nil {
			dto.Title = t.Track.Title
			dto.ArtistName = t.Track.ArtistName
			dto.ArtworkURL = t.Track.ArtworkURL
		}
		tracks[i] = dto
	}

	return usecasedto.PlaylistDTO{
		ID:          p.ID,
		UserID:      p.UserID,
		Name:        p.Name,
		Description: p.Description,
		IsPublic:    p.IsPublic,
		CreatedAt:   p.CreatedAt,
		UpdatedAt:   p.UpdatedAt,
		Tracks:      tracks,
	}
}
