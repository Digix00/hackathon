package handler

import (
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"testing"
	"time"

	"github.com/google/uuid"

	"hackathon/internal/infra/rdb/model"
)

func TestListMySongs_EmptyReturns200(t *testing.T) {
	db := newTestDB(t)
	seedTestUser(t, db, "firebase-uid-songs-empty")
	e := newTestServer(t, db, "firebase-uid-songs-empty")

	req, err := authRequest(http.MethodGet, "/api/v1/users/me/songs", nil)
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
		t.Fatalf("unmarshal: %v", err)
	}

	songs := body["songs"].([]any)
	if len(songs) != 0 {
		t.Fatalf("expected 0 songs, got %d", len(songs))
	}

	pagination := body["pagination"].(map[string]any)
	if pagination["has_more"].(bool) != false {
		t.Fatal("expected has_more false")
	}
	if pagination["next_cursor"] != nil {
		t.Fatalf("expected next_cursor nil, got %v", pagination["next_cursor"])
	}
}

func TestLikeSong_Success(t *testing.T) {
	db := newTestDB(t)
	user := seedTestUser(t, db, "firebase-uid-like-song-1")
	other := seedTestUser(t, db, "firebase-uid-like-song-other-1")
	e := newTestServer(t, db, "firebase-uid-like-song-1")

	encounter := orderedEncounter(user.ID, other.ID, jsonDate(t, "2026-03-01"))
	if err := db.Create(&encounter).Error; err != nil {
		t.Fatalf("create encounter: %v", err)
	}

	chainID := uuid.NewString()
	if err := db.Create(&model.LyricChain{ID: chainID, Status: "completed", ParticipantCount: 1, Threshold: 4}).Error; err != nil {
		t.Fatalf("create chain: %v", err)
	}

	songID := uuid.NewString()
	now := time.Now().UTC()
	if err := db.Create(&model.GeneratedSong{ID: songID, ChainID: chainID, Status: "completed", GeneratedAt: &now}).Error; err != nil {
		t.Fatalf("create song: %v", err)
	}

	req, err := authRequest(http.MethodPost, "/api/v1/songs/"+songID+"/likes", nil)
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
		t.Fatalf("unmarshal: %v", err)
	}
	if body["liked"].(bool) != true {
		t.Fatal("expected liked true")
	}

	var count int64
	if err := db.Model(&model.SongLike{}).Where("user_id = ? AND song_id = ?", user.ID, songID).Count(&count).Error; err != nil {
		t.Fatalf("count likes: %v", err)
	}
	if count != 1 {
		t.Fatalf("expected 1 like, got %d", count)
	}
}

func TestLikeSong_NotFoundSong(t *testing.T) {
	db := newTestDB(t)
	seedTestUser(t, db, "firebase-uid-like-notfound")
	e := newTestServer(t, db, "firebase-uid-like-notfound")

	req, _ := authRequest(http.MethodPost, "/api/v1/songs/"+uuid.NewString()+"/likes", nil)
	rec := httptest.NewRecorder()
	e.ServeHTTP(rec, req)

	if rec.Code != http.StatusNotFound {
		t.Fatalf("expected 404, got %d: %s", rec.Code, rec.Body.String())
	}
}

func TestLikeSong_DuplicateLike(t *testing.T) {
	db := newTestDB(t)
	user := seedTestUser(t, db, "firebase-uid-like-dup-1")
	other := seedTestUser(t, db, "firebase-uid-like-dup-other")
	e := newTestServer(t, db, "firebase-uid-like-dup-1")

	encounter := orderedEncounter(user.ID, other.ID, jsonDate(t, "2026-03-01"))
	if err := db.Create(&encounter).Error; err != nil {
		t.Fatalf("create encounter: %v", err)
	}

	chainID := uuid.NewString()
	if err := db.Create(&model.LyricChain{ID: chainID, Status: "completed", ParticipantCount: 1, Threshold: 4}).Error; err != nil {
		t.Fatalf("create chain: %v", err)
	}

	songID := uuid.NewString()
	now := time.Now().UTC()
	if err := db.Create(&model.GeneratedSong{ID: songID, ChainID: chainID, Status: "completed", GeneratedAt: &now}).Error; err != nil {
		t.Fatalf("create song: %v", err)
	}

	if err := db.Create(&model.SongLike{ID: uuid.NewString(), SongID: songID, UserID: user.ID}).Error; err != nil {
		t.Fatalf("create existing like: %v", err)
	}

	req, _ := authRequest(http.MethodPost, "/api/v1/songs/"+songID+"/likes", nil)
	rec := httptest.NewRecorder()
	e.ServeHTTP(rec, req)

	if rec.Code != http.StatusConflict {
		t.Fatalf("expected 409, got %d: %s", rec.Code, rec.Body.String())
	}
}

func TestUnlikeSong_Success(t *testing.T) {
	db := newTestDB(t)
	user := seedTestUser(t, db, "firebase-uid-unlike-1")
	other := seedTestUser(t, db, "firebase-uid-unlike-other")
	e := newTestServer(t, db, "firebase-uid-unlike-1")

	encounter := orderedEncounter(user.ID, other.ID, jsonDate(t, "2026-03-01"))
	if err := db.Create(&encounter).Error; err != nil {
		t.Fatalf("create encounter: %v", err)
	}

	chainID := uuid.NewString()
	if err := db.Create(&model.LyricChain{ID: chainID, Status: "completed", ParticipantCount: 1, Threshold: 4}).Error; err != nil {
		t.Fatalf("create chain: %v", err)
	}

	songID := uuid.NewString()
	now := time.Now().UTC()
	if err := db.Create(&model.GeneratedSong{ID: songID, ChainID: chainID, Status: "completed", GeneratedAt: &now}).Error; err != nil {
		t.Fatalf("create song: %v", err)
	}

	likeID := uuid.NewString()
	if err := db.Create(&model.SongLike{ID: likeID, SongID: songID, UserID: user.ID}).Error; err != nil {
		t.Fatalf("create like: %v", err)
	}

	req, _ := authRequest(http.MethodDelete, "/api/v1/songs/"+songID+"/likes", nil)
	rec := httptest.NewRecorder()
	e.ServeHTTP(rec, req)

	if rec.Code != http.StatusNoContent {
		t.Fatalf("expected 204, got %d: %s", rec.Code, rec.Body.String())
	}

	var count int64
	if err := db.Unscoped().Model(&model.SongLike{}).Where("id = ? AND deleted_at IS NOT NULL", likeID).Count(&count).Error; err != nil {
		t.Fatalf("count likes: %v", err)
	}
	if count != 1 {
		t.Fatalf("expected soft-deleted like, count=%d", count)
	}
}

func TestUnlikeSong_NotFound(t *testing.T) {
	db := newTestDB(t)
	seedTestUser(t, db, "firebase-uid-unlike-notfound")
	e := newTestServer(t, db, "firebase-uid-unlike-notfound")

	req, _ := authRequest(http.MethodDelete, "/api/v1/songs/"+uuid.NewString()+"/likes", nil)
	rec := httptest.NewRecorder()
	e.ServeHTTP(rec, req)

	if rec.Code != http.StatusNotFound {
		t.Fatalf("expected 404, got %d: %s", rec.Code, rec.Body.String())
	}
}
