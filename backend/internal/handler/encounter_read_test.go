package handler

import (
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"testing"
	"time"

	"hackathon/internal/infra/rdb/model"
)

func TestMarkEncounterAsRead_Returns200WithReadAt(t *testing.T) {
	db := newTestDB(t)
	requester := seedTestUser(t, db, "firebase-uid-enc-read-req")
	other := seedTestUser(t, db, "firebase-uid-enc-read-other")

	enc := orderedEncounter(requester.ID, other.ID, time.Now().UTC())
	if err := db.Create(&enc).Error; err != nil {
		t.Fatalf("create encounter: %v", err)
	}

	e := newTestServer(t, db, "firebase-uid-enc-read-req")
	req, err := authRequest(http.MethodPatch, "/api/v1/encounters/"+enc.ID+"/read", nil)
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
	encounter := body["encounter"].(map[string]any)
	if encounter["id"].(string) != enc.ID {
		t.Fatalf("expected encounter id %s, got %s", enc.ID, encounter["id"].(string))
	}
	if encounter["is_read"].(bool) != true {
		t.Fatalf("expected is_read true")
	}
	if encounter["read_at"].(string) == "" {
		t.Fatalf("expected non-empty read_at")
	}

	var count int64
	if err := db.Model(&model.EncounterRead{}).
		Where("encounter_id = ? AND user_id = ?", enc.ID, requester.ID).
		Count(&count).Error; err != nil {
		t.Fatalf("count encounter reads: %v", err)
	}
	if count != 1 {
		t.Fatalf("expected 1 encounter_read record, got %d", count)
	}
}

func TestMarkEncounterAsRead_IsIdempotent(t *testing.T) {
	db := newTestDB(t)
	requester := seedTestUser(t, db, "firebase-uid-enc-read-idem-req")
	other := seedTestUser(t, db, "firebase-uid-enc-read-idem-other")

	enc := orderedEncounter(requester.ID, other.ID, time.Now().UTC())
	if err := db.Create(&enc).Error; err != nil {
		t.Fatalf("create encounter: %v", err)
	}

	e := newTestServer(t, db, "firebase-uid-enc-read-idem-req")

	firstReq, _ := authRequest(http.MethodPatch, "/api/v1/encounters/"+enc.ID+"/read", nil)
	firstRec := httptest.NewRecorder()
	e.ServeHTTP(firstRec, firstReq)
	if firstRec.Code != http.StatusOK {
		t.Fatalf("first request: expected 200, got %d: %s", firstRec.Code, firstRec.Body.String())
	}

	var firstBody map[string]any
	if err := json.Unmarshal(firstRec.Body.Bytes(), &firstBody); err != nil {
		t.Fatalf("unmarshal first response: %v", err)
	}
	firstReadAt := firstBody["encounter"].(map[string]any)["read_at"].(string)

	secondReq, _ := authRequest(http.MethodPatch, "/api/v1/encounters/"+enc.ID+"/read", nil)
	secondRec := httptest.NewRecorder()
	e.ServeHTTP(secondRec, secondReq)
	if secondRec.Code != http.StatusOK {
		t.Fatalf("second request: expected 200, got %d: %s", secondRec.Code, secondRec.Body.String())
	}

	var secondBody map[string]any
	if err := json.Unmarshal(secondRec.Body.Bytes(), &secondBody); err != nil {
		t.Fatalf("unmarshal second response: %v", err)
	}
	secondReadAt := secondBody["encounter"].(map[string]any)["read_at"].(string)

	if firstReadAt != secondReadAt {
		t.Fatalf("expected same read_at for idempotent call: first=%s, second=%s", firstReadAt, secondReadAt)
	}

	var count int64
	if err := db.Model(&model.EncounterRead{}).
		Where("encounter_id = ? AND user_id = ?", enc.ID, requester.ID).
		Count(&count).Error; err != nil {
		t.Fatalf("count encounter reads: %v", err)
	}
	if count != 1 {
		t.Fatalf("expected exactly 1 encounter_read record after idempotent call, got %d", count)
	}
}

func TestMarkEncounterAsRead_Returns404ForNonParticipant(t *testing.T) {
	db := newTestDB(t)
	user1 := seedTestUser(t, db, "firebase-uid-enc-read-404-u1")
	user2 := seedTestUser(t, db, "firebase-uid-enc-read-404-u2")
	seedTestUser(t, db, "firebase-uid-enc-read-404-outsider")

	enc := orderedEncounter(user1.ID, user2.ID, time.Now().UTC())
	if err := db.Create(&enc).Error; err != nil {
		t.Fatalf("create encounter: %v", err)
	}

	e := newTestServer(t, db, "firebase-uid-enc-read-404-outsider")
	req, err := authRequest(http.MethodPatch, "/api/v1/encounters/"+enc.ID+"/read", nil)
	if err != nil {
		t.Fatalf("new request: %v", err)
	}
	rec := httptest.NewRecorder()
	e.ServeHTTP(rec, req)

	if rec.Code != http.StatusNotFound {
		t.Fatalf("expected 404, got %d: %s", rec.Code, rec.Body.String())
	}
}

func TestMarkEncounterAsRead_Returns404ForUnknownEncounter(t *testing.T) {
	db := newTestDB(t)
	seedTestUser(t, db, "firebase-uid-enc-read-unknown")

	e := newTestServer(t, db, "firebase-uid-enc-read-unknown")
	req, err := authRequest(http.MethodPatch, "/api/v1/encounters/00000000-0000-0000-0000-000000000000/read", nil)
	if err != nil {
		t.Fatalf("new request: %v", err)
	}
	rec := httptest.NewRecorder()
	e.ServeHTTP(rec, req)

	if rec.Code != http.StatusNotFound {
		t.Fatalf("expected 404, got %d: %s", rec.Code, rec.Body.String())
	}
}
