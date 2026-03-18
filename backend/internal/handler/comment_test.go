package handler

import (
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"testing"

	"github.com/google/uuid"

	"hackathon/internal/infra/rdb/model"
)

func TestCreateComment_Success(t *testing.T) {
	db := newTestDB(t)
	user := seedTestUser(t, db, "firebase-uid-comment-creator-1")
	other := seedTestUser(t, db, "firebase-uid-comment-other-1")
	encounter := orderedEncounter(user.ID, other.ID, jsonDate(t, "2026-03-01"))
	if err := db.Create(&encounter).Error; err != nil {
		t.Fatalf("create encounter: %v", err)
	}

	e := newTestServer(t, db, "firebase-uid-comment-creator-1")

	req, err := authRequest(http.MethodPost, "/api/v1/encounters/"+encounter.ID+"/comments", map[string]any{
		"content": "この曲好きです！",
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
	comment := body["comment"].(map[string]any)
	if comment["id"] == nil || comment["id"].(string) == "" {
		t.Fatal("expected non-empty id")
	}
	if comment["encounter_id"].(string) != encounter.ID {
		t.Fatalf("expected encounter_id %s, got %v", encounter.ID, comment["encounter_id"])
	}
	if comment["content"].(string) != "この曲好きです！" {
		t.Fatalf("expected content, got %v", comment["content"])
	}
	commentUser := comment["user"].(map[string]any)
	if commentUser["id"].(string) != user.ID {
		t.Fatalf("expected user id %s, got %v", user.ID, commentUser["id"])
	}
	if comment["created_at"] == nil || comment["created_at"].(string) == "" {
		t.Fatal("expected non-empty created_at")
	}
}

func TestCreateComment_NonParticipantReturns404(t *testing.T) {
	db := newTestDB(t)
	user1 := seedTestUser(t, db, "firebase-uid-comment-nonpart-1")
	user2 := seedTestUser(t, db, "firebase-uid-comment-nonpart-2")
	_ = seedTestUser(t, db, "firebase-uid-comment-nonpart-3")
	encounter := orderedEncounter(user1.ID, user2.ID, jsonDate(t, "2026-03-01"))
	if err := db.Create(&encounter).Error; err != nil {
		t.Fatalf("create encounter: %v", err)
	}

	// third user tries to comment on encounter they're not part of
	e := newTestServer(t, db, "firebase-uid-comment-nonpart-3")

	req, err := authRequest(http.MethodPost, "/api/v1/encounters/"+encounter.ID+"/comments", map[string]any{
		"content": "uninvited comment",
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

func TestCreateComment_NonExistentEncounterReturns404(t *testing.T) {
	db := newTestDB(t)
	seedTestUser(t, db, "firebase-uid-comment-noenc")
	e := newTestServer(t, db, "firebase-uid-comment-noenc")

	req, err := authRequest(http.MethodPost, "/api/v1/encounters/"+uuid.NewString()+"/comments", map[string]any{
		"content": "hello",
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

func TestCreateComment_MissingContentReturns400(t *testing.T) {
	db := newTestDB(t)
	user := seedTestUser(t, db, "firebase-uid-comment-nocontent-1")
	other := seedTestUser(t, db, "firebase-uid-comment-nocontent-2")
	encounter := orderedEncounter(user.ID, other.ID, jsonDate(t, "2026-03-01"))
	if err := db.Create(&encounter).Error; err != nil {
		t.Fatalf("create encounter: %v", err)
	}

	e := newTestServer(t, db, "firebase-uid-comment-nocontent-1")

	req, err := authRequest(http.MethodPost, "/api/v1/encounters/"+encounter.ID+"/comments", map[string]any{})
	if err != nil {
		t.Fatalf("new request: %v", err)
	}
	rec := httptest.NewRecorder()
	e.ServeHTTP(rec, req)

	if rec.Code != http.StatusBadRequest {
		t.Fatalf("expected 400, got %d: %s", rec.Code, rec.Body.String())
	}
}

func TestListComments_Success(t *testing.T) {
	db := newTestDB(t)
	user := seedTestUser(t, db, "firebase-uid-comment-list-1")
	other := seedTestUser(t, db, "firebase-uid-comment-list-2")
	encounter := orderedEncounter(user.ID, other.ID, jsonDate(t, "2026-03-01"))
	if err := db.Create(&encounter).Error; err != nil {
		t.Fatalf("create encounter: %v", err)
	}

	// seed two comments
	comment1 := model.Comment{
		ID:              uuid.NewString(),
		EncounterID:     encounter.ID,
		CommenterUserID: user.ID,
		Content:         "first comment",
	}
	comment2 := model.Comment{
		ID:              uuid.NewString(),
		EncounterID:     encounter.ID,
		CommenterUserID: other.ID,
		Content:         "second comment",
	}
	if err := db.Create(&comment1).Error; err != nil {
		t.Fatalf("create comment1: %v", err)
	}
	if err := db.Create(&comment2).Error; err != nil {
		t.Fatalf("create comment2: %v", err)
	}

	e := newTestServer(t, db, "firebase-uid-comment-list-1")

	req, err := authRequest(http.MethodGet, "/api/v1/encounters/"+encounter.ID+"/comments", nil)
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
	comments := body["comments"].([]any)
	if len(comments) != 2 {
		t.Fatalf("expected 2 comments, got %d", len(comments))
	}
	pagination := body["pagination"].(map[string]any)
	if pagination["has_more"].(bool) {
		t.Fatal("expected has_more false")
	}
	if pagination["next_cursor"] != nil {
		t.Fatalf("expected next_cursor null, got %v", pagination["next_cursor"])
	}
}

func TestListComments_NonParticipantReturns404(t *testing.T) {
	db := newTestDB(t)
	user1 := seedTestUser(t, db, "firebase-uid-comment-list-nonpart-1")
	user2 := seedTestUser(t, db, "firebase-uid-comment-list-nonpart-2")
	_ = seedTestUser(t, db, "firebase-uid-comment-list-nonpart-3")
	encounter := orderedEncounter(user1.ID, user2.ID, jsonDate(t, "2026-03-01"))
	if err := db.Create(&encounter).Error; err != nil {
		t.Fatalf("create encounter: %v", err)
	}

	e := newTestServer(t, db, "firebase-uid-comment-list-nonpart-3")

	req, err := authRequest(http.MethodGet, "/api/v1/encounters/"+encounter.ID+"/comments", nil)
	if err != nil {
		t.Fatalf("new request: %v", err)
	}
	rec := httptest.NewRecorder()
	e.ServeHTTP(rec, req)

	if rec.Code != http.StatusNotFound {
		t.Fatalf("expected 404, got %d: %s", rec.Code, rec.Body.String())
	}
}

func TestListComments_Pagination(t *testing.T) {
	db := newTestDB(t)
	user := seedTestUser(t, db, "firebase-uid-comment-page-1")
	other := seedTestUser(t, db, "firebase-uid-comment-page-2")
	encounter := orderedEncounter(user.ID, other.ID, jsonDate(t, "2026-03-01"))
	if err := db.Create(&encounter).Error; err != nil {
		t.Fatalf("create encounter: %v", err)
	}

	// seed 3 comments
	for i := 0; i < 3; i++ {
		c := model.Comment{
			ID:              uuid.NewString(),
			EncounterID:     encounter.ID,
			CommenterUserID: user.ID,
			Content:         "comment",
		}
		if err := db.Create(&c).Error; err != nil {
			t.Fatalf("create comment: %v", err)
		}
	}

	e := newTestServer(t, db, "firebase-uid-comment-page-1")

	req, err := authRequest(http.MethodGet, "/api/v1/encounters/"+encounter.ID+"/comments?limit=2", nil)
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
	comments := body["comments"].([]any)
	if len(comments) != 2 {
		t.Fatalf("expected 2 comments (page 1), got %d", len(comments))
	}
	pagination := body["pagination"].(map[string]any)
	if !pagination["has_more"].(bool) {
		t.Fatal("expected has_more true")
	}
	if pagination["next_cursor"] == nil {
		t.Fatal("expected non-null next_cursor")
	}
}

func TestDeleteComment_Success(t *testing.T) {
	db := newTestDB(t)
	user := seedTestUser(t, db, "firebase-uid-comment-del-1")
	other := seedTestUser(t, db, "firebase-uid-comment-del-2")
	encounter := orderedEncounter(user.ID, other.ID, jsonDate(t, "2026-03-01"))
	if err := db.Create(&encounter).Error; err != nil {
		t.Fatalf("create encounter: %v", err)
	}
	comment := model.Comment{
		ID:              uuid.NewString(),
		EncounterID:     encounter.ID,
		CommenterUserID: user.ID,
		Content:         "to be deleted",
	}
	if err := db.Create(&comment).Error; err != nil {
		t.Fatalf("create comment: %v", err)
	}

	e := newTestServer(t, db, "firebase-uid-comment-del-1")

	req, err := authRequest(http.MethodDelete, "/api/v1/comments/"+comment.ID, nil)
	if err != nil {
		t.Fatalf("new request: %v", err)
	}
	rec := httptest.NewRecorder()
	e.ServeHTTP(rec, req)

	if rec.Code != http.StatusNoContent {
		t.Fatalf("expected 204, got %d: %s", rec.Code, rec.Body.String())
	}

	// verify soft delete
	var count int64
	if err := db.Model(&model.Comment{}).Where("id = ? AND deleted_at IS NULL", comment.ID).Count(&count).Error; err != nil {
		t.Fatalf("count comment: %v", err)
	}
	if count != 0 {
		t.Fatal("expected comment to be soft-deleted")
	}
}

func TestDeleteComment_OtherUserReturns403(t *testing.T) {
	db := newTestDB(t)
	user := seedTestUser(t, db, "firebase-uid-comment-del-owner")
	other := seedTestUser(t, db, "firebase-uid-comment-del-other")
	encounter := orderedEncounter(user.ID, other.ID, jsonDate(t, "2026-03-01"))
	if err := db.Create(&encounter).Error; err != nil {
		t.Fatalf("create encounter: %v", err)
	}
	comment := model.Comment{
		ID:              uuid.NewString(),
		EncounterID:     encounter.ID,
		CommenterUserID: user.ID,
		Content:         "mine",
	}
	if err := db.Create(&comment).Error; err != nil {
		t.Fatalf("create comment: %v", err)
	}

	// other user tries to delete owner's comment
	e := newTestServer(t, db, "firebase-uid-comment-del-other")

	req, err := authRequest(http.MethodDelete, "/api/v1/comments/"+comment.ID, nil)
	if err != nil {
		t.Fatalf("new request: %v", err)
	}
	rec := httptest.NewRecorder()
	e.ServeHTTP(rec, req)

	if rec.Code != http.StatusForbidden {
		t.Fatalf("expected 403, got %d: %s", rec.Code, rec.Body.String())
	}
}

func TestDeleteComment_NonExistentReturns404(t *testing.T) {
	db := newTestDB(t)
	seedTestUser(t, db, "firebase-uid-comment-del-notfound")
	e := newTestServer(t, db, "firebase-uid-comment-del-notfound")

	req, err := authRequest(http.MethodDelete, "/api/v1/comments/"+uuid.NewString(), nil)
	if err != nil {
		t.Fatalf("new request: %v", err)
	}
	rec := httptest.NewRecorder()
	e.ServeHTTP(rec, req)

	if rec.Code != http.StatusNotFound {
		t.Fatalf("expected 404, got %d: %s", rec.Code, rec.Body.String())
	}
}
