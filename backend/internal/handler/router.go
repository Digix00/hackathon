package handler

import (
	"github.com/labstack/echo/v4"

	"hackathon/internal/handler/middleware"
)

func RegisterRoutes(e *echo.Echo, deps Dependencies) {
	InstallHTTPErrorHandler(e)

	userHandler := newUserHandler(deps.AuthUserManager, deps.UserUsecase)
	settingsHandler := newSettingsHandler(deps.SettingsUsecase)
	pushTokenHandler := newPushTokenHandler(deps.PushTokenUsecase)

	api := e.Group("/api/v1")
	api.Use(middleware.FirebaseAuth(deps.AuthTokenVerifier))

	api.POST("/users", userHandler.createUser)
	api.GET("/users/me", userHandler.getMe)
	api.GET("/users/:id", userHandler.getUserByID)
	api.PATCH("/users/me", userHandler.patchMe)
	api.DELETE("/users/me", userHandler.deleteMe)

	api.GET("/users/me/settings", settingsHandler.getMySettings)
	api.PATCH("/users/me/settings", settingsHandler.patchMySettings)

	api.POST("/users/me/push-tokens", pushTokenHandler.createPushToken)
	api.PATCH("/users/me/push-tokens/:id", pushTokenHandler.patchPushToken)
	api.DELETE("/users/me/push-tokens/:id", pushTokenHandler.deletePushToken)
}
