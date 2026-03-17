package config

import "github.com/kelseyhightower/envconfig"

type Config struct {
	Port        string `envconfig:"PORT" default:"8000"`
	GoEnv       string `envconfig:"GO_ENV" default:"development"`
	DatabaseURL string `envconfig:"DATABASE_URL" required:"true"`

	FirebaseProjectID        string `envconfig:"FIREBASE_PROJECT_ID" required:"true"`
	FirebaseAuthEmulatorHost string `envconfig:"FIREBASE_AUTH_EMULATOR_HOST"`

	// Spotify OAuth
	SpotifyClientID     string `envconfig:"SPOTIFY_CLIENT_ID"`
	SpotifyClientSecret string `envconfig:"SPOTIFY_CLIENT_SECRET"`
	SpotifyRedirectURI  string `envconfig:"SPOTIFY_REDIRECT_URI" default:"digix://music-connections/spotify/callback"`

	// OAuth state 署名シークレット（HMAC-SHA256 用）
	OAuthStateSecret string `envconfig:"OAUTH_STATE_SECRET" default:"dev-secret-change-in-production"`

	// Vertex AI / Gemini
	VertexAIProjectID string `envconfig:"VERTEX_AI_PROJECT_ID"`
	VertexAILocation  string `envconfig:"VERTEX_AI_LOCATION" default:"us-central1"`
	GeminiModelID     string `envconfig:"GEMINI_MODEL_ID" default:"gemini-1.5-flash"`

	// Lyria
	LyriaModelID          string `envconfig:"LYRIA_MODEL_ID" default:"lyria-002"`
	LyriaDefaultDurationS int    `envconfig:"LYRIA_DEFAULT_DURATION" default:"45"`
	LyriaTimeoutSec       int    `envconfig:"LYRIA_TIMEOUT_SEC" default:"300"`

	// Cloud Storage
	GCSBucketName string `envconfig:"GCS_BUCKET_NAME" default:"ana-prod-generated-songs"`
}

func Load() (*Config, error) {
	var cfg Config
	if err := envconfig.Process("", &cfg); err != nil {
		return nil, err
	}
	return &cfg, nil
}
