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

func TestPostLocationReturnsEmptyWhenNoNearbyUsers(t *testing.T) {
	db := newTestDB(t)
	seedTestUser(t, db, "firebase-uid-loc-empty")
	e := newTestServer(t, db, "firebase-uid-loc-empty")

	req, err := authRequest(http.MethodPost, "/api/v1/locations", map[string]any{
		"lat":         35.6812,
		"lng":         139.7671,
		"accuracy_m":  20.0,
		"recorded_at": time.Now().UTC().Format(time.RFC3339),
	})
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
	if body["encounter_count"].(float64) != 0 {
		t.Fatalf("expected 0 encounters, got %v", body["encounter_count"])
	}
	encounters := body["encounters"].([]any)
	if len(encounters) != 0 {
		t.Fatalf("expected empty encounters, got %d", len(encounters))
	}
}

func TestPostLocationCreatesEncounterForNearbyUser(t *testing.T) {
	db := newTestDB(t)
	requester := seedTestUser(t, db, "firebase-uid-loc-near-req")
	other := seedTestUser(t, db, "firebase-uid-loc-near-other")

	// other ユーザーの位置を事前に登録（ほぼ同じ座標）
	now := time.Now().UTC()
	if err := db.Create(&model.UserLocation{
		ID:        uuid.NewString(),
		UserID:    other.ID,
		Latitude:  35.6813,
		Longitude: 139.7672,
		UpdatedAt: now,
	}).Error; err != nil {
		t.Fatalf("create other user location: %v", err)
	}

	e := newTestServer(t, db, "firebase-uid-loc-near-req")

	req, err := authRequest(http.MethodPost, "/api/v1/locations", map[string]any{
		"lat":         35.6812,
		"lng":         139.7671,
		"accuracy_m":  20.0,
		"recorded_at": now.Format(time.RFC3339),
	})
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
	if body["encounter_count"].(float64) != 1 {
		t.Fatalf("expected 1 encounter, got %v", body["encounter_count"])
	}
	encounters := body["encounters"].([]any)
	if len(encounters) != 1 {
		t.Fatalf("expected 1 encounter in list, got %d", len(encounters))
	}
	enc := encounters[0].(map[string]any)
	if enc["type"].(string) != "location" {
		t.Fatalf("expected type location, got %v", enc["type"])
	}
	user := enc["user"].(map[string]any)
	if user["id"].(string) != other.ID {
		t.Fatalf("expected other user ID %s, got %v", other.ID, user["id"])
	}

	// DB にエンカウントレコードが作成されていることを確認
	var count int64
	if err := db.Model(&model.Encounter{}).
		Where("(user_id1 = ? OR user_id2 = ?) AND encounter_type = 'location'", requester.ID, requester.ID).
		Count(&count).Error; err != nil {
		t.Fatalf("count encounters: %v", err)
	}
	if count != 1 {
		t.Fatalf("expected 1 location encounter in DB, got %d", count)
	}
}

func TestPostLocationSkipsOutOfRangeUser(t *testing.T) {
	db := newTestDB(t)
	_ = seedTestUser(t, db, "firebase-uid-loc-far-req")
	other := seedTestUser(t, db, "firebase-uid-loc-far-other")

	now := time.Now().UTC()
	// 大阪付近（東京から約500km離れた位置）
	if err := db.Create(&model.UserLocation{
		ID:        uuid.NewString(),
		UserID:    other.ID,
		Latitude:  34.6937,
		Longitude: 135.5023,
		UpdatedAt: now,
	}).Error; err != nil {
		t.Fatalf("create other user location: %v", err)
	}

	e := newTestServer(t, db, "firebase-uid-loc-far-req")

	req, err := authRequest(http.MethodPost, "/api/v1/locations", map[string]any{
		"lat":         35.6812,
		"lng":         139.7671,
		"accuracy_m":  20.0,
		"recorded_at": now.Format(time.RFC3339),
	})
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
	if body["encounter_count"].(float64) != 0 {
		t.Fatalf("expected 0 encounters, got %v", body["encounter_count"])
	}
}

func TestPostLocationSkipsBlockedUser(t *testing.T) {
	db := newTestDB(t)
	requester := seedTestUser(t, db, "firebase-uid-loc-block-req")
	other := seedTestUser(t, db, "firebase-uid-loc-block-other")

	now := time.Now().UTC()
	if err := db.Create(&model.UserLocation{
		ID:        uuid.NewString(),
		UserID:    other.ID,
		Latitude:  35.6813,
		Longitude: 139.7672,
		UpdatedAt: now,
	}).Error; err != nil {
		t.Fatalf("create other user location: %v", err)
	}

	// requester が other をブロック
	if err := db.Create(&model.Block{
		ID:            uuid.NewString(),
		BlockerUserID: requester.ID,
		BlockedUserID: other.ID,
	}).Error; err != nil {
		t.Fatalf("create block: %v", err)
	}

	e := newTestServer(t, db, "firebase-uid-loc-block-req")

	req, err := authRequest(http.MethodPost, "/api/v1/locations", map[string]any{
		"lat":         35.6812,
		"lng":         139.7671,
		"accuracy_m":  20.0,
		"recorded_at": now.Format(time.RFC3339),
	})
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
	if body["encounter_count"].(float64) != 0 {
		t.Fatalf("expected 0 encounters (blocked), got %v", body["encounter_count"])
	}
}

