//go:build integration

package handler

import (
	"context"
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"os"
	"testing"
	"time"

	"github.com/google/uuid"
	"github.com/labstack/echo/v4"
	"gorm.io/driver/postgres"
	"gorm.io/gorm"

	"hackathon/internal/infra/rdb"
	"hackathon/internal/infra/rdb/model"
	"hackathon/internal/usecase"
)

func openPostgresIntegrationDB(t *testing.T) *gorm.DB {
	t.Helper()

	dsn := os.Getenv("PG_TEST_DATABASE_URL")
	if dsn == "" {
		dsn = "postgres://postgres:postgres@127.0.0.1:5432/hackathon?sslmode=disable"
	}

	db, err := gorm.Open(postgres.Open(dsn), &gorm.Config{})
	if err != nil {
		t.Skipf("skip integration test: postgres is not reachable (%v)", err)
	}

	sqlDB, err := db.DB()
	if err != nil {
		t.Fatalf("get sql.DB: %v", err)
	}

	ctx, cancel := context.WithTimeout(context.Background(), 2*time.Second)
	defer cancel()
	if err := sqlDB.PingContext(ctx); err != nil {
		t.Skipf("skip integration test: postgres ping failed (%v)", err)
	}

	if err := rdb.Migrate(db); err != nil {
		t.Fatalf("migrate postgres: %v", err)
	}

	return db
}

func cleanupPostgresTestData(t *testing.T, db *gorm.DB) {
	t.Helper()
	err := db.Exec(`
TRUNCATE TABLE
	outbox_lyria_jobs,
	song_likes,
	generated_songs,
	lyric_entries,
	lyric_chains,
	playlist_favorites,
	playlist_tracks,
	playlists,
	track_favorites,
	user_tracks,
	mutes,
	reports,
	comments,
	encounter_reads,
	daily_encounter_counts,
	outbox_notifications,
	music_connections,
	ble_tokens,
	users,
	files,
	user_settings,
	user_devices,
	prefectures,
	tracks,
	user_current_tracks,
	encounters,
	blocks
RESTART IDENTITY CASCADE;
`).Error
	if err != nil {
		t.Fatalf("cleanup postgres test data: %v", err)
	}
}

func newPostgresIntegrationServer(t *testing.T, db *gorm.DB, authUID string) *echo.Echo {
	t.Helper()

	userRepo := rdb.NewUserRepository(db)
	userSettingsRepo := rdb.NewUserSettingsRepository(db)
	userDeviceRepo := rdb.NewUserDeviceRepository(db)
	blockRepo := rdb.NewBlockRepository(db)
	encounterRepo := rdb.NewEncounterRepository(db)
	trackRepo := rdb.NewUserCurrentTrackRepository(db)
	bleTokenRepo := rdb.NewBleTokenRepository(db)
	reportRepo := rdb.NewReportRepository(db)

	e := echo.New()
	RegisterRoutes(e, Dependencies{
		AuthTokenVerifier: testTokenVerifier{uid: authUID},
		AuthUserManager:   testAuthUserManager{},
		UserUsecase:       usecase.NewUserUsecase(userRepo, userSettingsRepo, blockRepo, encounterRepo, trackRepo),
		SettingsUsecase:   usecase.NewSettingsUsecase(userRepo, userSettingsRepo),
		PushTokenUsecase:  usecase.NewPushTokenUsecase(userRepo, userDeviceRepo),
		BleTokenUsecase:   usecase.NewBleTokenUsecase(bleTokenRepo, userRepo, blockRepo),
		ReportUsecase:     usecase.NewReportUsecase(userRepo, reportRepo),
	})
	return e
}

