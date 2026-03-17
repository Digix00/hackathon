package main

import (
	firebaseauth "firebase.google.com/go/v4/auth"
	"gorm.io/gorm"

	"hackathon/config"
	"hackathon/internal/handler"
	inframusic "hackathon/internal/infra/music"
	"hackathon/internal/infra/rdb"
	"hackathon/internal/usecase"
)

func buildDependencies(db *gorm.DB, authClient *firebaseauth.Client, cfg *config.Config) handler.Dependencies {
	userRepo := rdb.NewUserRepository(db)
	userSettingsRepo := rdb.NewUserSettingsRepository(db)
	userDeviceRepo := rdb.NewUserDeviceRepository(db)
	blockRepo := rdb.NewBlockRepository(db)
	encounterRepo := rdb.NewEncounterRepository(db)
	currentTrackRepo := rdb.NewUserCurrentTrackRepository(db)
	bleTokenRepo := rdb.NewBleTokenRepository(db)
	musicConnRepo := rdb.NewMusicConnectionRepository(db)
	trackRepo := rdb.NewTrackRepository(db)
	chainRepo := rdb.NewLyricChainRepository(db)
	entryRepo := rdb.NewLyricEntryRepository(db)
	songRepo := rdb.NewGeneratedSongRepository(db)
	outboxRepo := rdb.NewOutboxLyriaJobRepository(db)

	// Spotify クライアント（OAuth + Track 検索を兼ねる）
	spotifyClient := inframusic.NewSpotifyOAuthClient(
		cfg.SpotifyClientID,
		cfg.SpotifyClientSecret,
		cfg.SpotifyRedirectURI,
		cfg.OAuthStateSecret,
	)

	return handler.Dependencies{
		AuthTokenVerifier: authClient,
		AuthUserManager:   authClient,
		UserUsecase:       usecase.NewUserUsecase(userRepo, userSettingsRepo, blockRepo, encounterRepo, currentTrackRepo),
		SettingsUsecase:   usecase.NewSettingsUsecase(userRepo, userSettingsRepo),
		PushTokenUsecase:  usecase.NewPushTokenUsecase(userRepo, userDeviceRepo),
		BleTokenUsecase: usecase.NewBleTokenUsecase(bleTokenRepo, userRepo, blockRepo),
		MusicUsecase: usecase.NewMusicUsecase(
			userRepo,
			musicConnRepo,
			trackRepo,
			spotifyClient,
			spotifyClient,
		),
		LyricUsecase: usecase.NewLyricUsecase(
			userRepo,
			chainRepo,
			entryRepo,
			songRepo,
			outboxRepo,
		),
	}
}
