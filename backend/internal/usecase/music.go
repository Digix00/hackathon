package usecase

import (
	"context"

	"github.com/google/uuid"

	domainerrs "hackathon/internal/domain/errs"
	"hackathon/internal/domain/repository"
	"hackathon/internal/domain/vo"
	"hackathon/internal/usecase/dto"
	"hackathon/internal/usecase/port"
)

// MusicUsecase は音楽サービス連携とトラック検索のビジネスロジック。
type MusicUsecase interface {
	// AuthorizeURL は指定プロバイダーの OAuth 認可 URL を返す。
	AuthorizeURL(ctx context.Context, authUID, provider string) (authorizeURL, state string, err error)

	// HandleCallback は OAuth コールバックを処理し、連携情報を保存する。
	// firebaseUID は state から抽出した値を使う（Authorization ヘッダーは不要）。
	HandleCallback(ctx context.Context, provider, code, state string) (firebaseUID string, err error)

	// ListMusicConnections は認証ユーザーの音楽サービス連携一覧を返す。
	ListMusicConnections(ctx context.Context, authUID string) ([]dto.MusicConnectionDTO, error)

	// DeleteMusicConnection は指定プロバイダーの連携を解除する。
	DeleteMusicConnection(ctx context.Context, authUID, provider string) error

	// SearchTracks は連携済み Spotify アカウントのトークンでトラック検索する。
	SearchTracks(ctx context.Context, authUID, query string, limit int, cursor string) (dto.TrackSearchResultDTO, error)

	// GetTrack はトラック詳細を返す（<provider>:track:<external_id> 形式の ID）。
	GetTrack(ctx context.Context, authUID, trackID string) (dto.TrackDTO, error)
}

type musicUsecase struct {
	userRepo           repository.UserRepository
	musicConnRepo      repository.MusicConnectionRepository
	trackRepo          repository.TrackRepository
	spotifyOAuthClient port.MusicOAuthClient
	spotifyTrackClient port.MusicTrackClient
}

// NewMusicUsecase は MusicUsecase を生成する。
func NewMusicUsecase(
	userRepo repository.UserRepository,
	musicConnRepo repository.MusicConnectionRepository,
	trackRepo repository.TrackRepository,
	spotifyOAuthClient port.MusicOAuthClient,
	spotifyTrackClient port.MusicTrackClient,
) MusicUsecase {
	return &musicUsecase{
		userRepo:           userRepo,
		musicConnRepo:      musicConnRepo,
		trackRepo:          trackRepo,
		spotifyOAuthClient: spotifyOAuthClient,
		spotifyTrackClient: spotifyTrackClient,
	}
}

func (u *musicUsecase) AuthorizeURL(ctx context.Context, authUID, provider string) (string, string, error) {
	p, err := vo.ParseMusicProvider(provider)
	if err != nil {
		return "", "", err
	}
	client := u.oauthClientFor(p)
	if client == nil {
		return "", "", domainerrs.BadRequest("provider not supported: " + provider)
	}
	return client.AuthorizeURL(ctx, authUID)
}

func (u *musicUsecase) HandleCallback(ctx context.Context, provider, code, state string) (string, error) {
	p, err := vo.ParseMusicProvider(provider)
	if err != nil {
		return "", err
	}
	client := u.oauthClientFor(p)
	if client == nil {
		return "", domainerrs.BadRequest("provider not supported: " + provider)
	}

	firebaseUID, err := client.ValidateState(state)
	if err != nil {
		return "", domainerrs.BadRequest("invalid state: " + err.Error())
	}

	user, err := u.userRepo.FindByAuthProviderAndProviderUserID(ctx, firebaseProvider, firebaseUID)
	if err != nil {
		return firebaseUID, err
	}

	tokenResult, err := client.ExchangeCode(ctx, code)
	if err != nil {
		return firebaseUID, domainerrs.Internal("token exchange failed: " + err.Error())
	}

	_, err = u.musicConnRepo.Upsert(ctx, repository.UpsertMusicConnectionParams{
		ID:               uuid.NewString(),
		UserID:           user.ID,
		Provider:         p,
		ProviderUserID:   tokenResult.ProviderUserID,
		ProviderUsername: tokenResult.ProviderUsername,
		AccessToken:      tokenResult.AccessToken,
		RefreshToken:     tokenResult.RefreshToken,
		ExpiresAt:        tokenResult.ExpiresAt,
	})
	return firebaseUID, err
}

func (u *musicUsecase) ListMusicConnections(ctx context.Context, authUID string) ([]dto.MusicConnectionDTO, error) {
	user, err := u.userRepo.FindByAuthProviderAndProviderUserID(ctx, firebaseProvider, authUID)
	if err != nil {
		return nil, err
	}

	conns, err := u.musicConnRepo.ListByUserID(ctx, user.ID)
	if err != nil {
		return nil, err
	}

	result := make([]dto.MusicConnectionDTO, len(conns))
	for i, c := range conns {
		result[i] = dto.MusicConnectionDTO{
			Provider:         string(c.Provider),
			ProviderUserID:   c.ProviderUserID,
			ProviderUsername: c.ProviderUsername,
			ExpiresAt:        c.ExpiresAt,
			UpdatedAt:        c.UpdatedAt,
		}
	}
	return result, nil
}

