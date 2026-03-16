package middleware

import (
	"context"
	"errors"
	"net/http"
	"net/http/httptest"
	"testing"

	firebaseauth "firebase.google.com/go/v4/auth"
	"github.com/labstack/echo/v4"
)

type fakeVerifier struct {
	token *firebaseauth.Token
	err   error
}

func (f fakeVerifier) VerifyIDToken(ctx context.Context, idToken string) (*firebaseauth.Token, error) {
	if f.err != nil {
		return nil, f.err
	}
	return f.token, nil
}

func TestFirebaseAuthRejectsMissingBearerToken(t *testing.T) {
	e := echo.New()
	req := httptest.NewRequest(http.MethodGet, "/", nil)
	rec := httptest.NewRecorder()
	c := e.NewContext(req, rec)

	h := FirebaseAuth(fakeVerifier{token: &firebaseauth.Token{UID: "u1"}})(func(c echo.Context) error {
		return c.NoContent(http.StatusOK)
	})

	err := h(c)
	if err == nil {
		t.Fatal("expected error")
	}

	httpErr, ok := err.(*echo.HTTPError)
	if !ok || httpErr.Code != http.StatusUnauthorized {
		t.Fatalf("expected 401 http error, got %#v", err)
	}
}

func TestFirebaseAuthSetsUserIDOnSuccess(t *testing.T) {
	e := echo.New()
	req := httptest.NewRequest(http.MethodGet, "/", nil)
	req.Header.Set(echo.HeaderAuthorization, "Bearer token")
	rec := httptest.NewRecorder()
	c := e.NewContext(req, rec)

	h := FirebaseAuth(fakeVerifier{token: &firebaseauth.Token{UID: "u1"}})(func(c echo.Context) error {
		uid, ok := UserIDFromContext(c)
		if !ok || uid != "u1" {
			t.Fatalf("expected uid u1, got %q, ok=%v", uid, ok)
		}
		return c.NoContent(http.StatusOK)
	})

	if err := h(c); err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
}

func TestFirebaseAuthRejectsInvalidToken(t *testing.T) {
	e := echo.New()
	req := httptest.NewRequest(http.MethodGet, "/", nil)
	req.Header.Set(echo.HeaderAuthorization, "Bearer token")
	rec := httptest.NewRecorder()
	c := e.NewContext(req, rec)

	h := FirebaseAuth(fakeVerifier{err: errors.New("invalid")})(func(c echo.Context) error {
		return c.NoContent(http.StatusOK)
	})

	err := h(c)
	if err == nil {
		t.Fatal("expected error")
	}

	httpErr, ok := err.(*echo.HTTPError)
	if !ok || httpErr.Code != http.StatusUnauthorized {
		t.Fatalf("expected 401 http error, got %#v", err)
	}
}
