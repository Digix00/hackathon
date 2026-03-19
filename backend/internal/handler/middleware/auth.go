package middleware

import (
	"context"
	"net/http"
	"strings"

	firebaseauth "firebase.google.com/go/v4/auth"
	"github.com/labstack/echo/v4"
)

const ContextKeyUserID = "user_id"

type TokenVerifier interface {
	VerifyIDToken(ctx context.Context, idToken string) (*firebaseauth.Token, error)
}

type DevAuthConfig struct {
	Enabled bool
	Token   string
	UID     string
}

func FirebaseAuth(verifier TokenVerifier, devAuth DevAuthConfig) echo.MiddlewareFunc {
	return func(next echo.HandlerFunc) echo.HandlerFunc {
		return func(c echo.Context) error {
			token, err := extractBearerToken(c.Request().Header.Get(echo.HeaderAuthorization))
			if err != nil {
				return echo.NewHTTPError(http.StatusUnauthorized, map[string]any{
					"code":    "UNAUTHORIZED",
					"message": "Authorization header must be Bearer token",
					"details": nil,
				})
			}

			if devAuth.Enabled && devAuth.Token != "" && token == devAuth.Token {
				uid := devAuth.UID
				if uid == "" {
					uid = "dev-user"
				}
				c.Set(ContextKeyUserID, uid)
				return next(c)
			}

			decoded, err := verifier.VerifyIDToken(c.Request().Context(), token)
			if err != nil {
				return echo.NewHTTPError(http.StatusUnauthorized, map[string]any{
					"code":    "UNAUTHORIZED",
					"message": "Invalid Firebase ID token",
					"details": nil,
				})
			}

			c.Set(ContextKeyUserID, decoded.UID)
			return next(c)
		}
	}
}

func UserIDFromContext(c echo.Context) (string, bool) {
	value := c.Get(ContextKeyUserID)
	userID, ok := value.(string)
	if !ok || userID == "" {
		return "", false
	}
	return userID, true
}

func extractBearerToken(headerValue string) (string, error) {
	parts := strings.SplitN(strings.TrimSpace(headerValue), " ", 2)
	if len(parts) != 2 {
		return "", echo.NewHTTPError(http.StatusUnauthorized)
	}
	if !strings.EqualFold(parts[0], "Bearer") || strings.TrimSpace(parts[1]) == "" {
		return "", echo.NewHTTPError(http.StatusUnauthorized)
	}
	return strings.TrimSpace(parts[1]), nil
}