func (u *musicUsecase) DeleteMusicConnection(ctx context.Context, authUID, provider string) error {
	if _, err := vo.ParseMusicProvider(provider); err != nil {
		return err
	}
	user, err := u.userRepo.FindByAuthProviderAndProviderUserID(ctx, firebaseProvider, authUID)
	if err != nil {
		return err
	}
	return u.musicConnRepo.DeleteByUserIDAndProvider(ctx, user.ID, provider)
}

func (u *musicUsecase) SearchTracks(ctx context.Context, authUID, query string, limit int, cursor string) (dto.TrackSearchResultDTO, error) {
	if query == "" {
		return dto.TrackSearchResultDTO{}, domainerrs.BadRequest("q is required")
	}
	user, err := u.userRepo.FindByAuthProviderAndProviderUserID(ctx, firebaseProvider, authUID)
	if err != nil {
		return dto.TrackSearchResultDTO{}, err
	}
	conn, err := u.musicConnRepo.FindByUserIDAndProvider(ctx, user.ID, string(vo.MusicProviderSpotify))
	if err != nil {
		return dto.TrackSearchResultDTO{}, domainerrs.BadRequest("Spotify connection required. Please connect your Spotify account first.")
	}

	result, err := u.spotifyTrackClient.SearchTracks(ctx, conn.AccessToken, query, limit, cursor)
	if err != nil {
		return dto.TrackSearchResultDTO{}, domainerrs.Internal("track search failed: " + err.Error())
	}

	tracks := make([]dto.TrackDTO, len(result.Tracks))
	for i, t := range result.Tracks {
		tracks[i] = dto.TrackDTO{
			ID:         string(vo.MusicProviderSpotify) + ":track:" + t.ExternalID,
			Title:      t.Title,
			ArtistName: t.ArtistName,
			ArtworkURL: t.ArtworkURL,
			PreviewURL: t.PreviewURL,
			AlbumName:  t.AlbumName,
			DurationMs: t.DurationMs,
		}
		// トラックをキャッシュに保存（エラーは無視して処理を継続）
		_ = u.cacheTrack(ctx, string(vo.MusicProviderSpotify), t)
	}

	return dto.TrackSearchResultDTO{
		Tracks:     tracks,
		NextCursor: result.NextCursor,
		HasMore:    result.HasMore,
	}, nil
}

func (u *musicUsecase) GetTrack(ctx context.Context, authUID, trackID string) (dto.TrackDTO, error) {
	provider, externalID, err := parseTrackID(trackID)
	if err != nil {
		return dto.TrackDTO{}, domainerrs.BadRequest("invalid track id: " + err.Error())
	}

	user, err := u.userRepo.FindByAuthProviderAndProviderUserID(ctx, firebaseProvider, authUID)
	if err != nil {
		return dto.TrackDTO{}, err
	}

	conn, err := u.musicConnRepo.FindByUserIDAndProvider(ctx, user.ID, provider)
	if err != nil {
		return dto.TrackDTO{}, domainerrs.BadRequest(provider + " connection required")
	}

	var trackClient port.MusicTrackClient
	if provider == string(vo.MusicProviderSpotify) {
		trackClient = u.spotifyTrackClient
	} else {
		return dto.TrackDTO{}, domainerrs.BadRequest("provider not supported: " + provider)
	}

	detail, err := trackClient.GetTrack(ctx, conn.AccessToken, externalID)
	if err != nil {
		return dto.TrackDTO{}, domainerrs.Internal("get track failed: " + err.Error())
	}

	return dto.TrackDTO{
		ID:         trackID,
		Title:      detail.Title,
		ArtistName: detail.ArtistName,
		ArtworkURL: detail.ArtworkURL,
		PreviewURL: detail.PreviewURL,
		AlbumName:  detail.AlbumName,
		DurationMs: detail.DurationMs,
	}, nil
}

// ─── helpers ──────────────────────────────────────────────────────────────────

func (u *musicUsecase) oauthClientFor(p vo.MusicProvider) port.MusicOAuthClient {
	switch p {
	case vo.MusicProviderSpotify:
		return u.spotifyOAuthClient
	default:
		return nil
	}
}

func (u *musicUsecase) cacheTrack(ctx context.Context, provider string, t port.MusicTrackInfo) error {
	_, err := u.trackRepo.Upsert(ctx, repository.UpsertTrackParams{
		ID:         uuid.NewString(),
		ExternalID: t.ExternalID,
		Provider:   provider,
		Title:      t.Title,
		ArtistName: t.ArtistName,
		AlbumName:  t.AlbumName,
		ArtworkURL: t.ArtworkURL,
		DurationMs: t.DurationMs,
	})
	return err
}

func parseTrackID(id string) (provider, externalID string, err error) {
	// "<provider>:track:<external_id>"
	parts := splitN(id, ":", 3)
	if len(parts) != 3 || parts[1] != "track" {
		return "", "", domainerrs.BadRequest("expected format: <provider>:track:<external_id>")
	}
	return parts[0], parts[2], nil
}

func splitN(s, sep string, n int) []string {
	result := make([]string, 0, n)
	for i := 0; i < n-1; i++ {
		idx := -1
		for j := 0; j < len(s); j++ {
			if s[j] == sep[0] {
				idx = j
				break
			}
		}
		if idx < 0 {
			break
		}
		result = append(result, s[:idx])
		s = s[idx+1:]
	}
	result = append(result, s)
	return result
}