func TestPostLocationDeduplicatesWithin5Minutes(t *testing.T) {
	db := newTestDB(t)
	requester := seedTestUser(t, db, "firebase-uid-loc-dedup-req")
	other := seedTestUser(t, db, "firebase-uid-loc-dedup-other")

	now := time.Now().UTC()
	if err := db.Create(&model.UserLocation{
		ID:        uuid.NewString(),
		UserID:    other.ID,
		Latitude:  35.6813,
		Longitude: 139.7672,
		UpdatedAt: now,
	}).Error; err != nil {
		t.Fatalf("create other user location: %v", err)
	}

	e := newTestServer(t, db, "firebase-uid-loc-dedup-req")

	payload := map[string]any{
		"lat":         35.6812,
		"lng":         139.7671,
		"accuracy_m":  20.0,
		"recorded_at": now.Format(time.RFC3339),
	}

	// 1回目: エンカウント作成
	firstReq, _ := authRequest(http.MethodPost, "/api/v1/locations", payload)
	firstRec := httptest.NewRecorder()
	e.ServeHTTP(firstRec, firstReq)
	if firstRec.Code != http.StatusOK {
		t.Fatalf("expected 200, got %d: %s", firstRec.Code, firstRec.Body.String())
	}
	var firstBody map[string]any
	if err := json.Unmarshal(firstRec.Body.Bytes(), &firstBody); err != nil {
		t.Fatalf("unmarshal: %v", err)
	}
	if firstBody["encounter_count"].(float64) != 1 {
		t.Fatalf("expected 1 encounter on first call, got %v", firstBody["encounter_count"])
	}

	// 2回目: 5分以内の重複なのでスキップ
	secondReq, _ := authRequest(http.MethodPost, "/api/v1/locations", payload)
	secondRec := httptest.NewRecorder()
	e.ServeHTTP(secondRec, secondReq)
	if secondRec.Code != http.StatusOK {
		t.Fatalf("expected 200, got %d: %s", secondRec.Code, secondRec.Body.String())
	}
	var secondBody map[string]any
	if err := json.Unmarshal(secondRec.Body.Bytes(), &secondBody); err != nil {
		t.Fatalf("unmarshal: %v", err)
	}
	if secondBody["encounter_count"].(float64) != 0 {
		t.Fatalf("expected 0 encounters on second call (dedup), got %v", secondBody["encounter_count"])
	}

	// DBに1件だけエンカウントが存在することを確認
	var count int64
	if err := db.Model(&model.Encounter{}).
		Where("(user_id1 = ? OR user_id2 = ?) AND encounter_type = 'location'", requester.ID, requester.ID).
		Count(&count).Error; err != nil {
		t.Fatalf("count encounters: %v", err)
	}
	if count != 1 {
		t.Fatalf("expected exactly 1 encounter in DB, got %d", count)
	}
}

func TestPostLocationRequiresRecordedAt(t *testing.T) {
	db := newTestDB(t)
	seedTestUser(t, db, "firebase-uid-loc-validation")
	e := newTestServer(t, db, "firebase-uid-loc-validation")

	req, err := authRequest(http.MethodPost, "/api/v1/locations", map[string]any{
		"lat":        35.6812,
		"lng":        139.7671,
		"accuracy_m": 20.0,
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

func TestPostLocationRequiresLat(t *testing.T) {
	db := newTestDB(t)
	seedTestUser(t, db, "firebase-uid-loc-no-lat")
	e := newTestServer(t, db, "firebase-uid-loc-no-lat")

	req, err := authRequest(http.MethodPost, "/api/v1/locations", map[string]any{
		"lng":         139.7671,
		"accuracy_m":  20.0,
		"recorded_at": time.Now().UTC().Format(time.RFC3339),
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

func TestPostLocationRequiresLng(t *testing.T) {
	db := newTestDB(t)
	seedTestUser(t, db, "firebase-uid-loc-no-lng")
	e := newTestServer(t, db, "firebase-uid-loc-no-lng")

	req, err := authRequest(http.MethodPost, "/api/v1/locations", map[string]any{
		"lat":         35.6812,
		"accuracy_m":  20.0,
		"recorded_at": time.Now().UTC().Format(time.RFC3339),
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

func TestPostLocationUpdatesExistingLocation(t *testing.T) {
	db := newTestDB(t)
	requester := seedTestUser(t, db, "firebase-uid-loc-upsert")
	now := time.Now().UTC()

	// 初期位置を登録
	if err := db.Create(&model.UserLocation{
		ID:        uuid.NewString(),
		UserID:    requester.ID,
		Latitude:  35.0,
		Longitude: 139.0,
		UpdatedAt: now.Add(-time.Minute),
	}).Error; err != nil {
		t.Fatalf("create initial location: %v", err)
	}

	e := newTestServer(t, db, "firebase-uid-loc-upsert")

	req, err := authRequest(http.MethodPost, "/api/v1/locations", map[string]any{
		"lat":         35.6812,
		"lng":         139.7671,
		"accuracy_m":  20.0,
		"recorded_at": now.Format(time.RFC3339),
	})
	if err != nil {
		t.Fatalf("new request: %v", err)
	}
	rec := httptest.NewRecorder()
	e.ServeHTTP(rec, req)

	if rec.Code != http.StatusOK {
		t.Fatalf("expected 200, got %d: %s", rec.Code, rec.Body.String())
	}

	// DB に user_locations が 1 件だけ（upsert済み）
	var count int64
	if err := db.Model(&model.UserLocation{}).Where("user_id = ?", requester.ID).Count(&count).Error; err != nil {
		t.Fatalf("count user_locations: %v", err)
	}
	if count != 1 {
		t.Fatalf("expected 1 user_location after upsert, got %d", count)
	}

	// 位置が更新されていることを確認
	var loc model.UserLocation
	if err := db.Where("user_id = ?", requester.ID).First(&loc).Error; err != nil {
		t.Fatalf("get user_location: %v", err)
	}
	if loc.Latitude != 35.6812 {
		t.Fatalf("expected updated lat 35.6812, got %v", loc.Latitude)
	}
}
