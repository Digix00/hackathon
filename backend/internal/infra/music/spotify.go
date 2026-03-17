package music

import (
	"context"
	"crypto/hmac"
	"crypto/sha256"
	"encoding/base64"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"net/url"
	"strconv"
	"strings"
	"time"

	"github.com/google/uuid"
	"golang.org/x/oauth2"

	"hackathon/internal/usecase/port"
)

var spotifyOAuth2Endpoint = oauth2.Endpoint{
	AuthURL:  "https://accounts.spotify.com/authorize",
	TokenURL: "https://accounts.spotify.com/api/token",
}

const (
	spotifyAPIBase = "https://api.spotify.com/v1"
)

// SpotifyOAuthClient は Spotify OAuth 連携と トラック検索を実装する。
type SpotifyOAuthClient struct {
	oauthCfg    *oauth2.Config
	stateSecret []byte
}

// NewSpotifyOAuthClient は SpotifyOAuthClient を生成する。
func NewSpotifyOAuthClient(clientID, clientSecret, redirectURI, stateSecret string) *SpotifyOAuthClient {
	cfg := &oauth2.Config{
		ClientID:     clientID,
		ClientSecret: clientSecret,
		RedirectURL:  redirectURI,
		Scopes: []string{
			"user-read-private",
			"user-read-email",
			"streaming",
			"user-library-read",
		},
		Endpoint: spotifyOAuth2Endpoint,
	}
	return &SpotifyOAuthClient{
		oauthCfg:    cfg,
		stateSecret: []byte(stateSecret),
	}
}

// AuthorizeURL は OAuth 認可 URL と署名付き state を生成する。
func (c *SpotifyOAuthClient) AuthorizeURL(_ context.Context, userFirebaseUID string) (string, string, error) {
	nonce := uuid.NewString()
	payload := userFirebaseUID + ":" + nonce
	sig := c.sign(payload)
	state := base64.URLEncoding.EncodeToString([]byte(payload + ":" + sig))

	authURL := c.oauthCfg.AuthCodeURL(state, oauth2.AccessTypeOffline)
	return authURL, state, nil
}

// ValidateState は state を検証し、Firebase UID を返す。
func (c *SpotifyOAuthClient) ValidateState(state string) (string, error) {
	decoded, err := base64.URLEncoding.DecodeString(state)
	if err != nil {
		return "", fmt.Errorf("invalid state encoding: %w", err)
	}

	parts := strings.SplitN(string(decoded), ":", 3)
	if len(parts) != 3 {
		return "", fmt.Errorf("invalid state format")
	}
	firebaseUID, nonce, sig := parts[0], parts[1], parts[2]
	_ = nonce

	payload := firebaseUID + ":" + nonce
	expected := c.sign(payload)
	if !hmac.Equal([]byte(sig), []byte(expected)) {
		return "", fmt.Errorf("invalid state signature")
	}
	return firebaseUID, nil
}

// ExchangeCode は認可コードをアクセストークンに交換する。
func (c *SpotifyOAuthClient) ExchangeCode(ctx context.Context, code string) (*port.MusicTokenResult, error) {
	token, err := c.oauthCfg.Exchange(ctx, code)
	if err != nil {
		return nil, fmt.Errorf("spotify token exchange failed: %w", err)
	}

	client := c.oauthCfg.Client(ctx, token)
	profile, err := fetchSpotifyProfile(client)
	if err != nil {
		return nil, err
	}

	var refreshToken *string
	if rt := token.RefreshToken; rt != "" {
		refreshToken = &rt
	}
	var expiresAt *time.Time
	if !token.Expiry.IsZero() {
		t := token.Expiry
		expiresAt = &t
	}

	return &port.MusicTokenResult{
		AccessToken:      token.AccessToken,
		RefreshToken:     refreshToken,
		ExpiresAt:        expiresAt,
		ProviderUserID:   profile.ID,
		ProviderUsername: &profile.DisplayName,
	}, nil
}

// RefreshToken はアクセストークンをリフレッシュする。
func (c *SpotifyOAuthClient) RefreshToken(ctx context.Context, refreshToken string) (*port.MusicTokenResult, error) {
	existing := &oauth2.Token{RefreshToken: refreshToken}
	tokenSrc := c.oauthCfg.TokenSource(ctx, existing)
	token, err := tokenSrc.Token()
	if err != nil {
		return nil, fmt.Errorf("spotify token refresh failed: %w", err)
	}

	var rt *string
	if token.RefreshToken != "" {
		rt = &token.RefreshToken
	}
	var expiresAt *time.Time
	if !token.Expiry.IsZero() {
		t := token.Expiry
		expiresAt = &t
	}
	return &port.MusicTokenResult{
		AccessToken:  token.AccessToken,
		RefreshToken: rt,
		ExpiresAt:    expiresAt,
	}, nil
}

