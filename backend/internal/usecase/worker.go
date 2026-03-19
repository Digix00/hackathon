package usecase

import (
	"context"

	"hackathon/internal/domain/repository"
)

type WorkerUsecase interface {
	// DeleteExpiredBleTokens physically deletes all BLE tokens that have passed their valid_to time.
	// Returns the number of rows deleted.
	DeleteExpiredBleTokens(ctx context.Context) (int64, error)
}

type workerUsecase struct {
	bleTokenRepo repository.BleTokenRepository
}

func NewWorkerUsecase(bleTokenRepo repository.BleTokenRepository) WorkerUsecase {
	return &workerUsecase{bleTokenRepo: bleTokenRepo}
}

func (u *workerUsecase) DeleteExpiredBleTokens(ctx context.Context) (int64, error) {
	return u.bleTokenRepo.DeleteExpired(ctx)
}