func TestPostgresIntegration_UserAndSettingsFlow(t *testing.T) {
	db := openPostgresIntegrationDB(t)
	cleanupPostgresTestData(t, db)
	defer cleanupPostgresTestData(t, db)

	e := newPostgresIntegrationServer(t, db, "firebase-pg-uid-1")

	createReq, err := authRequest(http.MethodPost, "/api/v1/users", map[string]any{
		"display_name": "pg-user",
		"bio":          "from integration test",
	})
	if err != nil {
		t.Fatalf("new request: %v", err)
	}
	createRec := httptest.NewRecorder()
	e.ServeHTTP(createRec, createReq)
	if createRec.Code != http.StatusCreated {
		t.Fatalf("expected 201, got %d: %s", createRec.Code, createRec.Body.String())
	}

	settingsReq, _ := authRequest(http.MethodGet, "/api/v1/users/me/settings", nil)
	settingsRec := httptest.NewRecorder()
	e.ServeHTTP(settingsRec, settingsReq)
	if settingsRec.Code != http.StatusOK {
		t.Fatalf("expected 200, got %d: %s", settingsRec.Code, settingsRec.Body.String())
	}

	patchReq, _ := authRequest(http.MethodPatch, "/api/v1/users/me/settings", map[string]any{
		"detection_distance": 80,
		"theme_mode":         "dark",
	})
	patchRec := httptest.NewRecorder()
	e.ServeHTTP(patchRec, patchReq)
	if patchRec.Code != http.StatusOK {
		t.Fatalf("expected 200, got %d: %s", patchRec.Code, patchRec.Body.String())
	}

	var body map[string]any
	if err := json.Unmarshal(patchRec.Body.Bytes(), &body); err != nil {
		t.Fatalf("unmarshal patch response: %v", err)
	}
	settings := body["settings"].(map[string]any)
	if settings["detection_distance"].(float64) != 80 {
		t.Fatalf("expected detection_distance 80, got %v", settings["detection_distance"])
	}
	if settings["theme_mode"].(string) != "dark" {
		t.Fatalf("expected theme_mode dark, got %v", settings["theme_mode"])
	}
}

func TestPostgresIntegration_PushTokenUpsert(t *testing.T) {
	db := openPostgresIntegrationDB(t)
	cleanupPostgresTestData(t, db)
	defer cleanupPostgresTestData(t, db)

	e := newPostgresIntegrationServer(t, db, "firebase-pg-uid-2")

	createUserReq, _ := authRequest(http.MethodPost, "/api/v1/users", map[string]any{"display_name": "pg-user-device"})
	createUserRec := httptest.NewRecorder()
	e.ServeHTTP(createUserRec, createUserReq)
	if createUserRec.Code != http.StatusCreated {
		t.Fatalf("expected 201, got %d: %s", createUserRec.Code, createUserRec.Body.String())
	}

	createReq, _ := authRequest(http.MethodPost, "/api/v1/users/me/push-tokens", map[string]any{
		"platform":   "ios",
		"device_id":  "pg-device",
		"push_token": "token-a",
	})
	createRec := httptest.NewRecorder()
	e.ServeHTTP(createRec, createReq)
	if createRec.Code != http.StatusCreated {
		t.Fatalf("expected 201, got %d: %s", createRec.Code, createRec.Body.String())
	}

	updateReq, _ := authRequest(http.MethodPost, "/api/v1/users/me/push-tokens", map[string]any{
		"platform":   "ios",
		"device_id":  "pg-device",
		"push_token": "token-b",
	})
	updateRec := httptest.NewRecorder()
	e.ServeHTTP(updateRec, updateReq)
	if updateRec.Code != http.StatusOK {
		t.Fatalf("expected 200, got %d: %s", updateRec.Code, updateRec.Body.String())
	}

	var user model.User
	if err := db.Where("auth_provider = ? AND provider_user_id = ?", testFirebaseProvider, "firebase-pg-uid-2").First(&user).Error; err != nil {
		t.Fatalf("load user: %v", err)
	}

	var count int64
	if err := db.Model(&model.UserDevice{}).Where("user_id = ?", user.ID).Count(&count).Error; err != nil {
		t.Fatalf("count user devices: %v", err)
	}
	if count != 1 {
		t.Fatalf("expected one row after upsert, got %d", count)
	}
}

