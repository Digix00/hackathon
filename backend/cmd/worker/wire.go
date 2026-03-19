package main

import (
	"gorm.io/gorm"

	"hackathon/internal/infra/rdb"
	"hackathon/internal/usecase"
)

func buildDependencies(db *gorm.DB) usecase.WorkerUsecase {
	bleTokenRepo := rdb.NewBleTokenRepository(db)
	return usecase.NewWorkerUsecase(bleTokenRepo)
}
