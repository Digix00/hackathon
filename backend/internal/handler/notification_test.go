package handler

import (
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"testing"

	"github.com/google/uuid"

	"hackathon/internal/infra/rdb/model"
)

func TestListNotificationsReturnsEmptyForNewUser(t *testing.T) {
	db := newTestDB(t)
	seedTestUser(t, db, "firebase-notif-uid-1")
	e := newTestServer(t, db, "firebase-notif-uid-1")

	req, err := authRequest(http.MethodGet, "/api/v1/users/me/notifications", nil)
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
	if body["total"].(float64) != 0 {
		t.Fatalf("expected total 0, got %v", body["total"])
	}
	if body["unread_count"].(float64) != 0 {
		t.Fatalf("expected unread_count 0, got %v", body["unread_count"])
	}
	notifications := body["notifications"].([]any)
	if len(notifications) != 0 {
		t.Fatalf("expected empty notifications, got %d items", len(notifications))
	}
}

func TestListNotificationsReturnsSentNotifications(t *testing.T) {
	db := newTestDB(t)
	user := seedTestUser(t, db, "firebase-notif-uid-2")
	other := seedTestUser(t, db, "firebase-notif-uid-2-other")
	encounter := orderedEncounter(user.ID, other.ID, jsonDate(t, "2026-03-18"))
	if err := db.Create(&encounter).Error; err != nil {
		t.Fatalf("create encounter: %v", err)
	}

	notif := model.OutboxNotification{
		ID:          uuid.NewString(),
		UserID:      user.ID,
		EncounterID: encounter.ID,
		Status:      "sent",
	}
	if err := db.Create(&notif).Error; err != nil {
		t.Fatalf("create notification: %v", err)
	}

	e := newTestServer(t, db, "firebase-notif-uid-2")
	req, err := authRequest(http.MethodGet, "/api/v1/users/me/notifications", nil)
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
	if body["total"].(float64) != 1 {
		t.Fatalf("expected total 1, got %v", body["total"])
	}
	if body["unread_count"].(float64) != 1 {
		t.Fatalf("expected unread_count 1, got %v", body["unread_count"])
	}
	notifications := body["notifications"].([]any)
	if len(notifications) != 1 {
		t.Fatalf("expected 1 notification, got %d", len(notifications))
	}
	item := notifications[0].(map[string]any)
	if item["id"].(string) != notif.ID {
		t.Fatalf("expected notification id %s, got %s", notif.ID, item["id"])
	}
	if item["read_at"] != nil {
		t.Fatalf("expected read_at to be nil, got %v", item["read_at"])
	}
}

func TestMarkNotificationAsRead(t *testing.T) {
	db := newTestDB(t)
	user := seedTestUser(t, db, "firebase-notif-uid-3")
	other := seedTestUser(t, db, "firebase-notif-uid-3-other")
	encounter := orderedEncounter(user.ID, other.ID, jsonDate(t, "2026-03-18"))
	if err := db.Create(&encounter).Error; err != nil {
		t.Fatalf("create encounter: %v", err)
	}

	notif := model.OutboxNotification{
		ID:          uuid.NewString(),
		UserID:      user.ID,
		EncounterID: encounter.ID,
		Status:      "sent",
	}
	if err := db.Create(&notif).Error; err != nil {
		t.Fatalf("create notification: %v", err)
	}

	e := newTestServer(t, db, "firebase-notif-uid-3")
	req, err := authRequest(http.MethodPatch, "/api/v1/users/me/notifications/"+notif.ID+"/read", nil)
	if err != nil {
		t.Fatalf("new request: %v", err)
	}
	rec := httptest.NewRecorder()
	e.ServeHTTP(rec, req)

	if rec.Code != http.StatusNoContent {
		t.Fatalf("expected 204, got %d: %s", rec.Code, rec.Body.String())
	}

	var updated model.OutboxNotification
	if err := db.First(&updated, "id = ?", notif.ID).Error; err != nil {
		t.Fatalf("reload notification: %v", err)
	}
	if updated.ReadAt == nil {
		t.Fatalf("expected read_at to be set after marking as read")
	}

	listReq, _ := authRequest(http.MethodGet, "/api/v1/users/me/notifications", nil)
	listRec := httptest.NewRecorder()
	e.ServeHTTP(listRec, listReq)
	var listBody map[string]any
	if err := json.Unmarshal(listRec.Body.Bytes(), &listBody); err != nil {
		t.Fatalf("unmarshal list response: %v", err)
	}
	if listBody["unread_count"].(float64) != 0 {
		t.Fatalf("expected unread_count 0 after marking read, got %v", listBody["unread_count"])
	}
}

