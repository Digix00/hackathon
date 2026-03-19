package handler

import (
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"testing"

	"github.com/google/uuid"

	"hackathon/internal/infra/rdb/model"
)

func TestListMutes_Empty(t *testing.T) {
	db := newTestDB(t)
	_ = seedTestUser(t, db, "firebase-uid-listmutes-empty")
	e := newTestServer(t, db, "firebase-uid-listmutes-empty")

	req, err := authRequest(http.MethodGet, "/api/v1/users/me/mutes", nil)
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
	mutes := body["mutes"].([]any)
	if len(mutes) != 0 {
		t.Fatalf("expected empty mutes, got %d", len(mutes))
	}
	pagination := body["pagination"].(map[string]any)
	if pagination["has_more"].(bool) != false {
		t.Fatal("expected has_more false")
	}
	if pagination["next_cursor"] != nil {
		t.Fatalf("expected next_cursor nil, got %v", pagination["next_cursor"])
	}
}

func TestListMutes_ReturnsOwnMutes(t *testing.T) {
	db := newTestDB(t)
	muter := seedTestUser(t, db, "firebase-uid-listmutes-muter")
	target1 := seedTestUser(t, db, "firebase-uid-listmutes-target1")
	target2 := seedTestUser(t, db, "firebase-uid-listmutes-target2")

	mute1 := model.Mute{
		ID:           uuid.NewString(),
		UserID:       muter.ID,
		TargetUserID: target1.ID,
	}
	mute2 := model.Mute{
		ID:           uuid.NewString(),
		UserID:       muter.ID,
		TargetUserID: target2.ID,
	}
	if err := db.Create(&mute1).Error; err != nil {
		t.Fatalf("create mute1: %v", err)
	}
	if err := db.Create(&mute2).Error; err != nil {
		t.Fatalf("create mute2: %v", err)
	}

	e := newTestServer(t, db, "firebase-uid-listmutes-muter")

	req, err := authRequest(http.MethodGet, "/api/v1/users/me/mutes", nil)
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
	mutes := body["mutes"].([]any)
	if len(mutes) != 2 {
		t.Fatalf("expected 2 mutes, got %d", len(mutes))
	}
	for _, m := range mutes {
		mute := m.(map[string]any)
		if mute["id"] == nil || mute["id"].(string) == "" {
			t.Fatal("expected non-empty id")
		}
		if mute["target_user_id"] == nil || mute["target_user_id"].(string) == "" {
			t.Fatal("expected non-empty target_user_id")
		}
		if mute["created_at"] == nil || mute["created_at"].(string) == "" {
			t.Fatal("expected non-empty created_at")
		}
	}
	pagination := body["pagination"].(map[string]any)
	if pagination["has_more"].(bool) != false {
		t.Fatal("expected has_more false")
	}
}

func TestListMutes_PaginationCursor(t *testing.T) {
	db := newTestDB(t)
	muter := seedTestUser(t, db, "firebase-uid-listmutes-cursor")

	for i := range 3 {
		target := seedTestUser(t, db, "firebase-uid-listmutes-cur-target-"+string(rune('a'+i)))
		mute := model.Mute{
			ID:           uuid.NewString(),
			UserID:       muter.ID,
			TargetUserID: target.ID,
		}
		if err := db.Create(&mute).Error; err != nil {
			t.Fatalf("create mute: %v", err)
		}
	}

	e := newTestServer(t, db, "firebase-uid-listmutes-cursor")

	// First page: limit=2
	req, err := authRequest(http.MethodGet, "/api/v1/users/me/mutes?limit=2", nil)
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
	firstMutes := firstBody["mutes"].([]any)
	if len(firstMutes) != 2 {
		t.Fatalf("expected 2 mutes, got %d", len(firstMutes))
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
	req2, err := authRequest(http.MethodGet, "/api/v1/users/me/mutes?limit=2&cursor="+nextCursor, nil)
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
	secondMutes := secondBody["mutes"].([]any)
	if len(secondMutes) != 1 {
		t.Fatalf("expected 1 mute on second page, got %d", len(secondMutes))
	}
	secondPagination := secondBody["pagination"].(map[string]any)
	if secondPagination["has_more"].(bool) != false {
		t.Fatal("expected has_more false on second page")
	}
	if secondPagination["next_cursor"] != nil {
		t.Fatalf("expected next_cursor nil on second page, got %v", secondPagination["next_cursor"])
	}
}

func TestListMutes_InvalidLimitReturns400(t *testing.T) {
	db := newTestDB(t)
	_ = seedTestUser(t, db, "firebase-uid-listmutes-badlimit")
	e := newTestServer(t, db, "firebase-uid-listmutes-badlimit")

	req, err := authRequest(http.MethodGet, "/api/v1/users/me/mutes?limit=abc", nil)
	if err != nil {
		t.Fatalf("new request: %v", err)
	}
	rec := httptest.NewRecorder()
	e.ServeHTTP(rec, req)

	if rec.Code != http.StatusBadRequest {
		t.Fatalf("expected 400, got %d: %s", rec.Code, rec.Body.String())
	}
}
