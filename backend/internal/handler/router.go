package handler

import (
	"net/http"

	"github.com/labstack/echo/v4"
	"gorm.io/gorm"

	"hackathon/internal/handler/middleware"
)

type Dependencies struct {
	AuthTokenVerifier middleware.TokenVerifier
	AuthUserManager   FirebaseUserManager
	DB                *gorm.DB
}

func RegisterRoutes(e *echo.Echo, deps Dependencies) {
	InstallHTTPErrorHandler(e)
	userHandler := newUserHandler(deps.DB, deps.AuthUserManager)

	api := e.Group("/api/v1")
	api.Use(middleware.FirebaseAuth(deps.AuthTokenVerifier))

	api.POST("/users", userHandler.createUser)
	api.GET("/users/me", userHandler.getMe)
	api.GET("/users/:id", userHandler.getUserByID)
	api.PATCH("/users/me", userHandler.patchMe)
	api.DELETE("/users/me", userHandler.deleteMe)

	api.GET("/users/me/settings", userHandler.getMySettings)
	api.PATCH("/users/me/settings", userHandler.patchMySettings)

	api.POST("/users/me/push-tokens", userHandler.createPushToken)
	api.PATCH("/users/me/push-tokens/:id", userHandler.patchPushToken)
	api.DELETE("/users/me/push-tokens/:id", userHandler.deletePushToken)
}

func notImplemented(operation string) echo.HandlerFunc {
	return func(c echo.Context) error {
		c.Logger().Warnf("not implemented endpoint called: operation=%s method=%s path=%s", operation, c.Request().Method, c.Path())
		return echo.NewHTTPError(http.StatusNotImplemented, map[string]any{
			"code":    "NOT_IMPLEMENTED",
			"message": operation + " is not implemented yet",
			"details": nil,
		})
	}
}
