package music

import (
	"context"
	"encoding/base64"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"net/url"
	"strings"
	"time"

	"hackathon/internal/domain/entity"
	domainerrs "hackathon/internal/domain/errs"
	"hackathon/internal/usecase/port"
)

type AppleMusicConfig struct {
	ClientID     string
	ClientSecret string
	RedirectURL  string
	AuthorizeURL string
	TokenURL     string
	APIBaseURL   string
	HTTPClient   *http.Client
}

type appleMusicProvider struct {
	cfg AppleMusicConfig
}

func NewAppleMusicProvider(cfg AppleMusicConfig) port.MusicProvider {
	if cfg.HTTPClient == nil {
		cfg.HTTPClient = http.DefaultClient
	}
	return &appleMusicProvider{cfg: cfg}
}

func (p *appleMusicProvider) Provider() string { return "apple_music" }

func (p *appleMusicProvider) BuildAuthorizeURL(input port.OAuthAuthorizeInput) (string, error) {
	if p.cfg.ClientID == "" || p.cfg.AuthorizeURL == "" || p.cfg.RedirectURL == "" {
		return "", domainerrs.Internal("apple music oauth is not configured")
	}
	values := url.Values{}
	values.Set("response_type", "code")
	values.Set("client_id", p.cfg.ClientID)
	values.Set("redirect_uri", p.cfg.RedirectURL)
	values.Set("state", input.State)
	return p.cfg.AuthorizeURL + "?" + values.Encode(), nil
}

func (p *appleMusicProvider) ExchangeCode(ctx context.Context, code string) (port.OAuthToken, error) {
	if p.cfg.TokenURL == "" {
		return port.OAuthToken{}, domainerrs.Internal("apple music token endpoint is not configured")
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

func (p *appleMusicProvider) GetProfile(ctx context.Context, accessToken string) (port.AccountProfile, error) {
	if p.cfg.APIBaseURL == "" {
		return port.AccountProfile{}, domainerrs.Internal("apple music api base url is not configured")
	}
	request, err := http.NewRequestWithContext(ctx, http.MethodGet, strings.TrimRight(p.cfg.APIBaseURL, "/")+"/me", nil)
	if err != nil {
		return port.AccountProfile{}, err
	}
	request.Header.Set("Authorization", "Bearer "+accessToken)
	var response struct {
		ID       string  `json:"id"`
		Username *string `json:"username"`
		Name     *string `json:"name"`
	}
	if err := p.doJSON(request, &response); err != nil {
		return port.AccountProfile{}, err
	}
	username := response.Username
	if username == nil {
		username = response.Name
	}
	return port.AccountProfile{UserID: response.ID, Username: username}, nil
}

func (p *appleMusicProvider) SearchTracks(context.Context, string, string, int, *string) (port.SearchTracksResult, error) {
	return port.SearchTracksResult{}, domainerrs.BadRequest("apple music track search is not supported by this backend endpoint")
}

func (p *appleMusicProvider) GetTrack(context.Context, string, string) (entity.TrackInfo, error) {
	return entity.TrackInfo{}, domainerrs.BadRequest("apple music track detail is not supported by this backend endpoint")
}

func (p *appleMusicProvider) doJSON(request *http.Request, dest any) error {
	response, err := p.cfg.HTTPClient.Do(request)
	if err != nil {
		return domainerrs.Internal(err.Error())
	}
	defer response.Body.Close()
	body, err := io.ReadAll(response.Body)
	if err != nil {
		return err
	}
	if response.StatusCode >= 400 {
		if response.StatusCode == http.StatusUnauthorized {
			return domainerrs.Unauthorized("music provider unauthorized")
		}
		return domainerrs.Internal(fmt.Sprintf("music provider request failed: status=%d body=%s", response.StatusCode, string(body)))
	}
	if err := json.Unmarshal(body, dest); err != nil {
		return err
	}
	return nil
}
