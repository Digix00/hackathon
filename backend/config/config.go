package config

import "github.com/kelseyhightower/envconfig"

type Config struct {
	Port        string `envconfig:"PORT" default:"8000"`
	GoEnv       string `envconfig:"GO_ENV" default:"development"`
	DatabaseURL string `envconfig:"DATABASE_URL" required:"true"`

	// #3 MUST: Firebase は Phase 1 で実装するため required を外す。実装時に required:"true" に戻すこと。
	FirebaseProjectID        string `envconfig:"FIREBASE_PROJECT_ID"`
	FirebaseAuthEmulatorHost string `envconfig:"FIREBASE_AUTH_EMULATOR_HOST"`
}

func Load() (*Config, error) {
	var cfg Config
	if err := envconfig.Process("", &cfg); err != nil {
		return nil, err
	}
	return &cfg, nil
}