func TestPostgresIntegration_DeleteMeLyricCleanup(t *testing.T) {
	db := openPostgresIntegrationDB(t)
	cleanupPostgresTestData(t, db)
	defer cleanupPostgresTestData(t, db)

	currentUID := "firebase-pg-uid-lyric-delete"
	otherUID := "firebase-pg-uid-lyric-other"

	currentUser := model.User{
		ID:             uuid.NewString(),
		AuthProvider:   testFirebaseProvider,
		ProviderUserID: currentUID,
		Sex:            "no-answer",
		AgeVisibility:  "hidden",
	}
	if err := db.Create(&currentUser).Error; err != nil {
		t.Fatalf("create current user: %v", err)
	}
	otherUser := model.User{
		ID:             uuid.NewString(),
		AuthProvider:   testFirebaseProvider,
		ProviderUserID: otherUID,
		Sex:            "no-answer",
		AgeVisibility:  "hidden",
	}
	if err := db.Create(&otherUser).Error; err != nil {
		t.Fatalf("create other user: %v", err)
	}

	encounter := orderedEncounter(currentUser.ID, otherUser.ID, time.Now().UTC())
	if err := db.Create(&encounter).Error; err != nil {
		t.Fatalf("create encounter: %v", err)
	}

	soloChainID := uuid.NewString()
	if err := db.Create(&model.LyricChain{ID: soloChainID, Status: "pending", ParticipantCount: 1, Threshold: 4}).Error; err != nil {
		t.Fatalf("create solo chain: %v", err)
	}
	if err := db.Create(&model.LyricEntry{ID: uuid.NewString(), ChainID: soloChainID, UserID: currentUser.ID, EncounterID: encounter.ID, Content: "solo line", SequenceNum: 1}).Error; err != nil {
		t.Fatalf("create solo entry: %v", err)
	}
	if err := db.Create(&model.GeneratedSong{ID: uuid.NewString(), ChainID: soloChainID, Status: "processing"}).Error; err != nil {
		t.Fatalf("create solo generated song: %v", err)
	}
	if err := db.Create(&model.OutboxLyriaJob{ID: uuid.NewString(), ChainID: soloChainID, Status: "pending"}).Error; err != nil {
		t.Fatalf("create solo outbox job: %v", err)
	}

	sharedChainID := uuid.NewString()
	if err := db.Create(&model.LyricChain{ID: sharedChainID, Status: "pending", ParticipantCount: 2, Threshold: 4}).Error; err != nil {
		t.Fatalf("create shared chain: %v", err)
	}
	if err := db.Create(&model.LyricEntry{ID: uuid.NewString(), ChainID: sharedChainID, UserID: currentUser.ID, EncounterID: encounter.ID, Content: "shared line 1", SequenceNum: 1}).Error; err != nil {
		t.Fatalf("create shared entry current user: %v", err)
	}
	if err := db.Create(&model.LyricEntry{ID: uuid.NewString(), ChainID: sharedChainID, UserID: otherUser.ID, EncounterID: encounter.ID, Content: "shared line 2", SequenceNum: 2}).Error; err != nil {
		t.Fatalf("create shared entry other user: %v", err)
	}

	e := newPostgresIntegrationServer(t, db, currentUID)
	deleteReq, _ := authRequest(http.MethodDelete, "/api/v1/users/me", nil)
	deleteRec := httptest.NewRecorder()
	e.ServeHTTP(deleteRec, deleteReq)
	if deleteRec.Code != http.StatusNoContent {
		t.Fatalf("expected 204, got %d: %s", deleteRec.Code, deleteRec.Body.String())
	}

	assertCount := func(name string, expected int64, tableModel any, query string, args ...any) {
		t.Helper()
		var count int64
		if err := db.Model(tableModel).Where(query, args...).Count(&count).Error; err != nil {
			t.Fatalf("count %s: %v", name, err)
		}
		if count != expected {
			t.Fatalf("expected %s=%d, got %d", name, expected, count)
		}
	}

	assertCount("solo chain", 0, &model.LyricChain{}, "id = ?", soloChainID)
	assertCount("solo entries", 0, &model.LyricEntry{}, "chain_id = ?", soloChainID)
	assertCount("solo generated songs", 0, &model.GeneratedSong{}, "chain_id = ?", soloChainID)
	assertCount("solo outbox jobs", 0, &model.OutboxLyriaJob{}, "chain_id = ?", soloChainID)

	assertCount("shared chain", 1, &model.LyricChain{}, "id = ?", sharedChainID)
	assertCount("shared entries", 2, &model.LyricEntry{}, "chain_id = ?", sharedChainID)
	assertCount("shared entries by deleted user", 0, &model.LyricEntry{}, "chain_id = ? AND user_id = ?", sharedChainID, currentUser.ID)

	var deletedUser model.User
	if err := db.Where("auth_provider = ? AND provider_user_id = ?", "system", "deleted-user").First(&deletedUser).Error; err != nil {
		t.Fatalf("load deleted user placeholder: %v", err)
	}
	assertCount("shared entries by placeholder user", 1, &model.LyricEntry{}, "chain_id = ? AND user_id = ?", sharedChainID, deletedUser.ID)
	if deletedUser.Name == nil || *deletedUser.Name != "削除済みユーザー" {
		t.Fatalf("expected deleted user display name to be anonymized, got %v", deletedUser.Name)
	}
}
