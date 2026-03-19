package main

import (
	"context"
	"time"

	"go.uber.org/zap"

	"hackathon/config"
	"hackathon/internal/infra/rdb"
	applogger "hackathon/logger"
)

func main() {
	loc, err := time.LoadLocation("Asia/Tokyo")
	if err != nil {
		panic("time location load failed: " + err.Error())
	}
	time.Local = loc

	cfg, err := config.LoadWorker()
	if err != nil {
		panic("config load failed: " + err.Error())
	}

	log, err := applogger.New(cfg.GoEnv)
	if err != nil {
		panic("logger init failed: " + err.Error())
	}
	defer log.Sync() //nolint:errcheck

	db, err := rdb.Open(cfg.DatabaseURL, cfg.GoEnv)
	if err != nil {
		log.Fatal("db open failed", zap.Error(err))
	}

	sqlDB, err := db.DB()
	if err != nil {
		log.Fatal("db get sql.DB failed", zap.Error(err))
	}
	defer sqlDB.Close()

	workerUsecase := buildDependencies(db)

	deleted, err := workerUsecase.DeleteExpiredBleTokens(context.Background())
	if err != nil {
		log.Fatal("delete expired ble tokens failed", zap.Error(err))
	}
	log.Info("deleted expired ble tokens", zap.Int64("count", deleted))
}
