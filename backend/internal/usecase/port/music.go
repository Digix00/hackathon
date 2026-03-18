package port

import (
	"context"
	"time"

	"hackathon/internal/domain/entity"
)

type OAuthAuthorizeInput struct {
	State string
}

type OAuthToken struct {
	AccessToken  string
	RefreshToken *string
	ExpiresAt    *time.Time
}

type AccountProfile struct {
	UserID   string
	Username *string
}

type SearchTracksResult struct {
	Tracks     []entity.TrackInfo
	NextCursor *string
	HasMore    bool
}

type MusicProvider interface {
	Provider() string
	BuildAuthorizeURL(input OAuthAuthorizeInput) (string, error)
	ExchangeCode(ctx context.Context, code string) (OAuthToken, error)
	GetProfile(ctx context.Context, accessToken string) (AccountProfile, error)
	SearchTracks(ctx context.Context, accessToken, query string, limit int, cursor *string) (SearchTracksResult, error)
	GetTrack(ctx context.Context, accessToken, externalID string) (entity.TrackInfo, error)
}
