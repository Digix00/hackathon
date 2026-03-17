package entity

import (
	"time"

	"hackathon/internal/domain/vo"
)

// MusicConnection は Spotify / Apple Music の OAuth 連携情報。
type MusicConnection struct {
	ID               string
	UserID           string
	Provider         vo.MusicProvider
	ProviderUserID   string
	ProviderUsername *string
	AccessToken      string
	RefreshToken     *string
	ExpiresAt        *time.Time
	UpdatedAt        time.Time
}

// NewMusicConnection は新規 MusicConnection を生成する。
func NewMusicConnection(userID string, provider vo.MusicProvider, providerUserID string, accessToken string) MusicConnection {
	return MusicConnection{
		UserID:         userID,
		Provider:       provider,
		ProviderUserID: providerUserID,
		AccessToken:    accessToken,
	}
}
