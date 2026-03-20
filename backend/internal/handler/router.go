package handler

import (
	"github.com/labstack/echo/v4"

	"hackathon/internal/handler/middleware"
)

func RegisterRoutes(e *echo.Echo, deps Dependencies) {
	InstallHTTPErrorHandler(e, deps.Logger)

	userHandler := newUserHandler(deps.Logger, deps.AuthUserManager, deps.UserUsecase, deps.AvatarUploader)
	settingsHandler := newSettingsHandler(deps.Logger, deps.SettingsUsecase)
	pushTokenHandler := newPushTokenHandler(deps.Logger, deps.PushTokenUsecase)
	bleTokenHandler := newBleTokenHandler(deps.Logger, deps.BleTokenUsecase)
	playlistHandler := newPlaylistHandler(deps.Logger, deps.PlaylistUsecase)
	encounterHandler := newEncounterHandler(deps.Logger, deps.EncounterUsecase)
	reportHandler := newReportHandler(deps.Logger, deps.ReportUsecase)
	muteHandler := newMuteHandler(deps.Logger, deps.MuteUsecase)
	blockHandler := newBlockHandler(deps.Logger, deps.BlockUsecase)
	notificationHandler := newNotificationHandler(deps.Logger, deps.NotificationUsecase)
	musicHandler := newMusicHandler(deps.Logger, deps.MusicUsecase)
	commentHandler := newCommentHandler(deps.Logger, deps.CommentUsecase)
	lyricHandler := newLyricHandler(deps.Logger, deps.LyricUsecase)
	songHandler := newSongHandler(deps.Logger, deps.SongUsecase)
	userTrackHandler := newUserTrackHandler(deps.Logger, deps.UserTrackUsecase)
	locationHandler := newLocationHandler(deps.Logger, deps.LocationUsecase)
	favoriteHandler := newFavoriteHandler(deps.Logger, deps.FavoriteUsecase)

	api := e.Group("/api/v1")
	api.GET("/music-connections/:provider/callback", musicHandler.callback)

	protected := api.Group("")
	protected.Use(middleware.FirebaseAuth(deps.AuthTokenVerifier, middleware.DevAuthConfig{
		Enabled: deps.GoEnv == "development" && deps.DevAuthToken != "",
		Token:   deps.DevAuthToken,
		UID:     deps.DevAuthUID,
	}))

	protected.POST("/users", userHandler.createUser)
	protected.GET("/users/me", userHandler.getMe)
	protected.GET("/users/:id", userHandler.getUserByID)
	protected.PATCH("/users/me", userHandler.patchMe)
	protected.POST("/users/me/avatar", userHandler.uploadAvatar)
	protected.DELETE("/users/me", userHandler.deleteMe)

	protected.GET("/users/me/settings", settingsHandler.getMySettings)
	protected.PATCH("/users/me/settings", settingsHandler.patchMySettings)

	protected.POST("/users/me/push-tokens", pushTokenHandler.createPushToken)
	protected.PATCH("/users/me/push-tokens/:id", pushTokenHandler.patchPushToken)
	protected.DELETE("/users/me/push-tokens/:id", pushTokenHandler.deletePushToken)

	protected.POST("/ble-tokens", bleTokenHandler.createBleToken)
	protected.GET("/ble-tokens/current", bleTokenHandler.getCurrentBleToken)
	protected.GET("/ble-tokens/:token/user", bleTokenHandler.getUserByBleToken)

	protected.POST("/playlists", playlistHandler.createPlaylist)
	protected.GET("/playlists/me", playlistHandler.getMyPlaylists)
	protected.GET("/playlists/:id", playlistHandler.getPlaylist)
	protected.PATCH("/playlists/:id", playlistHandler.updatePlaylist)
	protected.DELETE("/playlists/:id", playlistHandler.deletePlaylist)

	protected.POST("/playlists/:id/tracks", playlistHandler.addPlaylistTrack)
	protected.DELETE("/playlists/:id/tracks/:trackId", playlistHandler.removePlaylistTrack)

	protected.POST("/playlists/:id/favorites", playlistHandler.addPlaylistFavorite)
	protected.DELETE("/playlists/:id/favorites", playlistHandler.removePlaylistFavorite)

	protected.POST("/tracks/:id/favorites", favoriteHandler.addTrackFavorite)
	protected.DELETE("/tracks/:id/favorites", favoriteHandler.removeTrackFavorite)
	protected.GET("/users/me/track-favorites", favoriteHandler.listTrackFavorites)
	protected.GET("/users/me/playlist-favorites", favoriteHandler.listPlaylistFavorites)

	protected.POST("/locations", locationHandler.postLocation)

	protected.POST("/encounters", encounterHandler.createEncounter)
	protected.GET("/encounters", encounterHandler.listEncounters)
	protected.GET("/encounters/:id", encounterHandler.getEncounterByID)
	protected.PATCH("/encounters/:id/read", encounterHandler.markEncounterAsRead)

	protected.POST("/reports", reportHandler.createReport)

	protected.POST("/users/me/mutes", muteHandler.createMute)
	protected.DELETE("/users/me/mutes/:target_user_id", muteHandler.deleteMute)
	protected.GET("/users/me/mutes", muteHandler.listMutes)

	protected.POST("/users/me/blocks", blockHandler.createBlock)
	protected.DELETE("/users/me/blocks/:blocked_user_id", blockHandler.deleteBlock)
	protected.GET("/users/me/blocks", blockHandler.listBlocks)

	protected.GET("/users/me/notifications", notificationHandler.listNotifications)
	protected.PATCH("/users/me/notifications/:id/read", notificationHandler.markNotificationAsRead)
	protected.DELETE("/users/me/notifications/:id", notificationHandler.deleteNotification)

	protected.GET("/music-connections/:provider/authorize", musicHandler.authorize)
	protected.GET("/users/me/music-connections", musicHandler.listConnections)
	protected.DELETE("/users/me/music-connections/:provider", musicHandler.deleteConnection)
	protected.GET("/tracks/search", musicHandler.searchTracks)
	protected.GET("/tracks/:id", musicHandler.getTrack)

	protected.POST("/encounters/:id/comments", commentHandler.createComment)
	protected.GET("/encounters/:id/comments", commentHandler.listComments)
	protected.DELETE("/comments/:id", commentHandler.deleteComment)

	protected.POST("/lyrics", lyricHandler.submitLyric)
	protected.GET("/lyrics/chains/:chain_id", lyricHandler.getChainDetail)
	protected.GET("/users/me/songs", songHandler.listMySongs)
	protected.POST("/songs/:id/likes", songHandler.likeSong)
	protected.DELETE("/songs/:id/likes", songHandler.unlikeSong)

	protected.POST("/users/me/tracks", userTrackHandler.addUserTrack)
	protected.GET("/users/me/tracks", userTrackHandler.listUserTracks)
	protected.DELETE("/users/me/tracks/:id", userTrackHandler.deleteUserTrack)

	protected.GET("/users/me/shared-track", userTrackHandler.getSharedTrack)
	protected.PUT("/users/me/shared-track", userTrackHandler.upsertSharedTrack)
	protected.DELETE("/users/me/shared-track", userTrackHandler.deleteSharedTrack)
}
