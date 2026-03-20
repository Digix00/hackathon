//go:build integration

package rdb

import (
	"context"
	"testing"
	"time"

	"github.com/google/uuid"
	"gorm.io/gorm"

	"hackathon/internal/infra/rdb/model"
	"hackathon/internal/usecase"
)

func openRdbIntegrationDB(t *testing.T) *gorm.DB {
	t.Helper()
	if sharedTestDB == nil {
		t.Skip("skip integration test: postgres not available")
	}
	return sharedTestDB
}

func cleanupBleTokenTestData(t *testing.T) {
	t.Helper()
	err := sharedTestDB.Exec(`
TRUNCATE TABLE
	ble_tokens,
	users,
	user_settings
RESTART IDENTITY CASCADE;
`).Error
	if err != nil {
		t.Fatalf("cleanup ble token test data: %v", err)
	}
}

func seedUserForBleToken(t *testing.T, providerUserID string) model.User {
	t.Helper()
	user := model.User{
		ID:             uuid.NewString(),
		AuthProvider:   "firebase",
		ProviderUserID: providerUserID,
		Sex:            "no-answer",
		AgeVisibility:  "hidden",
	}
	if err := sharedTestDB.Create(&user).Error; err != nil {
		t.Fatalf("seed user: %v", err)
	}
	return user
}

func seedBleTokenRecord(t *testing.T, userID string, validFrom, validTo time.Time) model.BleToken {
	t.Helper()
	m := model.BleToken{
		ID:        uuid.NewString(),
		UserID:    userID,
		Token:     uuid.NewString()[:16],
		ValidFrom: validFrom,
		ValidTo:   validTo,
	}
	if err := sharedTestDB.Create(&m).Error; err != nil {
		t.Fatalf("seed ble token: %v", err)
	}
	return m
}

// TestIntegration_BleTokenRepository_DeleteExpired_RemovesExpiredTokens は
// valid_to が過去のトークンが物理削除されることを検証する。
func TestIntegration_BleTokenRepository_DeleteExpired_RemovesExpiredTokens(t *testing.T) {
	_ = openRdbIntegrationDB(t)
	cleanupBleTokenTestData(t)
	defer cleanupBleTokenTestData(t)

	user := seedUserForBleToken(t, "uid-expired-1")

	now := time.Now().UTC()
	expired1 := seedBleTokenRecord(t, user.ID, now.Add(-48*time.Hour), now.Add(-24*time.Hour))
	expired2 := seedBleTokenRecord(t, user.ID, now.Add(-2*time.Hour), now.Add(-1*time.Hour))

	repo := NewBleTokenRepository(sharedTestDB)
	deleted, err := repo.DeleteExpired(context.Background())
	if err != nil {
		t.Fatalf("DeleteExpired: %v", err)
	}
	if deleted != 2 {
		t.Fatalf("expected 2 deleted, got %d", deleted)
	}

	// Unscoped で物理削除されていることを確認
	var count int64
	if err := sharedTestDB.Unscoped().Model(&model.BleToken{}).
		Where("id IN (?, ?)", expired1.ID, expired2.ID).
		Count(&count).Error; err != nil {
		t.Fatalf("count expired tokens: %v", err)
	}
	if count != 0 {
		t.Fatalf("expected 0 rows after physical delete, got %d", count)
	}
}

// TestIntegration_BleTokenRepository_DeleteExpired_KeepsValidTokens は
// valid_to が未来のトークンが削除されないことを検証する。
func TestIntegration_BleTokenRepository_DeleteExpired_KeepsValidTokens(t *testing.T) {
	_ = openRdbIntegrationDB(t)
	cleanupBleTokenTestData(t)
	defer cleanupBleTokenTestData(t)

	user := seedUserForBleToken(t, "uid-valid-1")

	now := time.Now().UTC()
	_ = seedBleTokenRecord(t, user.ID, now.Add(-48*time.Hour), now.Add(-24*time.Hour))    // expired
	valid := seedBleTokenRecord(t, user.ID, now.Add(-1*time.Hour), now.Add(23*time.Hour)) // valid

	repo := NewBleTokenRepository(sharedTestDB)
	deleted, err := repo.DeleteExpired(context.Background())
	if err != nil {
		t.Fatalf("DeleteExpired: %v", err)
	}
	if deleted != 1 {
		t.Fatalf("expected 1 deleted, got %d", deleted)
	}

	// 有効なトークンが残っていることを確認
	var count int64
	if err := sharedTestDB.Model(&model.BleToken{}).Where("id = ?", valid.ID).Count(&count).Error; err != nil {
		t.Fatalf("count valid token: %v", err)
	}
	if count != 1 {
		t.Fatalf("expected valid token to remain, got count=%d", count)
	}
}

// TestIntegration_BleTokenRepository_DeleteExpired_ReturnsZeroWhenNothingToDelete は
// 期限切れトークンが存在しない場合に 0 が返されることを検証する。
func TestIntegration_BleTokenRepository_DeleteExpired_ReturnsZeroWhenNothingToDelete(t *testing.T) {
	_ = openRdbIntegrationDB(t)
	cleanupBleTokenTestData(t)
	defer cleanupBleTokenTestData(t)

	user := seedUserForBleToken(t, "uid-noexpired-1")
	now := time.Now().UTC()
	_ = seedBleTokenRecord(t, user.ID, now.Add(-1*time.Hour), now.Add(23*time.Hour)) // valid only

	repo := NewBleTokenRepository(sharedTestDB)
	deleted, err := repo.DeleteExpired(context.Background())
	if err != nil {
		t.Fatalf("DeleteExpired: %v", err)
	}
	if deleted != 0 {
		t.Fatalf("expected 0 deleted, got %d", deleted)
	}
}

// TestIntegration_WorkerUsecase_DeleteExpiredBleTokens は
// WorkerUsecase 経由での削除がリポジトリと整合していることを検証する。
func TestIntegration_WorkerUsecase_DeleteExpiredBleTokens(t *testing.T) {
	_ = openRdbIntegrationDB(t)
	cleanupBleTokenTestData(t)
	defer cleanupBleTokenTestData(t)

	user := seedUserForBleToken(t, "uid-worker-1")
	now := time.Now().UTC()
	_ = seedBleTokenRecord(t, user.ID, now.Add(-24*time.Hour), now.Add(-1*time.Hour))     // expired
	_ = seedBleTokenRecord(t, user.ID, now.Add(-30*time.Minute), now.Add(30*time.Minute)) // valid

	workerUsecase := usecase.NewWorkerUsecase(NewBleTokenRepository(sharedTestDB), nil, nil, nil, nil, 45)
	deleted, err := workerUsecase.DeleteExpiredBleTokens(context.Background())
	if err != nil {
		t.Fatalf("DeleteExpiredBleTokens: %v", err)
	}
	if deleted != 1 {
		t.Fatalf("expected 1 deleted via usecase, got %d", deleted)
	}

	var remaining int64
	if err := sharedTestDB.Model(&model.BleToken{}).Where("user_id = ?", user.ID).Count(&remaining).Error; err != nil {
		t.Fatalf("count remaining: %v", err)
	}
	if remaining != 1 {
		t.Fatalf("expected 1 token to remain, got %d", remaining)
	}
}
