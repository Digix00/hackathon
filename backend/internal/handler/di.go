package handler

import (
	"context"

	"hackathon/internal/handler/middleware"
	"hackathon/internal/usecase"
)

// Dependencies はhandlerレイヤーが必要とする外部依存をまとめた構造体。
// ルーティング登録前にmain側で構築して渡す。
type Dependencies struct {
	AuthTokenVerifier   middleware.TokenVerifier
	AuthUserManager     FirebaseUserManager
	GoEnv               string
	DevAuthToken        string
	DevAuthUID          string
	UserUsecase         usecase.UserUsecase
	SettingsUsecase     usecase.SettingsUsecase
	PushTokenUsecase    usecase.PushTokenUsecase
	BleTokenUsecase     usecase.BleTokenUsecase
	PlaylistUsecase     usecase.PlaylistUsecase
	ReportUsecase       usecase.ReportUsecase
	MuteUsecase         usecase.MuteUsecase
	BlockUsecase        usecase.BlockUsecase
	NotificationUsecase usecase.NotificationUsecase
	MusicUsecase        usecase.MusicUsecase
	EncounterUsecase    usecase.EncounterUsecase
	CommentUsecase      usecase.CommentUsecase
	LyricUsecase        usecase.LyricUsecase
	SongUsecase         usecase.SongUsecase
	UserTrackUsecase    usecase.UserTrackUsecase
	LocationUsecase     usecase.LocationUsecase
	FavoriteUsecase     usecase.FavoriteUsecase
}

// FirebaseUserManager はFirebase Auth上のユーザー削除操作を抽象化する。
type FirebaseUserManager interface {
	DeleteUser(ctx context.Context, uid string) error
}
