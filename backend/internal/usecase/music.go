package usecase

import (
	"context"
	"crypto/hmac"
	"crypto/sha256"
	"encoding/base64"
	"encoding/json"
	"net/url"
	"strings"
	"time"

	"go.uber.org/zap"

	"hackathon/internal/domain/entity"
	domainerrs "hackathon/internal/domain/errs"
	"hackathon/internal/domain/repository"
	usecasedto "hackathon/internal/usecase/dto"
	"hackathon/internal/usecase/port"
)

const (
	musicProviderSpotify    = "spotify"
	musicProviderAppleMusic = "apple_music"
	musicStateTTL           = 10 * time.Minute
)

type MusicUsecase interface {
	GetAuthorizeURL(ctx context.Context, authUID, provider string) (usecasedto.MusicAuthorizeResult, error)
	HandleCallback(ctx context.Context, provider, code, state string) error
	CallbackRedirectURL(provider, result, errorCode string) string
	ListConnections(ctx context.Context, authUID string) ([]usecasedto.MusicConnectionDTO, error)
	DeleteConnection(ctx context.Context, authUID, provider string) error
	SearchTracks(ctx context.Context, authUID, query string, limit int, cursor *string) (usecasedto.TrackSearchResultDTO, error)
	GetTrack(ctx context.Context, authUID, trackID string) (usecasedto.TrackDTO, error)
}

type musicUsecase struct {
	log                 *zap.Logger
	userRepo            repository.UserRepository
	musicConnectionRepo repository.MusicConnectionRepository
	trackCatalogRepo    repository.TrackCatalogRepository
	providers           map[string]port.MusicProvider
	stateSecret         []byte
	appDeepLinkScheme   string
	now                 func() time.Time
}

type musicStatePayload struct {
	Provider string `json:"provider"`
	AuthUID  string `json:"auth_uid"`
	Nonce    string `json:"nonce"`
	Exp      int64  `json:"exp"`
}

func NewMusicUsecase(
	log *zap.Logger,
	userRepo repository.UserRepository,
	musicConnectionRepo repository.MusicConnectionRepository,
	trackCatalogRepo repository.TrackCatalogRepository,
	providers []port.MusicProvider,
	stateSecret string,
	appDeepLinkScheme string,
) MusicUsecase {
	providerMap := make(map[string]port.MusicProvider, len(providers))
	for _, provider := range providers {
		if provider == nil {
			continue
		}
		providerMap[provider.Provider()] = provider
	}
	return &musicUsecase{
		log:                 log,
		userRepo:            userRepo,
		musicConnectionRepo: musicConnectionRepo,
		trackCatalogRepo:    trackCatalogRepo,
		providers:           providerMap,
		stateSecret:         []byte(stateSecret),
		appDeepLinkScheme:   appDeepLinkScheme,
		now:                 func() time.Time { return time.Now().UTC() },
	}
}

func (u *musicUsecase) GetAuthorizeURL(ctx context.Context, authUID, provider string) (usecasedto.MusicAuthorizeResult, error) {
	musicProvider, err := u.providerFor(provider)
	if err != nil {
		return usecasedto.MusicAuthorizeResult{}, err
	}
	if _, err := u.userRepo.FindByAuthProviderAndProviderUserID(ctx, firebaseProvider, authUID); err != nil {
		return usecasedto.MusicAuthorizeResult{}, err
	}

	state, err := u.signState(musicStatePayload{
		Provider: provider,
		AuthUID:  authUID,
		Nonce:    time.Now().UTC().Format(time.RFC3339Nano),
		Exp:      u.now().Add(musicStateTTL).Unix(),
	})
	if err != nil {
		return usecasedto.MusicAuthorizeResult{}, err
	}
	authorizeURL, err := musicProvider.BuildAuthorizeURL(port.OAuthAuthorizeInput{State: state})
	if err != nil {
		return usecasedto.MusicAuthorizeResult{}, err
	}
	return usecasedto.MusicAuthorizeResult{AuthorizeURL: authorizeURL, State: state}, nil
}

