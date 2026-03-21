package main

import (
	"context"

	firebaseauth "firebase.google.com/go/v4/auth"
	"go.uber.org/zap"
	"gorm.io/gorm"

	"hackathon/config"
	"hackathon/internal/handler"
	"hackathon/internal/infra/crypto"
	"hackathon/internal/infra/music"
	"hackathon/internal/infra/rdb"
	infrastorage "hackathon/internal/infra/storage"
	"hackathon/internal/usecase"
	usecaseport "hackathon/internal/usecase/port"
)

func buildDependencies(db *gorm.DB, authClient *firebaseauth.Client, cfg *config.Config, log *zap.Logger) handler.Dependencies {
	tokenEncrypter, err := crypto.NewTokenEncrypter(cfg.MusicTokenEncryptionKey)
	if err != nil {
		panic("music token encrypter init failed: " + err.Error())
	}

	var avatarUploader handler.AvatarUploader
	if cfg.AvatarBucketName != "" {
		storageClient, err := infrastorage.NewClient(context.Background(), cfg.AvatarBucketName)
		if err != nil {
			panic("avatar storage client init failed: " + err.Error())
		}
		avatarUploader = storageClient
	}

	userRepo := rdb.NewUserRepository(log, db)
	userSettingsRepo := rdb.NewUserSettingsRepository(log, db)
	userDeviceRepo := rdb.NewUserDeviceRepository(log, db)
	blockRepo := rdb.NewBlockRepository(log, db)
	encounterRepo := rdb.NewEncounterRepository(log, db)
	trackRepo := rdb.NewUserCurrentTrackRepository(log, db)
	userTrackRepo := rdb.NewUserTrackRepository(log, db)
	trackCatalogRepo := rdb.NewTrackCatalogRepository(log, db)
	musicConnectionRepo := rdb.NewMusicConnectionRepository(log, db, tokenEncrypter)
	bleTokenRepo := rdb.NewBleTokenRepository(log, db)
	locationRepo := rdb.NewUserLocationRepository(log, db)
	playlistRepo := rdb.NewPlaylistRepository(log, db)
	trackFavoriteRepo := rdb.NewTrackFavoriteRepository(log, db)
	reportRepo := rdb.NewReportRepository(log, db)
	muteRepo := rdb.NewMuteRepository(log, db)
	notificationRepo := rdb.NewNotificationRepository(log, db)
	commentRepo := rdb.NewCommentRepository(log, db)
	_ = rdb.NewTransactor(db)
	lyricRepo := rdb.NewLyricRepository(log, db)
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
		Logger:              log,
		AuthTokenVerifier:   authClient,
		AuthUserManager:     authClient,
		GoEnv:               cfg.GoEnv,
		DevAuthToken:        cfg.DevAuthToken,
		DevAuthUID:          cfg.DevAuthUID,
		AvatarUploader:      avatarUploader,
		UserUsecase:         usecase.NewUserUsecase(log, userRepo, userSettingsRepo, blockRepo, encounterRepo, trackRepo),
		SettingsUsecase:     usecase.NewSettingsUsecase(log, userRepo, userSettingsRepo),
		PushTokenUsecase:    usecase.NewPushTokenUsecase(log, userRepo, userDeviceRepo),
		BleTokenUsecase:     usecase.NewBleTokenUsecase(log, bleTokenRepo, userRepo, blockRepo),
		PlaylistUsecase:     usecase.NewPlaylistUsecase(log, playlistRepo, userRepo),
		ReportUsecase:       usecase.NewReportUsecase(log, userRepo, reportRepo),
		MuteUsecase:         usecase.NewMuteUsecase(log, userRepo, muteRepo),
		BlockUsecase:        usecase.NewBlockUsecase(log, userRepo, blockRepo),
		NotificationUsecase: usecase.NewNotificationUsecase(log, userRepo, notificationRepo),
		MusicUsecase:        usecase.NewMusicUsecase(log, userRepo, musicConnectionRepo, trackCatalogRepo, []usecaseport.MusicProvider{spotifyProvider, appleMusicProvider}, cfg.MusicStateSecret, cfg.AppDeepLinkScheme),
		EncounterUsecase:    usecase.NewEncounterUsecase(log, userRepo, bleTokenRepo, encounterRepo, blockRepo),
		CommentUsecase:      usecase.NewCommentUsecase(log, userRepo, commentRepo, encounterRepo),
		LyricUsecase:        usecase.NewLyricUsecase(log, userRepo, encounterRepo, lyricRepo),
		SongUsecase:         usecase.NewSongUsecase(log, userRepo, lyricRepo),
		UserTrackUsecase:    usecase.NewUserTrackUsecase(log, userRepo, userTrackRepo, trackRepo, trackCatalogRepo),
		LocationUsecase:     usecase.NewLocationUsecase(log, userRepo, userSettingsRepo, locationRepo, encounterRepo, blockRepo),
		FavoriteUsecase:     usecase.NewFavoriteUsecase(log, userRepo, trackFavoriteRepo, playlistRepo, trackCatalogRepo),
	}
}
