package handler

import (
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"testing"

	"github.com/google/uuid"

	"hackathon/internal/infra/rdb/model"
)

func TestCreateMute_Success(t *testing.T) {
	db := newTestDB(t)
	_ = seedTestUser(t, db, "firebase-uid-mute-creator-1")
	target := seedTestUser(t, db, "firebase-uid-mute-target-1")
	e := newTestServer(t, db, "firebase-uid-mute-creator-1")

	req, err := authRequest(http.MethodPost, "/api/v1/users/me/mutes", map[string]any{
		"target_user_id": target.ID,
	})
	if err != nil {
		t.Fatalf("new request: %v", err)
	}
	rec := httptest.NewRecorder()
	e.ServeHTTP(rec, req)

	if rec.Code != http.StatusCreated {
		t.Fatalf("expected 201, got %d: %s", rec.Code, rec.Body.String())
	}

	var body map[string]any
	if err := json.Unmarshal(rec.Body.Bytes(), &body); err != nil {
		t.Fatalf("unmarshal response: %v", err)
	}
	mute := body["mute"].(map[string]any)
	if mute["target_user_id"].(string) != target.ID {
		t.Fatalf("expected target_user_id %s, got %v", target.ID, mute["target_user_id"])
	}
	if mute["id"] == nil || mute["id"].(string) == "" {
		t.Fatal("expected non-empty id")
	}
	if mute["created_at"] == nil || mute["created_at"].(string) == "" {
		t.Fatal("expected non-empty created_at")
	}
}

func TestCreateMute_DuplicateReturns409(t *testing.T) {
	db := newTestDB(t)
	_ = seedTestUser(t, db, "firebase-uid-mute-dup-creator")
	target := seedTestUser(t, db, "firebase-uid-mute-dup-target")
	e := newTestServer(t, db, "firebase-uid-mute-dup-creator")

	reqBody := map[string]any{
		"target_user_id": target.ID,
	}

	req1, _ := authRequest(http.MethodPost, "/api/v1/users/me/mutes", reqBody)
	rec1 := httptest.NewRecorder()
	e.ServeHTTP(rec1, req1)
	if rec1.Code != http.StatusCreated {
		t.Fatalf("expected 201 on first mute, got %d: %s", rec1.Code, rec1.Body.String())
	}

	req2, _ := authRequest(http.MethodPost, "/api/v1/users/me/mutes", reqBody)
	rec2 := httptest.NewRecorder()
	e.ServeHTTP(rec2, req2)
	if rec2.Code != http.StatusConflict {
		t.Fatalf("expected 409 on duplicate mute, got %d: %s", rec2.Code, rec2.Body.String())
	}
}

func TestCreateMute_SelfMuteReturns400(t *testing.T) {
	db := newTestDB(t)
	user := seedTestUser(t, db, "firebase-uid-mute-self")
	e := newTestServer(t, db, "firebase-uid-mute-self")

	req, err := authRequest(http.MethodPost, "/api/v1/users/me/mutes", map[string]any{
		"target_user_id": user.ID,
	})
	if err != nil {
		t.Fatalf("new request: %v", err)
	}
	rec := httptest.NewRecorder()
	e.ServeHTTP(rec, req)

	if rec.Code != http.StatusBadRequest {
		t.Fatalf("expected 400 for self-mute, got %d: %s", rec.Code, rec.Body.String())
	}
}

func TestCreateMute_MissingTargetUserIDReturns400(t *testing.T) {
	db := newTestDB(t)
	seedTestUser(t, db, "firebase-uid-mute-missing-field")
	e := newTestServer(t, db, "firebase-uid-mute-missing-field")

	req, err := authRequest(http.MethodPost, "/api/v1/users/me/mutes", map[string]any{})
	if err != nil {
		t.Fatalf("new request: %v", err)
	}
	rec := httptest.NewRecorder()
	e.ServeHTTP(rec, req)

	if rec.Code != http.StatusBadRequest {
		t.Fatalf("expected 400, got %d: %s", rec.Code, rec.Body.String())
	}
}

func TestCreateMute_NonExistentUserReturns404(t *testing.T) {
	db := newTestDB(t)
	seedTestUser(t, db, "firebase-uid-mute-notfound")
	e := newTestServer(t, db, "firebase-uid-mute-notfound")

	req, err := authRequest(http.MethodPost, "/api/v1/users/me/mutes", map[string]any{
		"target_user_id": uuid.NewString(),
	})
	if err != nil {
		t.Fatalf("new request: %v", err)
	}
	rec := httptest.NewRecorder()
	e.ServeHTTP(rec, req)

	if rec.Code != http.StatusNotFound {
		t.Fatalf("expected 404, got %d: %s", rec.Code, rec.Body.String())
	}
}

func TestDeleteMute_Success(t *testing.T) {
	db := newTestDB(t)
	muter := seedTestUser(t, db, "firebase-uid-mute-delete-creator")
	target := seedTestUser(t, db, "firebase-uid-mute-delete-target")

	mute := model.Mute{
		ID:           uuid.NewString(),
		UserID:       muter.ID,
		TargetUserID: target.ID,
	}
	if err := db.Create(&mute).Error; err != nil {
		t.Fatalf("create mute: %v", err)
	}

	e := newTestServer(t, db, "firebase-uid-mute-delete-creator")

	req, err := authRequest(http.MethodDelete, "/api/v1/users/me/mutes/"+target.ID, nil)
	if err != nil {
		t.Fatalf("new request: %v", err)
	}
	rec := httptest.NewRecorder()
	e.ServeHTTP(rec, req)

	if rec.Code != http.StatusNoContent {
		t.Fatalf("expected 204, got %d: %s", rec.Code, rec.Body.String())
	}

	var count int64
	if err := db.Unscoped().Model(&model.Mute{}).Where("id = ? AND deleted_at IS NOT NULL", mute.ID).Count(&count).Error; err != nil {
		t.Fatalf("count mute: %v", err)
	}
	if count != 1 {
		t.Fatalf("expected mute to be soft-deleted, count=%d", count)
	}
}

func TestDeleteMute_NotFoundReturns404(t *testing.T) {
	db := newTestDB(t)
	seedTestUser(t, db, "firebase-uid-mute-delete-notfound")
	e := newTestServer(t, db, "firebase-uid-mute-delete-notfound")

	req, err := authRequest(http.MethodDelete, "/api/v1/users/me/mutes/"+uuid.NewString(), nil)
	if err != nil {
		t.Fatalf("new request: %v", err)
	}
	rec := httptest.NewRecorder()
	e.ServeHTTP(rec, req)

	if rec.Code != http.StatusNotFound {
		t.Fatalf("expected 404, got %d: %s", rec.Code, rec.Body.String())
	}
}
