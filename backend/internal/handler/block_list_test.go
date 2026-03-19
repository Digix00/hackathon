package handler

import (
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"testing"

	"github.com/google/uuid"

	"hackathon/internal/infra/rdb/model"
)

func TestListBlocks_Empty(t *testing.T) {
	db := newTestDB(t)
	_ = seedTestUser(t, db, "firebase-uid-listblocks-empty")
	e := newTestServer(t, db, "firebase-uid-listblocks-empty")

	req, err := authRequest(http.MethodGet, "/api/v1/users/me/blocks", nil)
	if err != nil {
		t.Fatalf("new request: %v", err)
	}
	rec := httptest.NewRecorder()
	e.ServeHTTP(rec, req)

	if rec.Code != http.StatusOK {
		t.Fatalf("expected 200, got %d: %s", rec.Code, rec.Body.String())
	}

	var body map[string]any
	if err := json.Unmarshal(rec.Body.Bytes(), &body); err != nil {
		t.Fatalf("unmarshal response: %v", err)
	}
	blocks := body["blocks"].([]any)
	if len(blocks) != 0 {
		t.Fatalf("expected empty blocks, got %d", len(blocks))
	}
	pagination := body["pagination"].(map[string]any)
	if pagination["has_more"].(bool) != false {
		t.Fatal("expected has_more false")
	}
	if pagination["next_cursor"] != nil {
		t.Fatalf("expected next_cursor nil, got %v", pagination["next_cursor"])
	}
}

func TestListBlocks_ReturnsOwnBlocks(t *testing.T) {
	db := newTestDB(t)
	blocker := seedTestUser(t, db, "firebase-uid-listblocks-blocker")
	target1 := seedTestUser(t, db, "firebase-uid-listblocks-target1")
	target2 := seedTestUser(t, db, "firebase-uid-listblocks-target2")

	block1 := model.Block{
		ID:            uuid.NewString(),
		BlockerUserID: blocker.ID,
		BlockedUserID: target1.ID,
	}
	block2 := model.Block{
		ID:            uuid.NewString(),
		BlockerUserID: blocker.ID,
		BlockedUserID: target2.ID,
	}
	if err := db.Create(&block1).Error; err != nil {
		t.Fatalf("create block1: %v", err)
	}
	if err := db.Create(&block2).Error; err != nil {
		t.Fatalf("create block2: %v", err)
	}

	e := newTestServer(t, db, "firebase-uid-listblocks-blocker")

	req, err := authRequest(http.MethodGet, "/api/v1/users/me/blocks", nil)
	if err != nil {
		t.Fatalf("new request: %v", err)
	}
	rec := httptest.NewRecorder()
	e.ServeHTTP(rec, req)

	if rec.Code != http.StatusOK {
		t.Fatalf("expected 200, got %d: %s", rec.Code, rec.Body.String())
	}

	var body map[string]any
	if err := json.Unmarshal(rec.Body.Bytes(), &body); err != nil {
		t.Fatalf("unmarshal response: %v", err)
	}
	blocks := body["blocks"].([]any)
	if len(blocks) != 2 {
		t.Fatalf("expected 2 blocks, got %d", len(blocks))
	}
	for _, b := range blocks {
		block := b.(map[string]any)
		if block["id"] == nil || block["id"].(string) == "" {
			t.Fatal("expected non-empty id")
		}
		if block["blocked_user_id"] == nil || block["blocked_user_id"].(string) == "" {
			t.Fatal("expected non-empty blocked_user_id")
		}
		if block["created_at"] == nil || block["created_at"].(string) == "" {
			t.Fatal("expected non-empty created_at")
		}
	}
	pagination := body["pagination"].(map[string]any)
	if pagination["has_more"].(bool) != false {
		t.Fatal("expected has_more false")
	}
}

func TestListBlocks_PaginationCursor(t *testing.T) {
	db := newTestDB(t)
	blocker := seedTestUser(t, db, "firebase-uid-listblocks-cursor")

	for i := range 3 {
		target := seedTestUser(t, db, "firebase-uid-listblocks-cur-target-"+string(rune('a'+i)))
		block := model.Block{
			ID:            uuid.NewString(),
			BlockerUserID: blocker.ID,
			BlockedUserID: target.ID,
		}
		if err := db.Create(&block).Error; err != nil {
			t.Fatalf("create block: %v", err)
		}
	}

	e := newTestServer(t, db, "firebase-uid-listblocks-cursor")

	// First page: limit=2
	req, err := authRequest(http.MethodGet, "/api/v1/users/me/blocks?limit=2", nil)
	if err != nil {
		t.Fatalf("new request: %v", err)
	}
	rec := httptest.NewRecorder()
	e.ServeHTTP(rec, req)

	if rec.Code != http.StatusOK {
		t.Fatalf("expected 200, got %d: %s", rec.Code, rec.Body.String())
	}

	var firstBody map[string]any
	if err := json.Unmarshal(rec.Body.Bytes(), &firstBody); err != nil {
		t.Fatalf("unmarshal first response: %v", err)
	}
	firstBlocks := firstBody["blocks"].([]any)
	if len(firstBlocks) != 2 {
		t.Fatalf("expected 2 blocks, got %d", len(firstBlocks))
	}
	firstPagination := firstBody["pagination"].(map[string]any)
	if firstPagination["has_more"].(bool) != true {
		t.Fatal("expected has_more true")
	}
	nextCursor := firstPagination["next_cursor"].(string)
	if nextCursor == "" {
		t.Fatal("expected non-empty next_cursor")
	}

	// Second page
	req2, err := authRequest(http.MethodGet, "/api/v1/users/me/blocks?limit=2&cursor="+nextCursor, nil)
	if err != nil {
		t.Fatalf("new request: %v", err)
	}
	rec2 := httptest.NewRecorder()
	e.ServeHTTP(rec2, req2)

	if rec2.Code != http.StatusOK {
		t.Fatalf("expected 200, got %d: %s", rec2.Code, rec2.Body.String())
	}

	var secondBody map[string]any
	if err := json.Unmarshal(rec2.Body.Bytes(), &secondBody); err != nil {
		t.Fatalf("unmarshal second response: %v", err)
	}
	secondBlocks := secondBody["blocks"].([]any)
	if len(secondBlocks) != 1 {
		t.Fatalf("expected 1 block on second page, got %d", len(secondBlocks))
	}
	secondPagination := secondBody["pagination"].(map[string]any)
	if secondPagination["has_more"].(bool) != false {
		t.Fatal("expected has_more false on second page")
	}
	if secondPagination["next_cursor"] != nil {
		t.Fatalf("expected next_cursor nil on second page, got %v", secondPagination["next_cursor"])
	}
}

func TestListBlocks_InvalidLimitReturns400(t *testing.T) {
	db := newTestDB(t)
	_ = seedTestUser(t, db, "firebase-uid-listblocks-badlimit")
	e := newTestServer(t, db, "firebase-uid-listblocks-badlimit")

	req, err := authRequest(http.MethodGet, "/api/v1/users/me/blocks?limit=abc", nil)
	if err != nil {
		t.Fatalf("new request: %v", err)
	}
	rec := httptest.NewRecorder()
	e.ServeHTTP(rec, req)

	if rec.Code != http.StatusBadRequest {
		t.Fatalf("expected 400, got %d: %s", rec.Code, rec.Body.String())
	}
}
