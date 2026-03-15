package config

import "github.com/kelseyhightower/envconfig"

type Config struct {
	Port        string `envconfig:"PORT" default:"8000"`
	GoEnv       string `envconfig:"GO_ENV" default:"development"`
	DatabaseURL string `envconfig:"DATABASE_URL" required:"true"`

	FirebaseProjectID        string `envconfig:"FIREBASE_PROJECT_ID" required:"true"`
	FirebaseAuthEmulatorHost string `envconfig:"FIREBASE_AUTH_EMULATOR_HOST"`
}

func Load() (*Config, error) {
	var cfg Config
	if err := envconfig.Process("", &cfg); err != nil {
		return nil, err
	}
	return &cfg, nil
}
