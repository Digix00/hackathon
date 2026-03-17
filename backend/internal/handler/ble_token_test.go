//go:build integration

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

// TestPostgresIntegration_BleToken は POST /ble-tokens → GET /ble-tokens/current の正常フロー
func TestPostgresIntegration_BleToken(t *testing.T) {
	db := newTestDB(t)
	user := seedTestUser(t, db, "firebase-uid-ble-1")
	_ = user

	e := newTestServer(t, db, "firebase-uid-ble-1")

	// POST /ble-tokens: 新しいトークンを発行
	createReq, err := authRequest(http.MethodPost, "/api/v1/ble-tokens", nil)
	if err != nil {
		t.Fatalf("new request: %v", err)
	}
	createRec := httptest.NewRecorder()
	e.ServeHTTP(createRec, createReq)
	if createRec.Code != http.StatusCreated {
		t.Fatalf("expected 201, got %d: %s", createRec.Code, createRec.Body.String())
	}

	var createBody map[string]any
	if err := json.Unmarshal(createRec.Body.Bytes(), &createBody); err != nil {
		t.Fatalf("unmarshal create response: %v", err)
	}
	bleToken, ok := createBody["ble_token"].(map[string]any)
	if !ok {
		t.Fatalf("expected ble_token object in response, got: %v", createBody)
	}
	tokenStr, ok := bleToken["token"].(string)
	if !ok || tokenStr == "" {
		t.Fatalf("expected non-empty token string, got: %v", bleToken["token"])
	}

	// GET /ble-tokens/current: 発行したトークンが取得できる
	getReq, err := authRequest(http.MethodGet, "/api/v1/ble-tokens/current", nil)
	if err != nil {
		t.Fatalf("new request: %v", err)
	}
	getRec := httptest.NewRecorder()
	e.ServeHTTP(getRec, getReq)
	if getRec.Code != http.StatusOK {
		t.Fatalf("expected 200, got %d: %s", getRec.Code, getRec.Body.String())
	}

	var getBody map[string]any
	if err := json.Unmarshal(getRec.Body.Bytes(), &getBody); err != nil {
		t.Fatalf("unmarshal get response: %v", err)
	}
	gotToken := getBody["ble_token"].(map[string]any)
	if gotToken["token"].(string) != tokenStr {
		t.Fatalf("expected token %q, got %q", tokenStr, gotToken["token"])
	}
}

// TestPostgresIntegration_BleToken_GetCurrentReturns404WhenNoToken は有効なトークンが存在しない場合 404 を返す
func TestPostgresIntegration_BleToken_GetCurrentReturns404WhenNoToken(t *testing.T) {
	db := newTestDB(t)
	seedTestUser(t, db, "firebase-uid-ble-2")

	e := newTestServer(t, db, "firebase-uid-ble-2")

	req, err := authRequest(http.MethodGet, "/api/v1/ble-tokens/current", nil)
	if err != nil {
		t.Fatalf("new request: %v", err)
	}
	rec := httptest.NewRecorder()
	e.ServeHTTP(rec, req)
	if rec.Code != http.StatusNotFound {
		t.Fatalf("expected 404, got %d: %s", rec.Code, rec.Body.String())
	}
}

// TestPostgresIntegration_BleToken_GetUserByToken はBLEトークンから相手のプロフィールが取得できる
func TestPostgresIntegration_BleToken_GetUserByToken(t *testing.T) {
	db := newTestDB(t)
	requester := seedTestUser(t, db, "firebase-uid-ble-requester")
	target := seedTestUser(t, db, "firebase-uid-ble-target")

	// target ユーザーのBLEトークンをDBに直接挿入
	now := time.Now().UTC()
	bleToken := model.BleToken{
		ID:        uuid.NewString(),
		UserID:    target.ID,
		Token:     uuid.NewString(),
		ValidFrom: now.Add(-1 * time.Hour),
		ValidTo:   now.Add(23 * time.Hour), // 有効期限内
	}
	if err := db.Create(&bleToken).Error; err != nil {
		t.Fatalf("create ble token: %v", err)
	}

	e := newTestServer(t, db, "firebase-uid-ble-requester")
	_ = requester

	req, err := authRequest(http.MethodGet, "/api/v1/ble-tokens/"+bleToken.Token+"/user", nil)
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
	user, ok := body["user"].(map[string]any)
	if !ok {
		t.Fatalf("expected user object, got: %v", body)
	}
	if user["id"].(string) != target.ID {
		t.Fatalf("expected target user id %q, got %q", target.ID, user["id"])
	}
}

