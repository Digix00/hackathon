package main

import (
	firebaseauth "firebase.google.com/go/v4/auth"
	"gorm.io/gorm"

	"hackathon/internal/handler"
	"hackathon/internal/infra/rdb"
	"hackathon/internal/usecase"
)

func buildDependencies(db *gorm.DB, authClient *firebaseauth.Client) handler.Dependencies {
	userRepo := rdb.NewUserRepository(db)
	userSettingsRepo := rdb.NewUserSettingsRepository(db)
	userDeviceRepo := rdb.NewUserDeviceRepository(db)
	blockRepo := rdb.NewBlockRepository(db)
	encounterRepo := rdb.NewEncounterRepository(db)
	trackRepo := rdb.NewUserCurrentTrackRepository(db)
	bleTokenRepo := rdb.NewBleTokenRepository(db)
	reportRepo := rdb.NewReportRepository(db)
	notificationRepo := rdb.NewNotificationRepository(db)

	return handler.Dependencies{
		AuthTokenVerifier:   authClient,
		AuthUserManager:     authClient,
		UserUsecase:         usecase.NewUserUsecase(userRepo, userSettingsRepo, blockRepo, encounterRepo, trackRepo),
		SettingsUsecase:     usecase.NewSettingsUsecase(userRepo, userSettingsRepo),
		PushTokenUsecase:    usecase.NewPushTokenUsecase(userRepo, userDeviceRepo),
		BleTokenUsecase:     usecase.NewBleTokenUsecase(bleTokenRepo, userRepo, blockRepo),
		ReportUsecase:       usecase.NewReportUsecase(userRepo, reportRepo),
		NotificationUsecase: usecase.NewNotificationUsecase(userRepo, notificationRepo),
		EncounterUsecase:    usecase.NewEncounterUsecase(userRepo, bleTokenRepo, encounterRepo, blockRepo),
	}
}
