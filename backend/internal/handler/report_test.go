package handler

import (
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"testing"

	"github.com/google/uuid"

	"hackathon/internal/infra/rdb/model"
)

func TestCreateReport_UserReport(t *testing.T) {
	db := newTestDB(t)
	_ = seedTestUser(t, db, "firebase-uid-report-reporter-1")
	target := seedTestUser(t, db, "firebase-uid-report-target-1")
	e := newTestServer(t, db, "firebase-uid-report-reporter-1")

	req, err := authRequest(http.MethodPost, "/api/v1/reports", map[string]any{
		"reported_user_id": target.ID,
		"report_type":      "user",
		"reason":           "spam",
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
	report := body["report"].(map[string]any)
	if report["reported_user_id"].(string) != target.ID {
		t.Fatalf("expected reported_user_id %s, got %v", target.ID, report["reported_user_id"])
	}
	if report["report_type"].(string) != "user" {
		t.Fatalf("expected report_type user, got %v", report["report_type"])
	}
	if report["reason"].(string) != "spam" {
		t.Fatalf("expected reason spam, got %v", report["reason"])
	}
	if report["id"] == nil || report["id"].(string) == "" {
		t.Fatal("expected non-empty id")
	}
	if report["created_at"] == nil || report["created_at"].(string) == "" {
		t.Fatal("expected non-empty created_at")
	}
}

func TestCreateReport_CommentReport(t *testing.T) {
	db := newTestDB(t)
	reporter := seedTestUser(t, db, "firebase-uid-report-reporter-2")
	target := seedTestUser(t, db, "firebase-uid-report-target-2")

	encounter := orderedEncounter(reporter.ID, target.ID, jsonDate(t, "2026-03-01"))
	if err := db.Create(&encounter).Error; err != nil {
		t.Fatalf("create encounter: %v", err)
	}
	comment := model.Comment{
		ID:              uuid.NewString(),
		EncounterID:     encounter.ID,
		CommenterUserID: target.ID,
		Content:         "bad content",
	}
	if err := db.Create(&comment).Error; err != nil {
		t.Fatalf("create comment: %v", err)
	}

	e := newTestServer(t, db, "firebase-uid-report-reporter-2")

	req, err := authRequest(http.MethodPost, "/api/v1/reports", map[string]any{
		"reported_user_id":  target.ID,
		"report_type":       "comment",
		"target_comment_id": comment.ID,
		"reason":            "inappropriate content",
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
	report := body["report"].(map[string]any)
	if report["report_type"].(string) != "comment" {
		t.Fatalf("expected report_type comment, got %v", report["report_type"])
	}
	if report["target_comment_id"].(string) != comment.ID {
		t.Fatalf("expected target_comment_id %s, got %v", comment.ID, report["target_comment_id"])
	}
}

func TestCreateReport_DuplicateReturns409(t *testing.T) {
	db := newTestDB(t)
	_ = seedTestUser(t, db, "firebase-uid-report-dup-reporter")
	target := seedTestUser(t, db, "firebase-uid-report-dup-target")
	e := newTestServer(t, db, "firebase-uid-report-dup-reporter")

	reqBody := map[string]any{
		"reported_user_id": target.ID,
		"report_type":      "user",
		"reason":           "harassment",
	}

	req1, _ := authRequest(http.MethodPost, "/api/v1/reports", reqBody)
	rec1 := httptest.NewRecorder()
	e.ServeHTTP(rec1, req1)
	if rec1.Code != http.StatusCreated {
		t.Fatalf("expected 201 on first report, got %d: %s", rec1.Code, rec1.Body.String())
	}

	req2, _ := authRequest(http.MethodPost, "/api/v1/reports", reqBody)
	rec2 := httptest.NewRecorder()
	e.ServeHTTP(rec2, req2)
	if rec2.Code != http.StatusConflict {
		t.Fatalf("expected 409 on duplicate report, got %d: %s", rec2.Code, rec2.Body.String())
	}
}

func TestCreateReport_SelfReportReturns400(t *testing.T) {
	db := newTestDB(t)
	user := seedTestUser(t, db, "firebase-uid-report-self")
	e := newTestServer(t, db, "firebase-uid-report-self")

	req, err := authRequest(http.MethodPost, "/api/v1/reports", map[string]any{
		"reported_user_id": user.ID,
		"report_type":      "user",
		"reason":           "test",
	})
	if err != nil {
		t.Fatalf("new request: %v", err)
	}
	rec := httptest.NewRecorder()
	e.ServeHTTP(rec, req)

	if rec.Code != http.StatusBadRequest {
		t.Fatalf("expected 400 for self-report, got %d: %s", rec.Code, rec.Body.String())
	}
}

func TestCreateReport_MissingFieldsReturn400(t *testing.T) {
	db := newTestDB(t)
	seedTestUser(t, db, "firebase-uid-report-validation")
	e := newTestServer(t, db, "firebase-uid-report-validation")

	cases := []struct {
		name string
		body map[string]any
	}{
		{
			name: "missing reported_user_id",
			body: map[string]any{"report_type": "user", "reason": "spam"},
		},
		{
			name: "invalid report_type",
			body: map[string]any{"reported_user_id": uuid.NewString(), "report_type": "invalid", "reason": "spam"},
		},
		{
			name: "missing reason",
			body: map[string]any{"reported_user_id": uuid.NewString(), "report_type": "user"},
		},
		{
			name: "comment type without target_comment_id",
			body: map[string]any{"reported_user_id": uuid.NewString(), "report_type": "comment", "reason": "spam"},
		},
		{
			name: "user type with target_comment_id",
			body: map[string]any{"reported_user_id": uuid.NewString(), "report_type": "user", "target_comment_id": uuid.NewString(), "reason": "spam"},
		},
	}

	for _, tc := range cases {
		t.Run(tc.name, func(t *testing.T) {
			req, err := authRequest(http.MethodPost, "/api/v1/reports", tc.body)
			if err != nil {
				t.Fatalf("new request: %v", err)
			}
			rec := httptest.NewRecorder()
			e.ServeHTTP(rec, req)
			if rec.Code != http.StatusBadRequest {
				t.Fatalf("expected 400, got %d: %s", rec.Code, rec.Body.String())
			}
		})
	}
}

func TestCreateReport_NonExistentUserReturns404(t *testing.T) {
	db := newTestDB(t)
	seedTestUser(t, db, "firebase-uid-report-notfound")
	e := newTestServer(t, db, "firebase-uid-report-notfound")

	req, err := authRequest(http.MethodPost, "/api/v1/reports", map[string]any{
		"reported_user_id": uuid.NewString(),
		"report_type":      "user",
		"reason":           "spam",
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