// TestPostgresIntegration_BleToken_GetUserByExpiredToken は有効期限切れのトークンの場合 404 を返す
func TestPostgresIntegration_BleToken_GetUserByExpiredToken(t *testing.T) {
	db := newTestDB(t)
	requester := seedTestUser(t, db, "firebase-uid-ble-req-expired")
	target := seedTestUser(t, db, "firebase-uid-ble-target-expired")
	_ = requester

	// 有効期限切れのBLEトークンをDBに直接挿入
	now := time.Now().UTC()
	expiredToken := model.BleToken{
		ID:        uuid.NewString(),
		UserID:    target.ID,
		Token:     uuid.NewString(),
		ValidFrom: now.Add(-25 * time.Hour),
		ValidTo:   now.Add(-1 * time.Hour), // 有効期限切れ
	}
	if err := db.Create(&expiredToken).Error; err != nil {
		t.Fatalf("create expired ble token: %v", err)
	}

	e := newTestServer(t, db, "firebase-uid-ble-req-expired")

	req, err := authRequest(http.MethodGet, "/api/v1/ble-tokens/"+expiredToken.Token+"/user", nil)
	if err != nil {
		t.Fatalf("new request: %v", err)
	}
	rec := httptest.NewRecorder()
	e.ServeHTTP(rec, req)
	if rec.Code != http.StatusNotFound {
		t.Fatalf("expected 404 for expired token, got %d: %s", rec.Code, rec.Body.String())
	}
}

// TestPostgresIntegration_BleToken_GetUserByTokenReturns404WhenBlocked はブロック状態の場合 404 を返す
func TestPostgresIntegration_BleToken_GetUserByTokenReturns404WhenBlocked(t *testing.T) {
	db := newTestDB(t)
	requester := seedTestUser(t, db, "firebase-uid-ble-blocker")
	target := seedTestUser(t, db, "firebase-uid-ble-blocked")

	// requester が target をブロック
	if err := db.Create(&model.Block{
		ID:            uuid.NewString(),
		BlockerUserID: requester.ID,
		BlockedUserID: target.ID,
	}).Error; err != nil {
		t.Fatalf("create block: %v", err)
	}

	now := time.Now().UTC()
	bleToken := model.BleToken{
		ID:        uuid.NewString(),
		UserID:    target.ID,
		Token:     uuid.NewString(),
		ValidFrom: now.Add(-1 * time.Hour),
		ValidTo:   now.Add(23 * time.Hour),
	}
	if err := db.Create(&bleToken).Error; err != nil {
		t.Fatalf("create ble token: %v", err)
	}

	e := newTestServer(t, db, "firebase-uid-ble-blocker")

	req, err := authRequest(http.MethodGet, "/api/v1/ble-tokens/"+bleToken.Token+"/user", nil)
	if err != nil {
		t.Fatalf("new request: %v", err)
	}
	rec := httptest.NewRecorder()
	e.ServeHTTP(rec, req)
	if rec.Code != http.StatusNotFound {
		t.Fatalf("expected 404 when blocked, got %d: %s", rec.Code, rec.Body.String())
	}
}

// TestPostgresIntegration_BleToken_GetUserByNonExistentToken は存在しないトークンの場合 404 を返す
func TestPostgresIntegration_BleToken_GetUserByNonExistentToken(t *testing.T) {
	db := newTestDB(t)
	seedTestUser(t, db, "firebase-uid-ble-notfound")

	e := newTestServer(t, db, "firebase-uid-ble-notfound")

	req, err := authRequest(http.MethodGet, "/api/v1/ble-tokens/no-such-token/user", nil)
	if err != nil {
		t.Fatalf("new request: %v", err)
	}
	rec := httptest.NewRecorder()
	e.ServeHTTP(rec, req)
	if rec.Code != http.StatusNotFound {
		t.Fatalf("expected 404 when token not found, got %d: %s", rec.Code, rec.Body.String())
	}
}
