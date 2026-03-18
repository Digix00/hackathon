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
	bleTokenHandler := newBleTokenHandler(deps.BleTokenUsecase)
	encounterHandler := newEncounterHandler(deps.EncounterUsecase)
	reportHandler := newReportHandler(deps.ReportUsecase)
	notificationHandler := newNotificationHandler(deps.NotificationUsecase)

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

	api.POST("/ble-tokens", bleTokenHandler.createBleToken)
	api.GET("/ble-tokens/current", bleTokenHandler.getCurrentBleToken)
	api.GET("/ble-tokens/:token/user", bleTokenHandler.getUserByBleToken)

	api.POST("/encounters", encounterHandler.createEncounter)
	api.GET("/encounters", encounterHandler.listEncounters)
	api.GET("/encounters/:id", encounterHandler.getEncounterByID)

	api.POST("/reports", reportHandler.createReport)

	api.GET("/users/me/notifications", notificationHandler.listNotifications)
	api.PATCH("/users/me/notifications/:id/read", notificationHandler.markNotificationAsRead)
	api.DELETE("/users/me/notifications/:id", notificationHandler.deleteNotification)
}
