package handler

import (
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"testing"

	"github.com/google/uuid"

	"hackathon/internal/infra/rdb/model"
)

// --- POST /users/me/tracks ---

func TestAddUserTrack_Success(t *testing.T) {
	db := newTestDB(t)
	user := seedTestUser(t, db, "firebase-uid-usertrack-add-1")
	e := newTestServer(t, db, "firebase-uid-usertrack-add-1")

	// Seed a track in the catalog.
	track := model.Track{
		ID:         uuid.NewString(),
		ExternalID: "abc123",
		Provider:   "spotify",
		Title:      "Song A",
		ArtistName: "Artist A",
	}
	if err := db.Create(&track).Error; err != nil {
		t.Fatalf("seed track: %v", err)
	}
	_ = user

	req, err := authRequest(http.MethodPost, "/api/v1/users/me/tracks", map[string]any{
		"track_id": "spotify:track:abc123",
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
	track2 := body["track"].(map[string]any)
	if track2["id"].(string) != "spotify:track:abc123" {
		t.Fatalf("expected track id spotify:track:abc123, got %v", track2["id"])
	}
	if track2["title"].(string) != "Song A" {
		t.Fatalf("expected title Song A, got %v", track2["title"])
	}
}

func TestAddUserTrack_DuplicateReturns200(t *testing.T) {
	db := newTestDB(t)
	seedTestUser(t, db, "firebase-uid-usertrack-dup-1")
	e := newTestServer(t, db, "firebase-uid-usertrack-dup-1")

	track := model.Track{
		ID:         uuid.NewString(),
		ExternalID: "dup001",
		Provider:   "spotify",
		Title:      "Dup Song",
		ArtistName: "Artist",
	}
	if err := db.Create(&track).Error; err != nil {
		t.Fatalf("seed track: %v", err)
	}

	reqBody := map[string]any{"track_id": "spotify:track:dup001"}

	req1, _ := authRequest(http.MethodPost, "/api/v1/users/me/tracks", reqBody)
	rec1 := httptest.NewRecorder()
	e.ServeHTTP(rec1, req1)
	if rec1.Code != http.StatusCreated {
		t.Fatalf("expected 201 on first add, got %d: %s", rec1.Code, rec1.Body.String())
	}

	req2, _ := authRequest(http.MethodPost, "/api/v1/users/me/tracks", reqBody)
	rec2 := httptest.NewRecorder()
	e.ServeHTTP(rec2, req2)
	if rec2.Code != http.StatusOK {
		t.Fatalf("expected 200 on duplicate, got %d: %s", rec2.Code, rec2.Body.String())
	}
}

func TestAddUserTrack_MissingTrackIDReturns400(t *testing.T) {
	db := newTestDB(t)
	seedTestUser(t, db, "firebase-uid-usertrack-missing-1")
	e := newTestServer(t, db, "firebase-uid-usertrack-missing-1")

	req, _ := authRequest(http.MethodPost, "/api/v1/users/me/tracks", map[string]any{})
	rec := httptest.NewRecorder()
	e.ServeHTTP(rec, req)

	if rec.Code != http.StatusBadRequest {
		t.Fatalf("expected 400, got %d: %s", rec.Code, rec.Body.String())
	}
}

func TestAddUserTrack_NonExistentTrackReturns404(t *testing.T) {
	db := newTestDB(t)
	seedTestUser(t, db, "firebase-uid-usertrack-notfound-1")
	e := newTestServer(t, db, "firebase-uid-usertrack-notfound-1")

	req, _ := authRequest(http.MethodPost, "/api/v1/users/me/tracks", map[string]any{
		"track_id": "spotify:track:doesnotexist",
	})
	rec := httptest.NewRecorder()
	e.ServeHTTP(rec, req)

	if rec.Code != http.StatusNotFound {
		t.Fatalf("expected 404, got %d: %s", rec.Code, rec.Body.String())
	}
}

// --- GET /users/me/tracks ---

func TestListUserTracks_Empty(t *testing.T) {
	db := newTestDB(t)
	seedTestUser(t, db, "firebase-uid-usertrack-list-empty")
	e := newTestServer(t, db, "firebase-uid-usertrack-list-empty")

	req, _ := authRequest(http.MethodGet, "/api/v1/users/me/tracks", nil)
	rec := httptest.NewRecorder()
	e.ServeHTTP(rec, req)

	if rec.Code != http.StatusOK {
		t.Fatalf("expected 200, got %d: %s", rec.Code, rec.Body.String())
	}

	var body map[string]any
	if err := json.Unmarshal(rec.Body.Bytes(), &body); err != nil {
		t.Fatalf("unmarshal response: %v", err)
	}
	tracks := body["tracks"].([]any)
	if len(tracks) != 0 {
		t.Fatalf("expected empty tracks, got %d", len(tracks))
	}
	pagination := body["pagination"].(map[string]any)
	if pagination["has_more"].(bool) {
		t.Fatal("expected has_more false")
	}
}

func TestListUserTracks_WithItems(t *testing.T) {
	db := newTestDB(t)
	user := seedTestUser(t, db, "firebase-uid-usertrack-list-items")
	e := newTestServer(t, db, "firebase-uid-usertrack-list-items")

	track1 := model.Track{ID: uuid.NewString(), ExternalID: "t001", Provider: "spotify", Title: "Song 1", ArtistName: "Artist"}
	track2 := model.Track{ID: uuid.NewString(), ExternalID: "t002", Provider: "spotify", Title: "Song 2", ArtistName: "Artist"}
	if err := db.Create(&track1).Error; err != nil {
		t.Fatalf("seed track1: %v", err)
	}
	if err := db.Create(&track2).Error; err != nil {
		t.Fatalf("seed track2: %v", err)
	}

	ut1 := model.UserTrack{ID: uuid.NewString(), UserID: user.ID, TrackID: track1.ID}
	ut2 := model.UserTrack{ID: uuid.NewString(), UserID: user.ID, TrackID: track2.ID}
	if err := db.Create(&ut1).Error; err != nil {
		t.Fatalf("seed user_track1: %v", err)
	}
	if err := db.Create(&ut2).Error; err != nil {
		t.Fatalf("seed user_track2: %v", err)
	}

	req, _ := authRequest(http.MethodGet, "/api/v1/users/me/tracks", nil)
	rec := httptest.NewRecorder()
	e.ServeHTTP(rec, req)

	if rec.Code != http.StatusOK {
		t.Fatalf("expected 200, got %d: %s", rec.Code, rec.Body.String())
	}

	var body map[string]any
	if err := json.Unmarshal(rec.Body.Bytes(), &body); err != nil {
		t.Fatalf("unmarshal response: %v", err)
	}
	tracks := body["tracks"].([]any)
	if len(tracks) != 2 {
		t.Fatalf("expected 2 tracks, got %d", len(tracks))
	}
}

func TestListUserTracks_Pagination(t *testing.T) {
	db := newTestDB(t)
	user := seedTestUser(t, db, "firebase-uid-usertrack-list-page")
	e := newTestServer(t, db, "firebase-uid-usertrack-list-page")

	for i := 0; i < 3; i++ {
		externalID := "page" + string(rune('0'+i))
		track := model.Track{ID: uuid.NewString(), ExternalID: externalID, Provider: "spotify", Title: "Song", ArtistName: "Artist"}
		if err := db.Create(&track).Error; err != nil {
			t.Fatalf("seed track %d: %v", i, err)
		}
		ut := model.UserTrack{ID: uuid.NewString(), UserID: user.ID, TrackID: track.ID}
		if err := db.Create(&ut).Error; err != nil {
			t.Fatalf("seed user_track %d: %v", i, err)
		}
	}

	// Fetch first page with limit=2
	req1, _ := authRequest(http.MethodGet, "/api/v1/users/me/tracks?limit=2", nil)
	rec1 := httptest.NewRecorder()
	e.ServeHTTP(rec1, req1)
	if rec1.Code != http.StatusOK {
		t.Fatalf("expected 200, got %d: %s", rec1.Code, rec1.Body.String())
	}

	var body1 map[string]any
	if err := json.Unmarshal(rec1.Body.Bytes(), &body1); err != nil {
		t.Fatalf("unmarshal first page: %v", err)
	}
	tracks1 := body1["tracks"].([]any)
	if len(tracks1) != 2 {
		t.Fatalf("expected 2 tracks on first page, got %d", len(tracks1))
	}
	pagination1 := body1["pagination"].(map[string]any)
	if !pagination1["has_more"].(bool) {
		t.Fatal("expected has_more true on first page")
	}
	nextCursor := pagination1["next_cursor"].(string)
	if nextCursor == "" {
		t.Fatal("expected non-empty next_cursor")
	}

	// Fetch second page
	req2, _ := authRequest(http.MethodGet, "/api/v1/users/me/tracks?limit=2&cursor="+nextCursor, nil)
	rec2 := httptest.NewRecorder()
	e.ServeHTTP(rec2, req2)
	if rec2.Code != http.StatusOK {
		t.Fatalf("expected 200, got %d: %s", rec2.Code, rec2.Body.String())
	}

	var body2 map[string]any
	if err := json.Unmarshal(rec2.Body.Bytes(), &body2); err != nil {
		t.Fatalf("unmarshal second page: %v", err)
	}
	tracks2 := body2["tracks"].([]any)
	if len(tracks2) != 1 {
		t.Fatalf("expected 1 track on second page, got %d", len(tracks2))
	}
	pagination2 := body2["pagination"].(map[string]any)
	if pagination2["has_more"].(bool) {
		t.Fatal("expected has_more false on second page")
	}
}

// --- DELETE /users/me/tracks/{id} ---

func TestDeleteUserTrack_Success(t *testing.T) {
	db := newTestDB(t)
	user := seedTestUser(t, db, "firebase-uid-usertrack-del-1")
	e := newTestServer(t, db, "firebase-uid-usertrack-del-1")

	track := model.Track{ID: uuid.NewString(), ExternalID: "del001", Provider: "spotify", Title: "Del Song", ArtistName: "Artist"}
	if err := db.Create(&track).Error; err != nil {
		t.Fatalf("seed track: %v", err)
	}
	ut := model.UserTrack{ID: uuid.NewString(), UserID: user.ID, TrackID: track.ID}
	if err := db.Create(&ut).Error; err != nil {
		t.Fatalf("seed user_track: %v", err)
	}

	req, _ := authRequest(http.MethodDelete, "/api/v1/users/me/tracks/spotify:track:del001", nil)
	rec := httptest.NewRecorder()
	e.ServeHTTP(rec, req)

	if rec.Code != http.StatusNoContent {
		t.Fatalf("expected 204, got %d: %s", rec.Code, rec.Body.String())
	}

	var count int64
	if err := db.Unscoped().Model(&model.UserTrack{}).Where("id = ? AND deleted_at IS NOT NULL", ut.ID).Count(&count).Error; err != nil {
		t.Fatalf("count: %v", err)
	}
	if count != 1 {
		t.Fatalf("expected soft-deleted user track, count=%d", count)
	}
}

func TestDeleteUserTrack_NotFoundReturns404(t *testing.T) {
	db := newTestDB(t)
	seedTestUser(t, db, "firebase-uid-usertrack-del-notfound")
	e := newTestServer(t, db, "firebase-uid-usertrack-del-notfound")

	track := model.Track{ID: uuid.NewString(), ExternalID: "nf001", Provider: "spotify", Title: "NF Song", ArtistName: "Artist"}
	if err := db.Create(&track).Error; err != nil {
		t.Fatalf("seed track: %v", err)
	}

	req, _ := authRequest(http.MethodDelete, "/api/v1/users/me/tracks/spotify:track:nf001", nil)
	rec := httptest.NewRecorder()
	e.ServeHTTP(rec, req)

	if rec.Code != http.StatusNotFound {
		t.Fatalf("expected 404, got %d: %s", rec.Code, rec.Body.String())
	}
}

// --- GET /users/me/shared-track ---

func TestGetSharedTrack_NotSet(t *testing.T) {
	db := newTestDB(t)
	seedTestUser(t, db, "firebase-uid-shared-get-empty")
	e := newTestServer(t, db, "firebase-uid-shared-get-empty")

	req, _ := authRequest(http.MethodGet, "/api/v1/users/me/shared-track", nil)
	rec := httptest.NewRecorder()
	e.ServeHTTP(rec, req)

	if rec.Code != http.StatusOK {
		t.Fatalf("expected 200, got %d: %s", rec.Code, rec.Body.String())
	}

	var body map[string]any
	if err := json.Unmarshal(rec.Body.Bytes(), &body); err != nil {
		t.Fatalf("unmarshal response: %v", err)
	}
	if body["shared_track"] != nil {
		t.Fatalf("expected shared_track null, got %v", body["shared_track"])
	}
}

func TestGetSharedTrack_WhenSet(t *testing.T) {
	db := newTestDB(t)
	user := seedTestUser(t, db, "firebase-uid-shared-get-set")
	e := newTestServer(t, db, "firebase-uid-shared-get-set")

	track := model.Track{ID: uuid.NewString(), ExternalID: "sh001", Provider: "spotify", Title: "Shared Song", ArtistName: "Artist"}
	if err := db.Create(&track).Error; err != nil {
		t.Fatalf("seed track: %v", err)
	}
	ct := model.UserCurrentTrack{ID: uuid.NewString(), UserID: user.ID, TrackID: track.ID}
	if err := db.Create(&ct).Error; err != nil {
		t.Fatalf("seed user_current_track: %v", err)
	}

	req, _ := authRequest(http.MethodGet, "/api/v1/users/me/shared-track", nil)
	rec := httptest.NewRecorder()
	e.ServeHTTP(rec, req)

	if rec.Code != http.StatusOK {
		t.Fatalf("expected 200, got %d: %s", rec.Code, rec.Body.String())
	}

	var body map[string]any
	if err := json.Unmarshal(rec.Body.Bytes(), &body); err != nil {
		t.Fatalf("unmarshal response: %v", err)
	}
	shared := body["shared_track"].(map[string]any)
	if shared["id"].(string) != "spotify:track:sh001" {
		t.Fatalf("expected id spotify:track:sh001, got %v", shared["id"])
	}
	if shared["title"].(string) != "Shared Song" {
		t.Fatalf("expected title Shared Song, got %v", shared["title"])
	}
	if shared["updated_at"] == nil || shared["updated_at"].(string) == "" {
		t.Fatal("expected non-empty updated_at")
	}
}

// --- PUT /users/me/shared-track ---

func TestUpsertSharedTrack_FirstTime201(t *testing.T) {
	db := newTestDB(t)
	seedTestUser(t, db, "firebase-uid-shared-put-new")
	e := newTestServer(t, db, "firebase-uid-shared-put-new")

	track := model.Track{ID: uuid.NewString(), ExternalID: "put001", Provider: "spotify", Title: "Put Song", ArtistName: "Artist"}
	if err := db.Create(&track).Error; err != nil {
		t.Fatalf("seed track: %v", err)
	}

	req, _ := authRequest(http.MethodPut, "/api/v1/users/me/shared-track", map[string]any{
		"track_id": "spotify:track:put001",
	})
	rec := httptest.NewRecorder()
	e.ServeHTTP(rec, req)

	if rec.Code != http.StatusCreated {
		t.Fatalf("expected 201, got %d: %s", rec.Code, rec.Body.String())
	}

	var body map[string]any
	if err := json.Unmarshal(rec.Body.Bytes(), &body); err != nil {
		t.Fatalf("unmarshal response: %v", err)
	}
	shared := body["shared_track"].(map[string]any)
	if shared["id"].(string) != "spotify:track:put001" {
		t.Fatalf("expected id spotify:track:put001, got %v", shared["id"])
	}
}

func TestUpsertSharedTrack_SameTrackReturns200(t *testing.T) {
	db := newTestDB(t)
	user := seedTestUser(t, db, "firebase-uid-shared-put-same")
	e := newTestServer(t, db, "firebase-uid-shared-put-same")

	track := model.Track{ID: uuid.NewString(), ExternalID: "same001", Provider: "spotify", Title: "Same Song", ArtistName: "Artist"}
	if err := db.Create(&track).Error; err != nil {
		t.Fatalf("seed track: %v", err)
	}
	// Pre-set the shared track
	ct := model.UserCurrentTrack{ID: uuid.NewString(), UserID: user.ID, TrackID: track.ID}
	if err := db.Create(&ct).Error; err != nil {
		t.Fatalf("seed user_current_track: %v", err)
	}

	req, _ := authRequest(http.MethodPut, "/api/v1/users/me/shared-track", map[string]any{
		"track_id": "spotify:track:same001",
	})
	rec := httptest.NewRecorder()
	e.ServeHTTP(rec, req)

	if rec.Code != http.StatusOK {
		t.Fatalf("expected 200 for same track, got %d: %s", rec.Code, rec.Body.String())
	}
}

func TestUpsertSharedTrack_UpdateReturns200(t *testing.T) {
	db := newTestDB(t)
	user := seedTestUser(t, db, "firebase-uid-shared-put-update")
	e := newTestServer(t, db, "firebase-uid-shared-put-update")

	track1 := model.Track{ID: uuid.NewString(), ExternalID: "upd001", Provider: "spotify", Title: "Song 1", ArtistName: "Artist"}
	track2 := model.Track{ID: uuid.NewString(), ExternalID: "upd002", Provider: "spotify", Title: "Song 2", ArtistName: "Artist"}
	if err := db.Create(&track1).Error; err != nil {
		t.Fatalf("seed track1: %v", err)
	}
	if err := db.Create(&track2).Error; err != nil {
		t.Fatalf("seed track2: %v", err)
	}
	// Pre-set shared track to track1
	ct := model.UserCurrentTrack{ID: uuid.NewString(), UserID: user.ID, TrackID: track1.ID}
	if err := db.Create(&ct).Error; err != nil {
		t.Fatalf("seed user_current_track: %v", err)
	}

	// Update to track2
	req, _ := authRequest(http.MethodPut, "/api/v1/users/me/shared-track", map[string]any{
		"track_id": "spotify:track:upd002",
	})
	rec := httptest.NewRecorder()
	e.ServeHTTP(rec, req)

	if rec.Code != http.StatusOK {
		t.Fatalf("expected 200 on update, got %d: %s", rec.Code, rec.Body.String())
	}

	var body map[string]any
	if err := json.Unmarshal(rec.Body.Bytes(), &body); err != nil {
		t.Fatalf("unmarshal response: %v", err)
	}
	shared := body["shared_track"].(map[string]any)
	if shared["id"].(string) != "spotify:track:upd002" {
		t.Fatalf("expected updated track id, got %v", shared["id"])
	}
}

func TestUpsertSharedTrack_MissingTrackIDReturns400(t *testing.T) {
	db := newTestDB(t)
	seedTestUser(t, db, "firebase-uid-shared-put-missing")
	e := newTestServer(t, db, "firebase-uid-shared-put-missing")

	req, _ := authRequest(http.MethodPut, "/api/v1/users/me/shared-track", map[string]any{})
	rec := httptest.NewRecorder()
	e.ServeHTTP(rec, req)

	if rec.Code != http.StatusBadRequest {
		t.Fatalf("expected 400, got %d: %s", rec.Code, rec.Body.String())
	}
}

// --- DELETE /users/me/shared-track ---

func TestDeleteSharedTrack_Success(t *testing.T) {
	db := newTestDB(t)
	user := seedTestUser(t, db, "firebase-uid-shared-del-1")
	e := newTestServer(t, db, "firebase-uid-shared-del-1")

	track := model.Track{ID: uuid.NewString(), ExternalID: "shdel001", Provider: "spotify", Title: "Del Song", ArtistName: "Artist"}
	if err := db.Create(&track).Error; err != nil {
		t.Fatalf("seed track: %v", err)
	}
	ct := model.UserCurrentTrack{ID: uuid.NewString(), UserID: user.ID, TrackID: track.ID}
	if err := db.Create(&ct).Error; err != nil {
		t.Fatalf("seed user_current_track: %v", err)
	}

	req, _ := authRequest(http.MethodDelete, "/api/v1/users/me/shared-track", nil)
	rec := httptest.NewRecorder()
	e.ServeHTTP(rec, req)

	if rec.Code != http.StatusNoContent {
		t.Fatalf("expected 204, got %d: %s", rec.Code, rec.Body.String())
	}

	var count int64
	if err := db.Model(&model.UserCurrentTrack{}).Where("user_id = ?", user.ID).Count(&count).Error; err != nil {
		t.Fatalf("count: %v", err)
	}
	if count != 0 {
		t.Fatalf("expected 0 shared tracks after delete, got %d", count)
	}
}

func TestDeleteSharedTrack_NotFoundReturns404(t *testing.T) {
	db := newTestDB(t)
	seedTestUser(t, db, "firebase-uid-shared-del-notfound")
	e := newTestServer(t, db, "firebase-uid-shared-del-notfound")

	req, _ := authRequest(http.MethodDelete, "/api/v1/users/me/shared-track", nil)
	rec := httptest.NewRecorder()
	e.ServeHTTP(rec, req)

	if rec.Code != http.StatusNotFound {
		t.Fatalf("expected 404, got %d: %s", rec.Code, rec.Body.String())
	}
}
