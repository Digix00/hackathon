package handler

import (
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"

	"github.com/google/uuid"

	"hackathon/internal/infra/rdb/model"
)

func TestSubmitLyric_Success(t *testing.T) {
	db := newTestDB(t)
	user := seedTestUser(t, db, "firebase-uid-lyric-submit-1")

	other := seedTestUser(t, db, "firebase-uid-lyric-submit-other-1")
	encounter := orderedEncounter(user.ID, other.ID, jsonDate(t, "2026-03-01"))
	if err := db.Create(&encounter).Error; err != nil {
		t.Fatalf("create encounter: %v", err)
	}

	e := newTestServer(t, db, "firebase-uid-lyric-submit-1")

	req, err := authRequest(http.MethodPost, "/api/v1/lyrics", map[string]any{
		"encounter_id": encounter.ID,
		"content":      "今日も空は青かった",
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
		t.Fatalf("unmarshal: %v", err)
	}

	entry := body["lyric_entry"].(map[string]any)
	if entry["id"] == nil || entry["id"].(string) == "" {
		t.Fatal("expected non-empty id")
	}
	if entry["content"].(string) != "今日も空は青かった" {
		t.Fatalf("unexpected content: %v", entry["content"])
	}
	if int(entry["sequence_num"].(float64)) != 1 {
		t.Fatalf("expected sequence_num 1, got %v", entry["sequence_num"])
	}

	chain := body["chain"].(map[string]any)
	if chain["status"].(string) != "pending" {
		t.Fatalf("expected status pending, got %v", chain["status"])
	}
	if int(chain["participant_count"].(float64)) != 1 {
		t.Fatalf("expected participant_count 1, got %v", chain["participant_count"])
	}
}

func TestSubmitLyric_MissingEncounterID(t *testing.T) {
	db := newTestDB(t)
	seedTestUser(t, db, "firebase-uid-lyric-missing-enc")
	e := newTestServer(t, db, "firebase-uid-lyric-missing-enc")

	req, err := authRequest(http.MethodPost, "/api/v1/lyrics", map[string]any{
		"content": "hello",
	})
	if err != nil {
		t.Fatalf("new request: %v", err)
	}
	rec := httptest.NewRecorder()
	e.ServeHTTP(rec, req)

	if rec.Code != http.StatusBadRequest {
		t.Fatalf("expected 400, got %d: %s", rec.Code, rec.Body.String())
	}
}

func TestSubmitLyric_MissingContent(t *testing.T) {
	db := newTestDB(t)
	seedTestUser(t, db, "firebase-uid-lyric-missing-content")
	e := newTestServer(t, db, "firebase-uid-lyric-missing-content")

	req, err := authRequest(http.MethodPost, "/api/v1/lyrics", map[string]any{
		"encounter_id": uuid.NewString(),
	})
	if err != nil {
		t.Fatalf("new request: %v", err)
	}
	rec := httptest.NewRecorder()
	e.ServeHTTP(rec, req)

	if rec.Code != http.StatusBadRequest {
		t.Fatalf("expected 400, got %d: %s", rec.Code, rec.Body.String())
	}
}

func TestSubmitLyric_ContentTooLong(t *testing.T) {
	db := newTestDB(t)
	seedTestUser(t, db, "firebase-uid-lyric-toolong")
	e := newTestServer(t, db, "firebase-uid-lyric-toolong")

	req, err := authRequest(http.MethodPost, "/api/v1/lyrics", map[string]any{
		"encounter_id": uuid.NewString(),
		"content":      strings.Repeat("あ", 101),
	})
	if err != nil {
		t.Fatalf("new request: %v", err)
	}
	rec := httptest.NewRecorder()
	e.ServeHTTP(rec, req)

	if rec.Code != http.StatusBadRequest {
		t.Fatalf("expected 400, got %d: %s", rec.Code, rec.Body.String())
	}
}

func TestSubmitLyric_SecondUserJoinsExistingChain(t *testing.T) {
	db := newTestDB(t)
	user1 := seedTestUser(t, db, "firebase-uid-lyric-join-1")
	user2 := seedTestUser(t, db, "firebase-uid-lyric-join-2")
	encounter1 := orderedEncounter(user1.ID, user2.ID, jsonDate(t, "2026-03-01"))
	if err := db.Create(&encounter1).Error; err != nil {
		t.Fatalf("create encounter: %v", err)
	}

	e1 := newTestServer(t, db, "firebase-uid-lyric-join-1")
	req1, _ := authRequest(http.MethodPost, "/api/v1/lyrics", map[string]any{
		"encounter_id": encounter1.ID,
		"content":      "first line",
	})
	rec1 := httptest.NewRecorder()
	e1.ServeHTTP(rec1, req1)
	if rec1.Code != http.StatusCreated {
		t.Fatalf("expected 201 for first submission, got %d: %s", rec1.Code, rec1.Body.String())
	}
	var body1 map[string]any
	if err := json.Unmarshal(rec1.Body.Bytes(), &body1); err != nil {
		t.Fatalf("unmarshal body1: %v", err)
	}
	chain1ID := body1["chain"].(map[string]any)["id"].(string)

	e2 := newTestServer(t, db, "firebase-uid-lyric-join-2")
	req2, _ := authRequest(http.MethodPost, "/api/v1/lyrics", map[string]any{
		"encounter_id": encounter1.ID,
		"content":      "second line",
	})
	rec2 := httptest.NewRecorder()
	e2.ServeHTTP(rec2, req2)
	if rec2.Code != http.StatusCreated {
		t.Fatalf("expected 201 for second submission, got %d: %s", rec2.Code, rec2.Body.String())
	}
	var body2 map[string]any
	if err := json.Unmarshal(rec2.Body.Bytes(), &body2); err != nil {
		t.Fatalf("unmarshal body2: %v", err)
	}
	chain2ID := body2["chain"].(map[string]any)["id"].(string)

	if chain1ID != chain2ID {
		t.Fatalf("expected user2 to join user1's chain %s, but got %s", chain1ID, chain2ID)
	}

	if int(body2["chain"].(map[string]any)["participant_count"].(float64)) != 2 {
		t.Fatalf("expected participant_count 2, got %v", body2["chain"].(map[string]any)["participant_count"])
	}
}

func TestGetChainDetail_Success(t *testing.T) {
	db := newTestDB(t)
	user := seedTestUser(t, db, "firebase-uid-chain-detail-1")
	e := newTestServer(t, db, "firebase-uid-chain-detail-1")

	chainID := uuid.NewString()
	if err := db.Create(&model.LyricChain{ID: chainID, Status: "pending", ParticipantCount: 1, Threshold: 4}).Error; err != nil {
		t.Fatalf("create chain: %v", err)
	}

	other := seedTestUser(t, db, "firebase-uid-chain-detail-other")
	encounter := orderedEncounter(user.ID, other.ID, jsonDate(t, "2026-03-01"))
	if err := db.Create(&encounter).Error; err != nil {
		t.Fatalf("create encounter: %v", err)
	}

	if err := db.Create(&model.LyricEntry{
		ID:          uuid.NewString(),
		ChainID:     chainID,
		UserID:      user.ID,
		EncounterID: encounter.ID,
		Content:     "夜明け前の静けさの中",
		SequenceNum: 1,
	}).Error; err != nil {
		t.Fatalf("create entry: %v", err)
	}

	req, _ := authRequest(http.MethodGet, "/api/v1/lyrics/chains/"+chainID, nil)
	rec := httptest.NewRecorder()
	e.ServeHTTP(rec, req)

	if rec.Code != http.StatusOK {
		t.Fatalf("expected 200, got %d: %s", rec.Code, rec.Body.String())
	}

	var body map[string]any
	if err := json.Unmarshal(rec.Body.Bytes(), &body); err != nil {
		t.Fatalf("unmarshal: %v", err)
	}

	chain := body["chain"].(map[string]any)
	if chain["id"].(string) != chainID {
		t.Fatalf("expected chain id %s, got %s", chainID, chain["id"])
	}
	if chain["status"].(string) != "pending" {
		t.Fatalf("expected status pending, got %v", chain["status"])
	}

	entries := body["entries"].([]any)
	if len(entries) != 1 {
		t.Fatalf("expected 1 entry, got %d", len(entries))
	}
	entry := entries[0].(map[string]any)
	if entry["content"].(string) != "夜明け前の静けさの中" {
		t.Fatalf("unexpected content: %v", entry["content"])
	}
}

func TestGetChainDetail_NotFound(t *testing.T) {
	db := newTestDB(t)
	seedTestUser(t, db, "firebase-uid-chain-notfound")
	e := newTestServer(t, db, "firebase-uid-chain-notfound")

	req, _ := authRequest(http.MethodGet, "/api/v1/lyrics/chains/"+uuid.NewString(), nil)
	rec := httptest.NewRecorder()
	e.ServeHTTP(rec, req)

	if rec.Code != http.StatusNotFound {
		t.Fatalf("expected 404, got %d: %s", rec.Code, rec.Body.String())
	}
}