func TestMarkNotificationAsReadReturns404ForOtherUser(t *testing.T) {
	db := newTestDB(t)
	owner := seedTestUser(t, db, "firebase-notif-uid-4-owner")
	other := seedTestUser(t, db, "firebase-notif-uid-4-other")
	encounter := orderedEncounter(owner.ID, other.ID, jsonDate(t, "2026-03-18"))
	if err := db.Create(&encounter).Error; err != nil {
		t.Fatalf("create encounter: %v", err)
	}

	notif := model.OutboxNotification{
		ID:          uuid.NewString(),
		UserID:      owner.ID,
		EncounterID: encounter.ID,
		Status:      "sent",
	}
	if err := db.Create(&notif).Error; err != nil {
		t.Fatalf("create notification: %v", err)
	}

	e := newTestServer(t, db, "firebase-notif-uid-4-other")
	req, err := authRequest(http.MethodPatch, "/api/v1/users/me/notifications/"+notif.ID+"/read", nil)
	if err != nil {
		t.Fatalf("new request: %v", err)
	}
	rec := httptest.NewRecorder()
	e.ServeHTTP(rec, req)

	if rec.Code != http.StatusNotFound {
		t.Fatalf("expected 404, got %d: %s", rec.Code, rec.Body.String())
	}
}

func TestDeleteNotification(t *testing.T) {
	db := newTestDB(t)
	user := seedTestUser(t, db, "firebase-notif-uid-5")
	other := seedTestUser(t, db, "firebase-notif-uid-5-other")
	encounter := orderedEncounter(user.ID, other.ID, jsonDate(t, "2026-03-18"))
	if err := db.Create(&encounter).Error; err != nil {
		t.Fatalf("create encounter: %v", err)
	}

	notif := model.OutboxNotification{
		ID:          uuid.NewString(),
		UserID:      user.ID,
		EncounterID: encounter.ID,
		Status:      "sent",
	}
	if err := db.Create(&notif).Error; err != nil {
		t.Fatalf("create notification: %v", err)
	}

	e := newTestServer(t, db, "firebase-notif-uid-5")
	req, err := authRequest(http.MethodDelete, "/api/v1/users/me/notifications/"+notif.ID, nil)
	if err != nil {
		t.Fatalf("new request: %v", err)
	}
	rec := httptest.NewRecorder()
	e.ServeHTTP(rec, req)

	if rec.Code != http.StatusNoContent {
		t.Fatalf("expected 204, got %d: %s", rec.Code, rec.Body.String())
	}

	var count int64
	if err := db.Model(&model.OutboxNotification{}).Where("id = ?", notif.ID).Count(&count).Error; err != nil {
		t.Fatalf("count notification: %v", err)
	}
	if count != 0 {
		t.Fatalf("expected notification to be deleted, still exists")
	}
}

func TestDeleteNotificationReturns404ForOtherUser(t *testing.T) {
	db := newTestDB(t)
	owner := seedTestUser(t, db, "firebase-notif-uid-6-owner")
	other := seedTestUser(t, db, "firebase-notif-uid-6-other")
	encounter := orderedEncounter(owner.ID, other.ID, jsonDate(t, "2026-03-18"))
	if err := db.Create(&encounter).Error; err != nil {
		t.Fatalf("create encounter: %v", err)
	}

	notif := model.OutboxNotification{
		ID:          uuid.NewString(),
		UserID:      owner.ID,
		EncounterID: encounter.ID,
		Status:      "sent",
	}
	if err := db.Create(&notif).Error; err != nil {
		t.Fatalf("create notification: %v", err)
	}

	e := newTestServer(t, db, "firebase-notif-uid-6-other")
	req, err := authRequest(http.MethodDelete, "/api/v1/users/me/notifications/"+notif.ID, nil)
	if err != nil {
		t.Fatalf("new request: %v", err)
	}
	rec := httptest.NewRecorder()
	e.ServeHTTP(rec, req)

	if rec.Code != http.StatusNotFound {
		t.Fatalf("expected 404, got %d: %s", rec.Code, rec.Body.String())
	}
}
