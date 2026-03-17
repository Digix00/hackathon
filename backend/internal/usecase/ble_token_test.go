package usecase

import (
	"context"
	"testing"
	"time"

	"hackathon/internal/domain/entity"
	domainerrs "hackathon/internal/domain/errs"
)

type stubBleTokenRepo struct {
	byUserID  map[string]entity.BleToken
	byToken   map[string]entity.BleToken
	createErr error
}

func (r *stubBleTokenRepo) Create(_ context.Context, token entity.BleToken) error {
	if r.createErr != nil {
		return r.createErr
	}
	r.byUserID[token.UserID] = token
	r.byToken[token.Token] = token
	return nil
}

func (r *stubBleTokenRepo) RotateToken(_ context.Context, newToken entity.BleToken) error {
	if r.createErr != nil {
		return r.createErr
	}
	// Expire existing token for the user
	if old, ok := r.byUserID[newToken.UserID]; ok {
		old.ValidTo = old.ValidFrom
		r.byUserID[newToken.UserID] = old
	}
	r.byUserID[newToken.UserID] = newToken
	r.byToken[newToken.Token] = newToken
	return nil
}

func (r *stubBleTokenRepo) FindLatestByUserID(_ context.Context, userID string) (entity.BleToken, error) {
	token, ok := r.byUserID[userID]
	if !ok {
		return entity.BleToken{}, domainerrs.NotFound("not found")
	}
	return token, nil
}

func (r *stubBleTokenRepo) FindByToken(_ context.Context, tokenStr string) (entity.BleToken, error) {
	token, ok := r.byToken[tokenStr]
	if !ok {
		return entity.BleToken{}, domainerrs.NotFound("not found")
	}
	return token, nil
}

func TestCreateBleToken(t *testing.T) {
	authUID := "test-auth-uid"
	userID := "test-user-id"

	userRepo := &stubUserRepo{
		byAuthUID: map[string]entity.User{
			authUID: {ID: userID},
		},
	}
	bleRepo := &stubBleTokenRepo{
		byUserID: make(map[string]entity.BleToken),
		byToken:  make(map[string]entity.BleToken),
	}

	uc := NewBleTokenUsecase(bleRepo, userRepo, &stubBlockRepo{}, &stubUserSettingsRepo{}, &stubEncounterRepo{}, &stubTrackRepo{})

	token, err := uc.CreateBleToken(context.Background(), authUID)
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	if token.Token == "" {
		t.Errorf("expected non-empty token")
	}

	// Verify it was saved to the repo
	savedToken, err := bleRepo.FindLatestByUserID(context.Background(), userID)
	if err != nil {
		t.Fatalf("expected token to be saved: %v", err)
	}
	if savedToken.Token != token.Token {
		t.Errorf("saved token %v does not match returned token %v", savedToken.Token, token.Token)
	}
}

func TestGetCurrentBleToken(t *testing.T) {
	authUID := "test-auth-uid"
	userID := "test-user-id"
	tokenStr := "some-token-str"

	userRepo := &stubUserRepo{
		byAuthUID: map[string]entity.User{
			authUID: {ID: userID},
		},
	}
	now := time.Now().UTC()
	bleRepo := &stubBleTokenRepo{
		byUserID: map[string]entity.BleToken{
			userID: {UserID: userID, Token: tokenStr, ValidFrom: now.Add(-1 * time.Hour), ValidTo: now.Add(1 * time.Hour)},
		},
		byToken: make(map[string]entity.BleToken),
	}

	uc := NewBleTokenUsecase(bleRepo, userRepo, &stubBlockRepo{}, &stubUserSettingsRepo{}, &stubEncounterRepo{}, &stubTrackRepo{})

	token, err := uc.GetCurrentBleToken(context.Background(), authUID)
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	if token.Token != tokenStr {
		t.Errorf("expected %v, got %v", tokenStr, token.Token)
	}
}

func TestGetBleUserByToken(t *testing.T) {
	requesterAuthUID := "req-uid"
	targetUserID := "t1"
	tokenStr := "some-token"

	now := time.Now().UTC()

	bleRepo := &stubBleTokenRepo{
		byUserID: make(map[string]entity.BleToken),
		byToken: map[string]entity.BleToken{
			tokenStr: {
				UserID:    targetUserID,
				Token:     tokenStr,
				ValidFrom: now.Add(-1 * time.Hour),
				ValidTo:   now.Add(1 * time.Hour), // Valid
			},
		},
	}

	userRepo := &stubUserRepo{
		byAuthUID: map[string]entity.User{
			requesterAuthUID: {ID: "r1"},
		},
		byID: map[string]entity.User{
			targetUserID: {ID: targetUserID},
		},
	}

	uc := NewBleTokenUsecase(bleRepo, userRepo, &stubBlockRepo{}, &stubUserSettingsRepo{data: make(map[string]entity.UserSettings)}, &stubEncounterRepo{}, &stubTrackRepo{})

	pub, err := uc.GetBleUserByToken(context.Background(), requesterAuthUID, tokenStr)
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	if pub.ID != targetUserID {
		t.Errorf("expected %v, got %v", targetUserID, pub.ID)
	}
}
