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
	musicHandler := newMusicHandler(deps.MusicUsecase)
	lyricHandler := newLyricHandler(deps.LyricUsecase)

	api := e.Group("/api/v1")
	api.Use(middleware.FirebaseAuth(deps.AuthTokenVerifier))

	// users
	api.POST("/users", userHandler.createUser)
	api.GET("/users/me", userHandler.getMe)
	api.GET("/users/:id", userHandler.getUserByID)
	api.PATCH("/users/me", userHandler.patchMe)
	api.DELETE("/users/me", userHandler.deleteMe)

	// user-settings
	api.GET("/users/me/settings", settingsHandler.getMySettings)
	api.PATCH("/users/me/settings", settingsHandler.patchMySettings)

	// push-tokens
	api.POST("/users/me/push-tokens", pushTokenHandler.createPushToken)
	api.PATCH("/users/me/push-tokens/:id", pushTokenHandler.patchPushToken)
	api.DELETE("/users/me/push-tokens/:id", pushTokenHandler.deletePushToken)

	// ble-tokens
	api.POST("/ble-tokens", bleTokenHandler.createBleToken)
	api.GET("/ble-tokens/current", bleTokenHandler.getCurrentBleToken)
	api.GET("/ble-tokens/:token/user", bleTokenHandler.getUserByBleToken)

	// music-connections
	api.GET("/music-connections/:provider/authorize", musicHandler.getMusicAuthorizeURL)
	api.GET("/music-connections/:provider/callback", musicHandler.handleMusicCallback)
	api.GET("/users/me/music-connections", musicHandler.getMyMusicConnections)
	api.DELETE("/users/me/music-connections/:provider", musicHandler.deleteMyMusicConnection)

	// tracks
	api.GET("/tracks/search", musicHandler.searchTracks)
	api.GET("/tracks/:id", musicHandler.getTrack)

	// lyrics
	api.POST("/lyrics", lyricHandler.postLyric)
	api.GET("/lyrics/chains/:chain_id", lyricHandler.getLyricChain)
}
