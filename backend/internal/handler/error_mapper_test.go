package handler

import (
	"encoding/json"
	"errors"
	"net/http"
	"net/http/httptest"
	"testing"

	"github.com/labstack/echo/v4"
	"go.uber.org/zap"

	domainerrs "hackathon/internal/domain/errs"
)

func TestMapErrorFromDomainError(t *testing.T) {
	status, body := mapError(domainerrs.BadRequest("invalid input"))
	if status != http.StatusBadRequest {
		t.Fatalf("expected 400, got %d", status)
	}
	if body.Code != "BAD_REQUEST" || body.Message != "invalid input" {
		t.Fatalf("unexpected body: %+v", body)
	}
}

func TestMapErrorFromHTTPErrorWithExplicitBody(t *testing.T) {
	status, body := mapError(echo.NewHTTPError(http.StatusConflict, map[string]any{
		"code":    "CONFLICT",
		"message": "already exists",
		"details": map[string]any{"field": "display_name"},
	}))
	if status != http.StatusConflict {
		t.Fatalf("expected 409, got %d", status)
	}
	if body.Code != "CONFLICT" || body.Message != "already exists" {
		t.Fatalf("unexpected body: %+v", body)
	}
	if body.Details == nil {
		t.Fatal("expected details to be preserved")
	}
}

func TestInstallHTTPErrorHandlerWritesUnifiedJSON(t *testing.T) {
	e := echo.New()
	InstallHTTPErrorHandler(e, zap.NewNop())

	req := httptest.NewRequest(http.MethodGet, "/", nil)
	rec := httptest.NewRecorder()
	c := e.NewContext(req, rec)

	e.HTTPErrorHandler(errors.New("boom"), c)

	if rec.Code != http.StatusInternalServerError {
		t.Fatalf("expected 500, got %d", rec.Code)
	}

	var body map[string]map[string]any
	if err := json.Unmarshal(rec.Body.Bytes(), &body); err != nil {
		t.Fatalf("unmarshal response: %v", err)
	}
	if body["error"]["code"] != "INTERNAL" {
		t.Fatalf("expected INTERNAL code, got %v", body["error"]["code"])
	}
}
