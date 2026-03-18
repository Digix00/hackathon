package main

import (
	firebaseauth "firebase.google.com/go/v4/auth"
	"gorm.io/gorm"

	"hackathon/config"
	"hackathon/internal/handler"
	"hackathon/internal/infra/crypto"
	"hackathon/internal/infra/music"
	"hackathon/internal/infra/rdb"
	"hackathon/internal/usecase"
	usecaseport "hackathon/internal/usecase/port"
)

func buildDependencies(db *gorm.DB, authClient *firebaseauth.Client, cfg *config.Config) handler.Dependencies {
	tokenEncrypter, err := crypto.NewTokenEncrypter(cfg.MusicTokenEncryptionKey)
	if err != nil {
		panic("music token encrypter init failed: " + err.Error())
	}

	userRepo := rdb.NewUserRepository(db)
	userSettingsRepo := rdb.NewUserSettingsRepository(db)
	userDeviceRepo := rdb.NewUserDeviceRepository(db)
	blockRepo := rdb.NewBlockRepository(db)
	encounterRepo := rdb.NewEncounterRepository(db)
	trackRepo := rdb.NewUserCurrentTrackRepository(db)
	userTrackRepo := rdb.NewUserTrackRepository(db)
	trackCatalogRepo := rdb.NewTrackCatalogRepository(db)
	musicConnectionRepo := rdb.NewMusicConnectionRepository(db, tokenEncrypter)
	bleTokenRepo := rdb.NewBleTokenRepository(db)
	playlistRepo := rdb.NewPlaylistRepository(db)
	reportRepo := rdb.NewReportRepository(db)
	muteRepo := rdb.NewMuteRepository(db)
	notificationRepo := rdb.NewNotificationRepository(db)
	commentRepo := rdb.NewCommentRepository(db)
	_ = rdb.NewTransactor(db)
	spotifyProvider := music.NewSpotifyProvider(music.SpotifyConfig{
		ClientID:     cfg.SpotifyClientID,
		ClientSecret: cfg.SpotifyClientSecret,
		RedirectURL:  cfg.SpotifyRedirectURL,
		AuthorizeURL: cfg.SpotifyAuthorizeURL,
		TokenURL:     cfg.SpotifyTokenURL,
		APIBaseURL:   cfg.SpotifyAPIBaseURL,
	})
	appleMusicProvider := music.NewAppleMusicProvider(music.AppleMusicConfig{
		ClientID:     cfg.AppleMusicClientID,
		ClientSecret: cfg.AppleMusicClientSecret,
		RedirectURL:  cfg.AppleMusicRedirectURL,
		AuthorizeURL: cfg.AppleMusicAuthorizeURL,
		TokenURL:     cfg.AppleMusicTokenURL,
		APIBaseURL:   cfg.AppleMusicAPIBaseURL,
	})

	return handler.Dependencies{
		AuthTokenVerifier:   authClient,
		AuthUserManager:     authClient,
		UserUsecase:         usecase.NewUserUsecase(userRepo, userSettingsRepo, blockRepo, encounterRepo, trackRepo),
		SettingsUsecase:     usecase.NewSettingsUsecase(userRepo, userSettingsRepo),
		PushTokenUsecase:    usecase.NewPushTokenUsecase(userRepo, userDeviceRepo),
		BleTokenUsecase:     usecase.NewBleTokenUsecase(bleTokenRepo, userRepo, blockRepo),
		PlaylistUsecase:     usecase.NewPlaylistUsecase(playlistRepo, userRepo),
		ReportUsecase:       usecase.NewReportUsecase(userRepo, reportRepo),
		MuteUsecase:         usecase.NewMuteUsecase(userRepo, muteRepo),
		NotificationUsecase: usecase.NewNotificationUsecase(userRepo, notificationRepo),
		MusicUsecase:        usecase.NewMusicUsecase(userRepo, musicConnectionRepo, trackCatalogRepo, []usecaseport.MusicProvider{spotifyProvider, appleMusicProvider}, cfg.MusicStateSecret, cfg.AppDeepLinkScheme),
		EncounterUsecase:    usecase.NewEncounterUsecase(userRepo, bleTokenRepo, encounterRepo, blockRepo),
		CommentUsecase:      usecase.NewCommentUsecase(userRepo, commentRepo, encounterRepo),
		UserTrackUsecase:    usecase.NewUserTrackUsecase(userRepo, userTrackRepo, trackRepo, trackCatalogRepo),
	}
}
