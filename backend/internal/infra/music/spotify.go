package music

import (
	"context"
	"encoding/base64"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"net/url"
	"strconv"
	"strings"
	"time"

	"hackathon/internal/domain/entity"
	domainerrs "hackathon/internal/domain/errs"
	"hackathon/internal/usecase/port"
)

type SpotifyConfig struct {
	ClientID     string
	ClientSecret string
	RedirectURL  string
	AuthorizeURL string
	TokenURL     string
	APIBaseURL   string
	HTTPClient   *http.Client
}

type spotifyProvider struct {
	cfg SpotifyConfig
}

func NewSpotifyProvider(cfg SpotifyConfig) port.MusicProvider {
	if cfg.HTTPClient == nil {
		cfg.HTTPClient = http.DefaultClient
	}
	return &spotifyProvider{cfg: cfg}
}

func (p *spotifyProvider) Provider() string { return "spotify" }

func (p *spotifyProvider) BuildAuthorizeURL(input port.OAuthAuthorizeInput) (string, error) {
	if p.cfg.ClientID == "" || p.cfg.RedirectURL == "" || p.cfg.AuthorizeURL == "" {
		return "", domainerrs.Internal("spotify oauth is not configured")
	}
	values := url.Values{}
	values.Set("response_type", "code")
	values.Set("client_id", p.cfg.ClientID)
	values.Set("redirect_uri", p.cfg.RedirectURL)
	values.Set("scope", "user-read-email")
	values.Set("state", input.State)
	return p.cfg.AuthorizeURL + "?" + values.Encode(), nil
}

func (p *spotifyProvider) ExchangeCode(ctx context.Context, code string) (port.OAuthToken, error) {
	if p.cfg.ClientID == "" || p.cfg.ClientSecret == "" || p.cfg.TokenURL == "" || p.cfg.RedirectURL == "" {
		return port.OAuthToken{}, domainerrs.Internal("spotify oauth is not configured")
	}
	form := url.Values{}
	form.Set("grant_type", "authorization_code")
	form.Set("code", code)
	form.Set("redirect_uri", p.cfg.RedirectURL)

	request, err := http.NewRequestWithContext(ctx, http.MethodPost, p.cfg.TokenURL, strings.NewReader(form.Encode()))
	if err != nil {
		return port.OAuthToken{}, err
	}
	request.Header.Set("Content-Type", "application/x-www-form-urlencoded")
	basic := base64.StdEncoding.EncodeToString([]byte(p.cfg.ClientID + ":" + p.cfg.ClientSecret))
	request.Header.Set("Authorization", "Basic "+basic)

	var response struct {
		AccessToken  string `json:"access_token"`
		RefreshToken string `json:"refresh_token"`
		ExpiresIn    int    `json:"expires_in"`
	}
	if err := p.doJSON(request, &response); err != nil {
		return port.OAuthToken{}, err
	}
	var refreshToken *string
	if response.RefreshToken != "" {
		refreshToken = &response.RefreshToken
	}
	var expiresAt *time.Time
	if response.ExpiresIn > 0 {
		t := time.Now().UTC().Add(time.Duration(response.ExpiresIn) * time.Second)
		expiresAt = &t
	}
	return port.OAuthToken{AccessToken: response.AccessToken, RefreshToken: refreshToken, ExpiresAt: expiresAt}, nil
}

func (p *spotifyProvider) GetProfile(ctx context.Context, accessToken string) (port.AccountProfile, error) {
	if p.cfg.APIBaseURL == "" {
		return port.AccountProfile{}, domainerrs.Internal("spotify oauth is not configured")
	}
	request, err := http.NewRequestWithContext(ctx, http.MethodGet, strings.TrimRight(p.cfg.APIBaseURL, "/")+"/me", nil)
	if err != nil {
		return port.AccountProfile{}, err
	}
	request.Header.Set("Authorization", "Bearer "+accessToken)
	var response struct {
		ID          string  `json:"id"`
		DisplayName *string `json:"display_name"`
	}
	if err := p.doJSON(request, &response); err != nil {
		return port.AccountProfile{}, err
	}
	return port.AccountProfile{UserID: response.ID, Username: response.DisplayName}, nil
}

