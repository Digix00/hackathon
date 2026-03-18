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
	muteHandler := newMuteHandler(deps.MuteUsecase)
	blockHandler := newBlockHandler(deps.BlockUsecase)
	notificationHandler := newNotificationHandler(deps.NotificationUsecase)
	musicHandler := newMusicHandler(deps.MusicUsecase)

	api := e.Group("/api/v1")
	api.GET("/music-connections/:provider/callback", musicHandler.callback)

	protected := api.Group("")
	protected.Use(middleware.FirebaseAuth(deps.AuthTokenVerifier))

	protected.POST("/users", userHandler.createUser)
	protected.GET("/users/me", userHandler.getMe)
	protected.GET("/users/:id", userHandler.getUserByID)
	protected.PATCH("/users/me", userHandler.patchMe)
	protected.DELETE("/users/me", userHandler.deleteMe)

	protected.GET("/users/me/settings", settingsHandler.getMySettings)
	protected.PATCH("/users/me/settings", settingsHandler.patchMySettings)

	protected.POST("/users/me/push-tokens", pushTokenHandler.createPushToken)
	protected.PATCH("/users/me/push-tokens/:id", pushTokenHandler.patchPushToken)
	protected.DELETE("/users/me/push-tokens/:id", pushTokenHandler.deletePushToken)

	protected.POST("/ble-tokens", bleTokenHandler.createBleToken)
	protected.GET("/ble-tokens/current", bleTokenHandler.getCurrentBleToken)
	protected.GET("/ble-tokens/:token/user", bleTokenHandler.getUserByBleToken)

	protected.POST("/encounters", encounterHandler.createEncounter)
	protected.GET("/encounters", encounterHandler.listEncounters)
	protected.GET("/encounters/:id", encounterHandler.getEncounterByID)

	protected.POST("/reports", reportHandler.createReport)

	protected.POST("/users/me/mutes", muteHandler.createMute)
	protected.DELETE("/users/me/mutes/:target_user_id", muteHandler.deleteMute)

	protected.POST("/users/me/blocks", blockHandler.createBlock)
	protected.DELETE("/users/me/blocks/:blocked_user_id", blockHandler.deleteBlock)

	protected.GET("/users/me/notifications", notificationHandler.listNotifications)
	protected.PATCH("/users/me/notifications/:id/read", notificationHandler.markNotificationAsRead)
	protected.DELETE("/users/me/notifications/:id", notificationHandler.deleteNotification)

	protected.GET("/music-connections/:provider/authorize", musicHandler.authorize)
	protected.GET("/users/me/music-connections", musicHandler.listConnections)
	protected.DELETE("/users/me/music-connections/:provider", musicHandler.deleteConnection)
	protected.GET("/tracks/search", musicHandler.searchTracks)
	protected.GET("/tracks/:id", musicHandler.getTrack)
}