func (u *musicUsecase) HandleCallback(ctx context.Context, provider, code, state string) error {
	musicProvider, err := u.providerFor(provider)
	if err != nil {
		return err
	}
	if strings.TrimSpace(code) == "" {
		return domainerrs.BadRequest("code is required")
	}
	payload, err := u.verifyState(state)
	if err != nil {
		return err
	}
	if payload.Provider != provider {
		return domainerrs.BadRequest("state provider does not match callback provider")
	}
	user, err := u.userRepo.FindByAuthProviderAndProviderUserID(ctx, firebaseProvider, payload.AuthUID)
	if err != nil {
		return err
	}
	token, err := musicProvider.ExchangeCode(ctx, code)
	if err != nil {
		return err
	}
	profile, err := musicProvider.GetProfile(ctx, token.AccessToken)
	if err != nil {
		// プロフィール取得に失敗してもアクセストークンは保存する（Premium 制限等への対処）
		profile = port.AccountProfile{}
	}
	_, err = u.musicConnectionRepo.Upsert(ctx, repository.UpsertMusicConnectionParams{
		UserID:           user.ID,
		Provider:         provider,
		ProviderUserID:   profile.UserID,
		ProviderUsername: profile.Username,
		AccessToken:      token.AccessToken,
		RefreshToken:     token.RefreshToken,
		ExpiresAt:        token.ExpiresAt,
	})
	return err
}

func (u *musicUsecase) ListConnections(ctx context.Context, authUID string) ([]usecasedto.MusicConnectionDTO, error) {
	user, err := u.userRepo.FindByAuthProviderAndProviderUserID(ctx, firebaseProvider, authUID)
	if err != nil {
		return nil, err
	}
	connections, err := u.musicConnectionRepo.ListByUserID(ctx, user.ID)
	if err != nil {
		return nil, err
	}
	result := make([]usecasedto.MusicConnectionDTO, 0, len(connections))
	for _, connection := range connections {
		result = append(result, usecasedto.MusicConnectionDTO{
			Provider:         connection.Provider,
			ProviderUserID:   connection.ProviderUserID,
			ProviderUsername: connection.ProviderUsername,
			ExpiresAt:        connection.ExpiresAt,
			UpdatedAt:        connection.UpdatedAt,
		})
	}
	return result, nil
}

func (u *musicUsecase) DeleteConnection(ctx context.Context, authUID, provider string) error {
	if _, err := u.providerFor(provider); err != nil {
		return err
	}
	user, err := u.userRepo.FindByAuthProviderAndProviderUserID(ctx, firebaseProvider, authUID)
	if err != nil {
		return err
	}
	return u.musicConnectionRepo.DeleteByUserIDAndProvider(ctx, user.ID, provider)
}

func (u *musicUsecase) SearchTracks(ctx context.Context, authUID, query string, limit int, cursor *string) (usecasedto.TrackSearchResultDTO, error) {
	if strings.TrimSpace(query) == "" {
		return usecasedto.TrackSearchResultDTO{}, domainerrs.BadRequest("q is required")
	}
	if limit <= 0 {
		limit = 20
	}
	if limit > 50 {
		return usecasedto.TrackSearchResultDTO{}, domainerrs.BadRequest("limit must be less than or equal to 50")
	}

	provider, connection, err := u.connectedProvider(ctx, authUID, musicProviderSpotify)
	if err != nil {
		return usecasedto.TrackSearchResultDTO{}, err
	}
	result, err := provider.SearchTracks(ctx, connection.AccessToken, query, limit, cursor)
	if err != nil {
		return usecasedto.TrackSearchResultDTO{}, err
	}
	tracks := make([]usecasedto.TrackDTO, 0, len(result.Tracks))
	for _, track := range result.Tracks {
		cached, err := u.trackCatalogRepo.Upsert(ctx, track)
		if err != nil {
			return usecasedto.TrackSearchResultDTO{}, err
		}
		tracks = append(tracks, entityTrackToDTO(cached))
	}
	return usecasedto.TrackSearchResultDTO{Tracks: tracks, NextCursor: result.NextCursor, HasMore: result.HasMore}, nil
}

func (u *musicUsecase) GetTrack(ctx context.Context, authUID, trackID string) (usecasedto.TrackDTO, error) {
	providerName, externalID, err := parseTrackID(trackID)
	if err != nil {
		return usecasedto.TrackDTO{}, err
	}
	provider, connection, err := u.connectedProvider(ctx, authUID, providerName)
	if err != nil {
		return usecasedto.TrackDTO{}, err
	}
	track, err := provider.GetTrack(ctx, connection.AccessToken, externalID)
	if err != nil {
		return usecasedto.TrackDTO{}, err
	}
	cached, err := u.trackCatalogRepo.Upsert(ctx, track)
	if err != nil {
		return usecasedto.TrackDTO{}, err
	}
	return entityTrackToDTO(cached), nil
}