func (p *spotifyProvider) SearchTracks(ctx context.Context, accessToken, query string, limit int, cursor *string) (port.SearchTracksResult, error) {
	values := url.Values{}
	values.Set("q", query)
	values.Set("type", "track")
	values.Set("limit", strconv.Itoa(limit))
	if cursor != nil && *cursor != "" {
		offsetBytes, err := base64.RawURLEncoding.DecodeString(*cursor)
		if err != nil {
			return port.SearchTracksResult{}, domainerrs.BadRequest("invalid cursor")
		}
		values.Set("offset", string(offsetBytes))
	}
	endpoint := strings.TrimRight(p.cfg.APIBaseURL, "/") + "/search?" + values.Encode()
	request, err := http.NewRequestWithContext(ctx, http.MethodGet, endpoint, nil)
	if err != nil {
		return port.SearchTracksResult{}, err
	}
	request.Header.Set("Authorization", "Bearer "+accessToken)
	var response struct {
		Tracks struct {
			Items  []spotifyTrack `json:"items"`
			Next   *string        `json:"next"`
			Offset int            `json:"offset"`
			Limit  int            `json:"limit"`
			Total  int            `json:"total"`
		} `json:"tracks"`
	}
	if err := p.doJSON(request, &response); err != nil {
		return port.SearchTracksResult{}, err
	}
	tracks := make([]entity.TrackInfo, 0, len(response.Tracks.Items))
	for _, item := range response.Tracks.Items {
		tracks = append(tracks, item.toEntity())
	}
	var nextCursor *string
	if response.Tracks.Next != nil && response.Tracks.Offset+response.Tracks.Limit < response.Tracks.Total {
		next := base64.RawURLEncoding.EncodeToString([]byte(strconv.Itoa(response.Tracks.Offset + response.Tracks.Limit)))
		nextCursor = &next
	}
	return port.SearchTracksResult{Tracks: tracks, NextCursor: nextCursor, HasMore: nextCursor != nil}, nil
}

func (p *spotifyProvider) GetTrack(ctx context.Context, accessToken, externalID string) (entity.TrackInfo, error) {
	request, err := http.NewRequestWithContext(ctx, http.MethodGet, strings.TrimRight(p.cfg.APIBaseURL, "/")+"/tracks/"+url.PathEscape(externalID), nil)
	if err != nil {
		return entity.TrackInfo{}, err
	}
	request.Header.Set("Authorization", "Bearer "+accessToken)
	var response spotifyTrack
	if err := p.doJSON(request, &response); err != nil {
		return entity.TrackInfo{}, err
	}
	return response.toEntity(), nil
}

type spotifyTrack struct {
	ID         string  `json:"id"`
	Name       string  `json:"name"`
	DurationMS int     `json:"duration_ms"`
	PreviewURL *string `json:"preview_url"`
	Album      struct {
		Name   *string `json:"name"`
		Images []struct {
			URL string `json:"url"`
		} `json:"images"`
	} `json:"album"`
	Artists []struct {
		Name string `json:"name"`
	} `json:"artists"`
}

func (t spotifyTrack) toEntity() entity.TrackInfo {
	var artworkURL *string
	if len(t.Album.Images) > 0 && t.Album.Images[0].URL != "" {
		artworkURL = &t.Album.Images[0].URL
	}
	artistName := ""
	if len(t.Artists) > 0 {
		artistName = t.Artists[0].Name
	}
	duration := t.DurationMS
	return entity.TrackInfo{
		ID:         "spotify:track:" + t.ID,
		Title:      t.Name,
		ArtistName: artistName,
		ArtworkURL: artworkURL,
		PreviewURL: t.PreviewURL,
		AlbumName:  t.Album.Name,
		DurationMs: &duration,
	}
}

func (p *spotifyProvider) doJSON(request *http.Request, dest any) error {
	response, err := p.cfg.HTTPClient.Do(request)
	if err != nil {
		return domainerrs.Internal(err.Error())
	}
	defer func() { _ = response.Body.Close() }()
	body, err := io.ReadAll(response.Body)
	if err != nil {
		return err
	}
	if response.StatusCode >= 400 {
		switch response.StatusCode {
		case http.StatusUnauthorized:
			return domainerrs.Unauthorized("music provider unauthorized")
		case http.StatusNotFound:
			return domainerrs.NotFound("track was not found")
		case http.StatusBadRequest:
			return domainerrs.BadRequest(fmt.Sprintf("music provider rejected the request: %s", string(body)))
		case http.StatusTooManyRequests:
			return domainerrs.Internal("music provider rate limit exceeded; please retry later")
		default:
			return domainerrs.Internal(fmt.Sprintf("music provider request failed: status=%d body=%s", response.StatusCode, string(body)))
		}
	}
	if err := json.Unmarshal(body, dest); err != nil {
		return err
	}
	return nil
}
