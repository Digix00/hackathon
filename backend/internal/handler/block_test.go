package handler

import (
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"testing"

	"github.com/google/uuid"

	"hackathon/internal/infra/rdb/model"
)

func TestCreateBlock_Success(t *testing.T) {
	db := newTestDB(t)
	_ = seedTestUser(t, db, "firebase-uid-block-creator-1")
	target := seedTestUser(t, db, "firebase-uid-block-target-1")
	e := newTestServer(t, db, "firebase-uid-block-creator-1")

	req, err := authRequest(http.MethodPost, "/api/v1/users/me/blocks", map[string]any{
		"blocked_user_id": target.ID,
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
	block := body["block"].(map[string]any)
	if block["blocked_user_id"].(string) != target.ID {
		t.Fatalf("expected blocked_user_id %s, got %v", target.ID, block["blocked_user_id"])
	}
	if block["id"] == nil || block["id"].(string) == "" {
		t.Fatal("expected non-empty id")
	}
	if block["created_at"] == nil || block["created_at"].(string) == "" {
		t.Fatal("expected non-empty created_at")
	}
}

func TestCreateBlock_DuplicateReturns409(t *testing.T) {
	db := newTestDB(t)
	_ = seedTestUser(t, db, "firebase-uid-block-dup-creator")
	target := seedTestUser(t, db, "firebase-uid-block-dup-target")
	e := newTestServer(t, db, "firebase-uid-block-dup-creator")

	reqBody := map[string]any{
		"blocked_user_id": target.ID,
	}

	req1, _ := authRequest(http.MethodPost, "/api/v1/users/me/blocks", reqBody)
	rec1 := httptest.NewRecorder()
	e.ServeHTTP(rec1, req1)
	if rec1.Code != http.StatusCreated {
		t.Fatalf("expected 201 on first block, got %d: %s", rec1.Code, rec1.Body.String())
	}

	req2, _ := authRequest(http.MethodPost, "/api/v1/users/me/blocks", reqBody)
	rec2 := httptest.NewRecorder()
	e.ServeHTTP(rec2, req2)
	if rec2.Code != http.StatusConflict {
		t.Fatalf("expected 409 on duplicate block, got %d: %s", rec2.Code, rec2.Body.String())
	}
}

func TestCreateBlock_SelfBlockReturns400(t *testing.T) {
	db := newTestDB(t)
	user := seedTestUser(t, db, "firebase-uid-block-self")
	e := newTestServer(t, db, "firebase-uid-block-self")

	req, err := authRequest(http.MethodPost, "/api/v1/users/me/blocks", map[string]any{
		"blocked_user_id": user.ID,
	})
	if err != nil {
		t.Fatalf("new request: %v", err)
	}
	rec := httptest.NewRecorder()
	e.ServeHTTP(rec, req)

	if rec.Code != http.StatusBadRequest {
		t.Fatalf("expected 400 for self-block, got %d: %s", rec.Code, rec.Body.String())
	}
}

func TestCreateBlock_MissingBlockedUserIDReturns400(t *testing.T) {
	db := newTestDB(t)
	seedTestUser(t, db, "firebase-uid-block-missing-field")
	e := newTestServer(t, db, "firebase-uid-block-missing-field")

	req, err := authRequest(http.MethodPost, "/api/v1/users/me/blocks", map[string]any{})
	if err != nil {
		t.Fatalf("new request: %v", err)
	}
	rec := httptest.NewRecorder()
	e.ServeHTTP(rec, req)

	if rec.Code != http.StatusBadRequest {
		t.Fatalf("expected 400, got %d: %s", rec.Code, rec.Body.String())
	}
}

func TestCreateBlock_NonExistentUserReturns404(t *testing.T) {
	db := newTestDB(t)
	seedTestUser(t, db, "firebase-uid-block-notfound")
	e := newTestServer(t, db, "firebase-uid-block-notfound")

	req, err := authRequest(http.MethodPost, "/api/v1/users/me/blocks", map[string]any{
		"blocked_user_id": uuid.NewString(),
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

func TestDeleteBlock_Success(t *testing.T) {
	db := newTestDB(t)
	blocker := seedTestUser(t, db, "firebase-uid-block-delete-creator")
	target := seedTestUser(t, db, "firebase-uid-block-delete-target")

	block := model.Block{
		ID:            uuid.NewString(),
		BlockerUserID: blocker.ID,
		BlockedUserID: target.ID,
	}
	if err := db.Create(&block).Error; err != nil {
		t.Fatalf("create block: %v", err)
	}

	e := newTestServer(t, db, "firebase-uid-block-delete-creator")

	req, err := authRequest(http.MethodDelete, "/api/v1/users/me/blocks/"+target.ID, nil)
	if err != nil {
		t.Fatalf("new request: %v", err)
	}
	rec := httptest.NewRecorder()
	e.ServeHTTP(rec, req)

	if rec.Code != http.StatusNoContent {
		t.Fatalf("expected 204, got %d: %s", rec.Code, rec.Body.String())
	}

	var count int64
	if err := db.Unscoped().Model(&model.Block{}).Where("id = ? AND deleted_at IS NOT NULL", block.ID).Count(&count).Error; err != nil {
		t.Fatalf("count block: %v", err)
	}
	if count != 1 {
		t.Fatalf("expected block to be soft-deleted, count=%d", count)
	}
}

func TestDeleteBlock_NotFoundReturns404(t *testing.T) {
	db := newTestDB(t)
	seedTestUser(t, db, "firebase-uid-block-delete-notfound")
	e := newTestServer(t, db, "firebase-uid-block-delete-notfound")

	req, err := authRequest(http.MethodDelete, "/api/v1/users/me/blocks/"+uuid.NewString(), nil)
	if err != nil {
		t.Fatalf("new request: %v", err)
	}
	rec := httptest.NewRecorder()
	e.ServeHTTP(rec, req)

	if rec.Code != http.StatusNotFound {
		t.Fatalf("expected 404, got %d: %s", rec.Code, rec.Body.String())
	}
}
