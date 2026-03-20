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

func TestListMySongs_ReturnsLyriaFields(t *testing.T) {
	db := newTestDB(t)
	user := seedTestUser(t, db, "firebase-uid-songs-lyria-fields")
	other := seedTestUser(t, db, "firebase-uid-songs-lyria-fields-other")
	e := newTestServer(t, db, "firebase-uid-songs-lyria-fields")

	encounter := orderedEncounter(user.ID, other.ID, jsonDate(t, "2026-03-01"))
	if err := db.Create(&encounter).Error; err != nil {
		t.Fatalf("create encounter: %v", err)
	}

	chainID := uuid.NewString()
	if err := db.Create(&model.LyricChain{ID: chainID, Status: "completed", ParticipantCount: 4, Threshold: 4}).Error; err != nil {
		t.Fatalf("create chain: %v", err)
	}

	line := "夜明けのメロディが流れる"
	if err := db.Create(&model.LyricEntry{
		ID:          uuid.NewString(),
		ChainID:     chainID,
		UserID:      user.ID,
		EncounterID: encounter.ID,
		Content:     line,
		SequenceNum: 1,
	}).Error; err != nil {
		t.Fatalf("create lyric entry: %v", err)
	}

	title := "夜明けの詩"
	audioURL := "https://example.com/song.mp3"
	durationSec := 45
	mood := "upbeat"
	now := time.Now().UTC()
	if err := db.Create(&model.GeneratedSong{
		ID:          uuid.NewString(),
		ChainID:     chainID,
		Title:       &title,
		AudioURL:    &audioURL,
		DurationSec: &durationSec,
		Mood:        &mood,
		Status:      "completed",
		GeneratedAt: &now,
	}).Error; err != nil {
		t.Fatalf("create song: %v", err)
	}

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
	if len(songs) != 1 {
		t.Fatalf("expected 1 song, got %d", len(songs))
	}

	song := songs[0].(map[string]any)
	if song["chain_id"] != chainID {
		t.Fatalf("expected chain_id %q, got %v", chainID, song["chain_id"])
	}
	if song["duration_sec"].(float64) != float64(durationSec) {
		t.Fatalf("expected duration_sec %d, got %v", durationSec, song["duration_sec"])
	}
	if song["mood"] != mood {
		t.Fatalf("expected mood %q, got %v", mood, song["mood"])
	}
	if song["audio_url"] != audioURL {
		t.Fatalf("expected audio_url %q, got %v", audioURL, song["audio_url"])
	}
	if song["my_lyric"] != line {
		t.Fatalf("expected my_lyric %q, got %v", line, song["my_lyric"])
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
