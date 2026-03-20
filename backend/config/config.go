package config

import (
	"fmt"
	"net/url"

	"github.com/kelseyhightower/envconfig"
)

type Config struct {
	Port        string `envconfig:"PORT" default:"8000"`
	GoEnv       string `envconfig:"GO_ENV" default:"development"`
	DatabaseURL string `envconfig:"DATABASE_URL"`

	// Cloud Run 環境では DATABASE_URL の代わりに以下の個別変数から DSN を組み立てる。
	// DB_PASSWORD は Secret Manager から注入されるため DATABASE_URL に直接埋め込めない。
	DBUser           string `envconfig:"DB_USER"`
	DBPassword       string `envconfig:"DB_PASSWORD"`
	DBName           string `envconfig:"DB_NAME"`
	DBConnectionName string `envconfig:"DB_CONNECTION_NAME"` // 例: project:region:instance

	FirebaseProjectID        string `envconfig:"FIREBASE_PROJECT_ID" required:"true"`
	FirebaseAuthEmulatorHost string `envconfig:"FIREBASE_AUTH_EMULATOR_HOST"`
	DevAuthToken             string `envconfig:"DEV_AUTH_TOKEN"`
	DevAuthUID               string `envconfig:"DEV_AUTH_UID" default:"dev-user"`

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

type WorkerConfig struct {
	GoEnv            string `envconfig:"GO_ENV" default:"production"`
	DatabaseURL      string `envconfig:"DATABASE_URL"`
	DBUser           string `envconfig:"DB_USER"`
	DBPassword       string `envconfig:"DB_PASSWORD"`
	DBName           string `envconfig:"DB_NAME"`
	DBConnectionName string `envconfig:"DB_CONNECTION_NAME"`

	// Vertex AI / Lyria / Gemini 設定
	VertexAIProjectID    string `envconfig:"VERTEX_AI_PROJECT_ID"`
	VertexAILocation     string `envconfig:"VERTEX_AI_LOCATION" default:"us-central1"`
	LyriaModelID         string `envconfig:"LYRIA_MODEL_ID" default:"lyria-002"`
	LyriaDefaultDuration int    `envconfig:"LYRIA_DEFAULT_DURATION" default:"45"`
	GeminiModelID        string `envconfig:"GEMINI_MODEL_ID" default:"gemini-1.5-flash"`

	// Lyria タイムアウト設定（秒）
	LyriaTimeoutSec int `envconfig:"LYRIA_TIMEOUT_SEC" default:"300"`

	// Cloud Storage 設定
	AudioBucketName string `envconfig:"AUDIO_BUCKET_NAME"`
}

func LoadWorker() (*WorkerConfig, error) {
	var cfg WorkerConfig
	if err := envconfig.Process("", &cfg); err != nil {
		return nil, err
	}
	if cfg.DatabaseURL == "" {
		if cfg.DBUser == "" || cfg.DBPassword == "" || cfg.DBName == "" || cfg.DBConnectionName == "" {
			return nil, fmt.Errorf("DATABASE_URL または DB_USER/DB_PASSWORD/DB_NAME/DB_CONNECTION_NAME を設定してください")
		}
		cfg.DatabaseURL = fmt.Sprintf(
			"postgres://%s@/%s?host=/cloudsql/%s",
			url.UserPassword(cfg.DBUser, cfg.DBPassword).String(),
			url.PathEscape(cfg.DBName),
			cfg.DBConnectionName,
		)
	}
	if cfg.GoEnv != "development" {
		if cfg.VertexAIProjectID == "" {
			return nil, fmt.Errorf("VERTEX_AI_PROJECT_ID は本番環境で必須です")
		}
		if cfg.AudioBucketName == "" {
			return nil, fmt.Errorf("AUDIO_BUCKET_NAME は本番環境で必須です")
		}
	}
	return &cfg, nil
}

func Load() (*Config, error) {
	var cfg Config
	if err := envconfig.Process("", &cfg); err != nil {
		return nil, err
	}
	if cfg.DatabaseURL == "" {
		if cfg.DBUser == "" || cfg.DBPassword == "" || cfg.DBName == "" || cfg.DBConnectionName == "" {
			return nil, fmt.Errorf("DATABASE_URL または DB_USER/DB_PASSWORD/DB_NAME/DB_CONNECTION_NAME を設定してください")
		}
		cfg.DatabaseURL = fmt.Sprintf(
			"postgres://%s@/%s?host=/cloudsql/%s",
			url.UserPassword(cfg.DBUser, cfg.DBPassword).String(),
			url.PathEscape(cfg.DBName),
			cfg.DBConnectionName,
		)
	}
	if len(cfg.MusicTokenEncryptionKey) != 64 {
		return nil, fmt.Errorf("MUSIC_TOKEN_ENCRYPTION_KEY は64文字の16進数文字列(32バイト)である必要があります")
	}
	return &cfg, nil
}
