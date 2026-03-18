package main

import (
	"context"
	"database/sql"
	"errors"
	"time"

	"go.uber.org/zap"
	"gorm.io/gorm"

	"hackathon/config"
	"hackathon/internal/infra/rdb"
	applogger "hackathon/logger"
)

const (
	connectTimeout = 5 * time.Second
	maxWait        = 30 * time.Second
	retryInterval  = 2 * time.Second
)

func main() {
	cfg, err := config.Load()
	if err != nil {
		panic("config load failed: " + err.Error())
	}

	log, err := applogger.New(cfg.GoEnv)
	if err != nil {
		panic("logger init failed: " + err.Error())
	}
	defer log.Sync() //nolint:errcheck

	if cfg.GoEnv != "development" && cfg.GoEnv != "test" {
		log.Fatal("init-db is only allowed in development/test", zap.String("go_env", cfg.GoEnv))
	}

	db, sqlDB := connectWithRetry(log, cfg.DatabaseURL, cfg.GoEnv)
	defer sqlDB.Close() //nolint:errcheck
	if err := rdb.Migrate(db); err != nil {
		log.Fatal("db migrate failed", zap.Error(err))
	}
	log.Info("db migration completed")

	if err := rdb.Seed(db); err != nil {
		log.Fatal("db seed failed", zap.Error(err))
	}
	log.Info("db seed completed")
}

func connectWithRetry(log *zap.Logger, dsn string, env string) (*gorm.DB, *sql.DB) {
	deadline := time.Now().Add(maxWait)
	var lastErr error

	for attempt := 1; time.Now().Before(deadline); attempt++ {
		db, err := rdb.Open(dsn, env)
		if err != nil {
			lastErr = err
			log.Info("db open failed, retrying", zap.Int("attempt", attempt), zap.Error(err))
			time.Sleep(retryInterval)
			continue
		}

		sqlDB, err := db.DB()
		if err != nil {
			lastErr = err
			log.Info("db open failed, retrying", zap.Int("attempt", attempt), zap.Error(err))
			time.Sleep(retryInterval)
			continue
		}

		ctx, cancel := context.WithTimeout(context.Background(), connectTimeout)
		err = sqlDB.PingContext(ctx)
		cancel()
		if err != nil {
			lastErr = err
			log.Info("db ping failed, retrying", zap.Int("attempt", attempt), zap.Error(err))
			sqlDB.Close() //nolint:errcheck
			time.Sleep(retryInterval)
			continue
		}

		return db, sqlDB
	}

	if lastErr == nil {
		lastErr = errors.New("db connection timed out")
	}
	log.Fatal("db connection failed", zap.Error(lastErr))
	return nil, nil
}
