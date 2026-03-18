package entity

import "time"

type MusicConnection struct {
	ID               string
	UserID           string
	Provider         string
	ProviderUserID   string
	ProviderUsername *string
	AccessToken      string
	RefreshToken     *string
	ExpiresAt        *time.Time
	CreatedAt        time.Time
	UpdatedAt        time.Time
}