func (u *musicUsecase) providerFor(provider string) (port.MusicProvider, error) {
	musicProvider, ok := u.providers[provider]
	if !ok {
		return nil, domainerrs.BadRequest("unsupported provider")
	}
	return musicProvider, nil
}

func (u *musicUsecase) connectedProvider(ctx context.Context, authUID, provider string) (port.MusicProvider, entity.MusicConnection, error) {
	musicProvider, err := u.providerFor(provider)
	if err != nil {
		return nil, entity.MusicConnection{}, err
	}
	user, err := u.userRepo.FindByAuthProviderAndProviderUserID(ctx, firebaseProvider, authUID)
	if err != nil {
		return nil, entity.MusicConnection{}, err
	}
	connection, err := u.musicConnectionRepo.FindByUserIDAndProvider(ctx, user.ID, provider)
	if err != nil {
		return nil, entity.MusicConnection{}, err
	}
	return musicProvider, connection, nil
}

func entityTrackToDTO(track entity.TrackInfo) usecasedto.TrackDTO {
	return usecasedto.TrackDTO{
		ID:         track.ID,
		Title:      track.Title,
		ArtistName: track.ArtistName,
		ArtworkURL: track.ArtworkURL,
		PreviewURL: track.PreviewURL,
		AlbumName:  track.AlbumName,
		DurationMs: track.DurationMs,
	}
}

func parseTrackID(trackID string) (string, string, error) {
	parts := strings.Split(trackID, ":")
	if len(parts) != 3 || parts[1] != "track" || parts[0] == "" || parts[2] == "" {
		return "", "", domainerrs.BadRequest("track id must be <provider>:track:<external_id>")
	}
	provider := parts[0]
	if provider != musicProviderSpotify && provider != musicProviderAppleMusic {
		return "", "", domainerrs.BadRequest("unsupported provider")
	}
	return provider, parts[2], nil
}

func (u *musicUsecase) CallbackRedirectURL(provider string, result string, errorCode string) string {
	values := url.Values{}
	values.Set("result", result)
	if errorCode != "" {
		values.Set("error_code", errorCode)
	}
	return u.appDeepLinkScheme + "://music-connections/" + provider + "/callback?" + values.Encode()
}

func (u *musicUsecase) signState(payload musicStatePayload) (string, error) {
	raw, err := json.Marshal(payload)
	if err != nil {
		return "", err
	}
	encodedPayload := base64.RawURLEncoding.EncodeToString(raw)
	mac := hmac.New(sha256.New, u.stateSecret)
	if _, err := mac.Write([]byte(encodedPayload)); err != nil {
		return "", err
	}
	signature := base64.RawURLEncoding.EncodeToString(mac.Sum(nil))
	return encodedPayload + "." + signature, nil
}

func (u *musicUsecase) verifyState(state string) (musicStatePayload, error) {
	parts := strings.Split(state, ".")
	if len(parts) != 2 {
		return musicStatePayload{}, domainerrs.BadRequest("invalid state")
	}
	mac := hmac.New(sha256.New, u.stateSecret)
	if _, err := mac.Write([]byte(parts[0])); err != nil {
		return musicStatePayload{}, err
	}
	expected := mac.Sum(nil)
	actual, err := base64.RawURLEncoding.DecodeString(parts[1])
	if err != nil || !hmac.Equal(actual, expected) {
		return musicStatePayload{}, domainerrs.BadRequest("invalid state signature")
	}
	payloadBytes, err := base64.RawURLEncoding.DecodeString(parts[0])
	if err != nil {
		return musicStatePayload{}, domainerrs.BadRequest("invalid state payload")
	}
	var payload musicStatePayload
	if err := json.Unmarshal(payloadBytes, &payload); err != nil {
		return musicStatePayload{}, domainerrs.BadRequest("invalid state payload")
	}
	if payload.Provider == "" || payload.AuthUID == "" || payload.Exp == 0 {
		return musicStatePayload{}, domainerrs.BadRequest("invalid state payload")
	}
	if u.now().Unix() > payload.Exp {
		return musicStatePayload{}, domainerrs.BadRequest("state has expired")
	}
	return payload, nil
}