// SearchTracks は Spotify Web API でトラック検索する。
func (c *SpotifyOAuthClient) SearchTracks(ctx context.Context, accessToken string, query string, limit int, cursor string) (*port.MusicTrackSearchResult, error) {
	if limit <= 0 || limit > 50 {
		limit = 20
	}

	offset := 0
	if cursor != "" {
		if v, err := strconv.Atoi(cursor); err == nil {
			offset = v
		}
	}

	params := url.Values{}
	params.Set("q", query)
	params.Set("type", "track")
	params.Set("limit", strconv.Itoa(limit))
	params.Set("offset", strconv.Itoa(offset))

	reqURL := spotifyAPIBase + "/search?" + params.Encode()
	req, err := http.NewRequestWithContext(ctx, http.MethodGet, reqURL, nil)
	if err != nil {
		return nil, err
	}
	req.Header.Set("Authorization", "Bearer "+accessToken)

	resp, err := http.DefaultClient.Do(req)
	if err != nil {
		return nil, err
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		body, _ := io.ReadAll(resp.Body)
		return nil, fmt.Errorf("spotify search failed (status=%d): %s", resp.StatusCode, string(body))
	}

	var result spotifySearchResponse
	if err := json.NewDecoder(resp.Body).Decode(&result); err != nil {
		return nil, err
	}

	tracks := make([]port.MusicTrackInfo, len(result.Tracks.Items))
	for i, item := range result.Tracks.Items {
		tracks[i] = spotifyItemToTrackInfo(item)
	}

	nextOffset := offset + limit
	nextCursor := strconv.Itoa(nextOffset)
	hasMore := result.Tracks.Next != ""

	return &port.MusicTrackSearchResult{
		Tracks:     tracks,
		NextCursor: &nextCursor,
		HasMore:    hasMore,
	}, nil
}

// GetTrack は単一トラックの詳細を返す。
func (c *SpotifyOAuthClient) GetTrack(ctx context.Context, accessToken string, externalID string) (*port.MusicTrackDetail, error) {
	req, err := http.NewRequestWithContext(ctx, http.MethodGet, spotifyAPIBase+"/tracks/"+externalID, nil)
	if err != nil {
		return nil, err
	}
	req.Header.Set("Authorization", "Bearer "+accessToken)

	resp, err := http.DefaultClient.Do(req)
	if err != nil {
		return nil, err
	}
	defer resp.Body.Close()

	if resp.StatusCode == http.StatusNotFound {
		return nil, fmt.Errorf("track not found: %s", externalID)
	}
	if resp.StatusCode != http.StatusOK {
		body, _ := io.ReadAll(resp.Body)
		return nil, fmt.Errorf("spotify get track failed (status=%d): %s", resp.StatusCode, string(body))
	}

	var item spotifyTrackItem
	if err := json.NewDecoder(resp.Body).Decode(&item); err != nil {
		return nil, err
	}

	info := spotifyItemToTrackInfo(item)
	return &port.MusicTrackDetail{
		ExternalID: info.ExternalID,
		Title:      info.Title,
		ArtistName: info.ArtistName,
		ArtworkURL: info.ArtworkURL,
		PreviewURL: info.PreviewURL,
		AlbumName:  info.AlbumName,
		DurationMs: info.DurationMs,
	}, nil
}

// ─── helpers ──────────────────────────────────────────────────────────────────

func (c *SpotifyOAuthClient) sign(payload string) string {
	mac := hmac.New(sha256.New, c.stateSecret)
	mac.Write([]byte(payload))
	return base64.URLEncoding.EncodeToString(mac.Sum(nil))
}

func fetchSpotifyProfile(client *http.Client) (*spotifyProfileResponse, error) {
	resp, err := client.Get(spotifyAPIBase + "/me")
	if err != nil {
		return nil, fmt.Errorf("spotify profile fetch failed: %w", err)
	}
	defer resp.Body.Close()

	var profile spotifyProfileResponse
	if err := json.NewDecoder(resp.Body).Decode(&profile); err != nil {
		return nil, err
	}
	return &profile, nil
}

func spotifyItemToTrackInfo(item spotifyTrackItem) port.MusicTrackInfo {
	var artworkURL *string
	if len(item.Album.Images) > 0 {
		u := item.Album.Images[0].URL
		artworkURL = &u
	}
	var previewURL *string
	if item.PreviewURL != "" {
		previewURL = &item.PreviewURL
	}
	var albumName *string
	if item.Album.Name != "" {
		albumName = &item.Album.Name
	}

	artistNames := make([]string, len(item.Artists))
	for i, a := range item.Artists {
		artistNames[i] = a.Name
	}
	artistName := strings.Join(artistNames, ", ")

	return port.MusicTrackInfo{
		ExternalID: item.ID,
		Title:      item.Name,
		ArtistName: artistName,
		ArtworkURL: artworkURL,
		PreviewURL: previewURL,
		AlbumName:  albumName,
		DurationMs: &item.DurationMs,
	}
}

// ─── Spotify API response structs ─────────────────────────────────────────────

type spotifyProfileResponse struct {
	ID          string `json:"id"`
	DisplayName string `json:"display_name"`
}

type spotifySearchResponse struct {
	Tracks struct {
		Items []spotifyTrackItem `json:"items"`
		Next  string             `json:"next"`
		Total int                `json:"total"`
	} `json:"tracks"`
}

type spotifyTrackItem struct {
	ID         string `json:"id"`
	Name       string `json:"name"`
	PreviewURL string `json:"preview_url"`
	DurationMs int    `json:"duration_ms"`
	Album      struct {
		Name   string `json:"name"`
		Images []struct {
			URL string `json:"url"`
		} `json:"images"`
	} `json:"album"`
	Artists []struct {
		Name string `json:"name"`
	} `json:"artists"`
}
