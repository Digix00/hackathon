package rdb

import (
	"fmt"

	"gorm.io/driver/postgres"
	"gorm.io/gorm"
	"gorm.io/gorm/logger"
)

func Open(dsn string, env string) (*gorm.DB, error) {
	logLevel := logger.Warn
	if env == "development" {
		logLevel = logger.Info
	}

	db, err := gorm.Open(postgres.Open(dsn), &gorm.Config{
		Logger: logger.Default.LogMode(logLevel),
		// AutoMigrate 時に FK 制約を自動生成しない。
		// users ↔ files の循環依存を避けるため、FK は Migrate() 内で手動追加する。
		DisableForeignKeyConstraintWhenMigrating: true,
	})
	if err != nil {
		return nil, fmt.Errorf("rdb.Open: %w", err)
	}
	return db, nil
}
