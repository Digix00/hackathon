package config

import (
	"fmt"

	"github.com/kelseyhightower/envconfig"
)

type Config struct {
	Port        string `envconfig:"PORT" default:"8000"`
	GoEnv       string `envconfig:"GO_ENV" default:"development"`
	DatabaseURL string `envconfig:"DATABASE_URL" required:"true"`

	FirebaseProjectID        string `envconfig:"FIREBASE_PROJECT_ID" required:"true"`
	FirebaseAuthEmulatorHost string `envconfig:"FIREBASE_AUTH_EMULATOR_HOST"`

	AppDeepLinkScheme string `envconfig:"APP_DEEP_LINK_SCHEME" default:"digix"`
	MusicStateSecret  string `envconfig:"MUSIC_STATE_SECRET" required:"true"`

	// MusicTokenEncryptionKey はOAuthアクセストークン/リフレッシュトークンのAES-256-GCM暗号化鍵。
	// 64文字の16進数文字列（32バイト）を指定する。未設定の場合はサーバーが起動しない。
	MusicTokenEncryptionKey string `envconfig:"MUSIC_TOKEN_ENCRYPTION_KEY" required:"true"`

	SpotifyClientID     string `envconfig:"SPOTIFY_CLIENT_ID"`
	SpotifyClientSecret string `envconfig:"SPOTIFY_CLIENT_SECRET"`
	SpotifyRedirectURL  string `envconfig:"SPOTIFY_REDIRECT_URL" default:"http://localhost:8000/api/v1/music-connections/spotify/callback"`
	SpotifyAuthorizeURL string `envconfig:"SPOTIFY_AUTHORIZE_URL" default:"https://accounts.spotify.com/authorize"`
	SpotifyTokenURL     string `envconfig:"SPOTIFY_TOKEN_URL" default:"https://accounts.spotify.com/api/token"`
	SpotifyAPIBaseURL   string `envconfig:"SPOTIFY_API_BASE_URL" default:"https://api.spotify.com/v1"`

	AppleMusicClientID     string `envconfig:"APPLE_MUSIC_CLIENT_ID"`
	AppleMusicClientSecret string `envconfig:"APPLE_MUSIC_CLIENT_SECRET"`
	AppleMusicRedirectURL  string `envconfig:"APPLE_MUSIC_REDIRECT_URL" default:"http://localhost:8000/api/v1/music-connections/apple_music/callback"`
	AppleMusicAuthorizeURL string `envconfig:"APPLE_MUSIC_AUTHORIZE_URL"`
	AppleMusicTokenURL     string `envconfig:"APPLE_MUSIC_TOKEN_URL"`
	AppleMusicAPIBaseURL   string `envconfig:"APPLE_MUSIC_API_BASE_URL"`
}

func Load() (*Config, error) {
	var cfg Config
	if err := envconfig.Process("", &cfg); err != nil {
		return nil, err
	}
	if len(cfg.MusicTokenEncryptionKey) != 64 {
		return nil, fmt.Errorf("MUSIC_TOKEN_ENCRYPTION_KEY は64文字の16進数文字列(32バイト)である必要があります")
	}
	return &cfg, nil
}
