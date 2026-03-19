package handler

import (
	"bytes"
	"context"
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"testing"
	"time"

	firebaseauth "firebase.google.com/go/v4/auth"
	"github.com/google/uuid"
	"github.com/labstack/echo/v4"
	"gorm.io/gorm"

	"hackathon/internal/infra/crypto"
	"hackathon/internal/infra/music"
	"hackathon/internal/infra/rdb"
	"hackathon/internal/infra/rdb/model"
	"hackathon/internal/usecase"
	usecaseport "hackathon/internal/usecase/port"
)

// testTokenEncryptionKey はテスト用の固定暗号鍵（32バイト = 64文字の16進数）
const testTokenEncryptionKey = "0102030405060708090a0b0c0d0e0f101112131415161718191a1b1c1d1e1f20"

const testFirebaseProvider = "firebase"

type testTokenVerifier struct {
	uid string
	err error
}

func (v testTokenVerifier) VerifyIDToken(ctx context.Context, idToken string) (*firebaseauth.Token, error) {
	if v.err != nil {
		return nil, v.err
	}
	return &firebaseauth.Token{UID: v.uid}, nil
}

// testAuthUserManager はテスト用のFirebase Auth stub。
// Firebase への実通信なしに DeleteUser を成功扱いにする。
type testAuthUserManager struct{}

func (testAuthUserManager) DeleteUser(_ context.Context, _ string) error { return nil }

func newTestDB(t *testing.T) *gorm.DB {
	t.Helper()

	if sharedTestDB == nil {
		t.Skip("skip postgres-backed router test: postgres not available")
	}

	cleanupPostgresTestDataForRouter(t, sharedTestDB)
	t.Cleanup(func() {
		cleanupPostgresTestDataForRouter(t, sharedTestDB)
	})

	return sharedTestDB
}

func cleanupPostgresTestDataForRouter(t *testing.T, db *gorm.DB) {
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
	encounter_tracks,
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
	user_locations,
	encounters,
	blocks
RESTART IDENTITY CASCADE;
`).Error
	if err != nil {
		t.Fatalf("cleanup postgres test data: %v", err)
	}
}

func seedTestUser(t *testing.T, db *gorm.DB, providerUserID string) model.User {
	t.Helper()
	name := "tester"
	user := model.User{
		ID:             uuid.NewString(),
		AuthProvider:   testFirebaseProvider,
		ProviderUserID: providerUserID,
		Name:           &name,
		AgeVisibility:  "hidden",
		Sex:            "no-answer",
	}
	if err := db.Create(&user).Error; err != nil {
		t.Fatalf("create user: %v", err)
	}
	return user
}

func newTestServer(t *testing.T, db *gorm.DB, authUID string) *echo.Echo {
	t.Helper()
	return newTestServerWithProviders(t, db, authUID, nil)
}

func newTestServerWithProviders(t *testing.T, db *gorm.DB, authUID string, providers []usecaseport.MusicProvider) *echo.Echo {
	t.Helper()

	userRepo := rdb.NewUserRepository(db)
	userSettingsRepo := rdb.NewUserSettingsRepository(db)
	userDeviceRepo := rdb.NewUserDeviceRepository(db)
	blockRepo := rdb.NewBlockRepository(db)
	encounterRepo := rdb.NewEncounterRepository(db)
	trackRepo := rdb.NewUserCurrentTrackRepository(db)
	trackCatalogRepo := rdb.NewTrackCatalogRepository(db)
	enc, err := crypto.NewTokenEncrypter(testTokenEncryptionKey)
	if err != nil {
		t.Fatalf("token encrypter init: %v", err)
	}
	musicConnectionRepo := rdb.NewMusicConnectionRepository(db, enc)
	bleTokenRepo := rdb.NewBleTokenRepository(db)
	playlistRepo := rdb.NewPlaylistRepository(db)
	reportRepo := rdb.NewReportRepository(db)
	muteRepo := rdb.NewMuteRepository(db)
	notificationRepo := rdb.NewNotificationRepository(db)
	locationRepo := rdb.NewUserLocationRepository(db)
	commentRepo := rdb.NewCommentRepository(db)
	lyricRepo := rdb.NewLyricRepository(db)
	if providers == nil {
		providers = []usecaseport.MusicProvider{
			music.NewSpotifyProvider(music.SpotifyConfig{}),
			music.NewAppleMusicProvider(music.AppleMusicConfig{}),
		}
	}

	userTrackRepo := rdb.NewUserTrackRepository(db)
	trackFavoriteRepo := rdb.NewTrackFavoriteRepository(db)

	e := echo.New()
	RegisterRoutes(e, Dependencies{
		AuthTokenVerifier:   testTokenVerifier{uid: authUID},
		AuthUserManager:     testAuthUserManager{},
		UserUsecase:         usecase.NewUserUsecase(userRepo, userSettingsRepo, blockRepo, encounterRepo, trackRepo),
		SettingsUsecase:     usecase.NewSettingsUsecase(userRepo, userSettingsRepo),
		PushTokenUsecase:    usecase.NewPushTokenUsecase(userRepo, userDeviceRepo),
		BleTokenUsecase:     usecase.NewBleTokenUsecase(bleTokenRepo, userRepo, blockRepo),
		PlaylistUsecase:     usecase.NewPlaylistUsecase(playlistRepo, userRepo),
		ReportUsecase:       usecase.NewReportUsecase(userRepo, reportRepo),
		MuteUsecase:         usecase.NewMuteUsecase(userRepo, muteRepo),
		BlockUsecase:        usecase.NewBlockUsecase(userRepo, blockRepo),
		NotificationUsecase: usecase.NewNotificationUsecase(userRepo, notificationRepo),
		MusicUsecase:        usecase.NewMusicUsecase(userRepo, musicConnectionRepo, trackCatalogRepo, providers, "test-state-secret", "digix"),
		EncounterUsecase:    usecase.NewEncounterUsecase(userRepo, bleTokenRepo, encounterRepo, blockRepo),
		CommentUsecase:      usecase.NewCommentUsecase(userRepo, commentRepo, encounterRepo),
		LyricUsecase:        usecase.NewLyricUsecase(userRepo, encounterRepo, lyricRepo),
		SongUsecase:         usecase.NewSongUsecase(userRepo, lyricRepo),
		UserTrackUsecase:    usecase.NewUserTrackUsecase(userRepo, userTrackRepo, trackRepo, trackCatalogRepo),
		LocationUsecase:     usecase.NewLocationUsecase(userRepo, userSettingsRepo, locationRepo, encounterRepo, blockRepo),
		FavoriteUsecase:     usecase.NewFavoriteUsecase(userRepo, trackFavoriteRepo, playlistRepo, trackCatalogRepo),
	})
	return e
}

func authRequest(method string, path string, body any) (*http.Request, error) {
	var reader *bytes.Reader
	if body == nil {
		reader = bytes.NewReader(nil)
	} else {
		payload, err := json.Marshal(body)
		if err != nil {
			return nil, err
		}
		reader = bytes.NewReader(payload)
	}

	req, err := http.NewRequest(method, path, reader)
	if err != nil {
		return nil, err
	}
	req.Header.Set(echo.HeaderAuthorization, "Bearer test-token")
	req.Header.Set(echo.HeaderContentType, echo.MIMEApplicationJSON)
	return req, nil
}

func TestGetMySettingsCreatesDefaultSettings(t *testing.T) {
	db := newTestDB(t)
	seedTestUser(t, db, "firebase-uid-1")
	e := newTestServer(t, db, "firebase-uid-1")

	req, err := authRequest(http.MethodGet, "/api/v1/users/me/settings", nil)
	if err != nil {
		t.Fatalf("new request: %v", err)
	}
	rec := httptest.NewRecorder()

	e.ServeHTTP(rec, req)

	if rec.Code != http.StatusOK {
		t.Fatalf("expected 200, got %d: %s", rec.Code, rec.Body.String())
	}

	var body map[string]any
	if err := json.Unmarshal(rec.Body.Bytes(), &body); err != nil {
		t.Fatalf("unmarshal response: %v", err)
	}
	settings := body["settings"].(map[string]any)
	if settings["detection_distance"].(float64) != 50 {
		t.Fatalf("expected default detection_distance 50, got %v", settings["detection_distance"])
	}
	if settings["theme_mode"].(string) != "system" {
		t.Fatalf("expected default theme_mode system, got %v", settings["theme_mode"])
	}
}

func TestPatchMySettingsRejectsOutOfRangeDistance(t *testing.T) {
	db := newTestDB(t)
	seedTestUser(t, db, "firebase-uid-2")
	e := newTestServer(t, db, "firebase-uid-2")

	req, err := authRequest(http.MethodPatch, "/api/v1/users/me/settings", map[string]any{
		"detection_distance": 101,
	})
	if err != nil {
		t.Fatalf("new request: %v", err)
	}
	rec := httptest.NewRecorder()

	e.ServeHTTP(rec, req)

	if rec.Code != http.StatusBadRequest {
		t.Fatalf("expected 400, got %d: %s", rec.Code, rec.Body.String())
	}
}

func TestCreatePushTokenUpsertsByPlatformAndDeviceID(t *testing.T) {
	db := newTestDB(t)
	user := seedTestUser(t, db, "firebase-uid-3")
	e := newTestServer(t, db, "firebase-uid-3")

	createReq, err := authRequest(http.MethodPost, "/api/v1/users/me/push-tokens", map[string]any{
		"platform":    "ios",
		"device_id":   "device-1",
		"push_token":  "token-a",
		"app_version": "1.0.0",
	})
	if err != nil {
		t.Fatalf("new request: %v", err)
	}
	createRec := httptest.NewRecorder()
	e.ServeHTTP(createRec, createReq)
	if createRec.Code != http.StatusCreated {
		t.Fatalf("expected 201, got %d: %s", createRec.Code, createRec.Body.String())
	}

	updateReq, err := authRequest(http.MethodPost, "/api/v1/users/me/push-tokens", map[string]any{
		"platform":    "ios",
		"device_id":   "device-1",
		"push_token":  "token-b",
		"app_version": "1.0.1",
	})
	if err != nil {
		t.Fatalf("new request: %v", err)
	}
	updateRec := httptest.NewRecorder()
	e.ServeHTTP(updateRec, updateReq)
	if updateRec.Code != http.StatusOK {
		t.Fatalf("expected 200, got %d: %s", updateRec.Code, updateRec.Body.String())
	}

	var count int64
	if err := db.Model(&model.UserDevice{}).Where("user_id = ?", user.ID).Count(&count).Error; err != nil {
		t.Fatalf("count devices: %v", err)
	}
	if count != 1 {
		t.Fatalf("expected 1 device after upsert, got %d", count)
	}

	var device model.UserDevice
	if err := db.Where("user_id = ? AND platform = ? AND device_id = ?", user.ID, "ios", "device-1").First(&device).Error; err != nil {
		t.Fatalf("load device: %v", err)
	}
	if device.DeviceToken != "token-b" {
		t.Fatalf("expected token-b, got %s", device.DeviceToken)
	}
}

func TestPatchAndDeletePushToken(t *testing.T) {
	db := newTestDB(t)
	user := seedTestUser(t, db, "firebase-uid-4")
	device := model.UserDevice{
		ID:          uuid.NewString(),
		UserID:      user.ID,
		Platform:    "android",
		DeviceID:    "device-2",
		DeviceToken: "token-z",
		Enabled:     true,
	}
	if err := db.Create(&device).Error; err != nil {
		t.Fatalf("create device: %v", err)
	}

	e := newTestServer(t, db, "firebase-uid-4")

	patchReq, err := authRequest(http.MethodPatch, "/api/v1/users/me/push-tokens/"+device.ID, map[string]any{
		"enabled": false,
	})
	if err != nil {
		t.Fatalf("new request: %v", err)
	}
	patchRec := httptest.NewRecorder()
	e.ServeHTTP(patchRec, patchReq)
	if patchRec.Code != http.StatusOK {
		t.Fatalf("expected 200, got %d: %s", patchRec.Code, patchRec.Body.String())
	}

	var updated model.UserDevice
	if err := db.First(&updated, "id = ?", device.ID).Error; err != nil {
		t.Fatalf("reload device: %v", err)
	}
	if updated.Enabled {
		t.Fatalf("expected device to be disabled")
	}

	deleteReq, err := authRequest(http.MethodDelete, "/api/v1/users/me/push-tokens/"+device.ID, nil)
	if err != nil {
		t.Fatalf("new request: %v", err)
	}
	deleteRec := httptest.NewRecorder()
	e.ServeHTTP(deleteRec, deleteReq)
	if deleteRec.Code != http.StatusNoContent {
		t.Fatalf("expected 204, got %d: %s", deleteRec.Code, deleteRec.Body.String())
	}
}

func TestCreateGetPatchAndDeleteUserFlow(t *testing.T) {
	db := newTestDB(t)
	if err := db.Create(&model.Prefecture{ID: "13", Name: "東京都"}).Error; err != nil {
		t.Fatalf("create prefecture: %v", err)
	}
	e := newTestServer(t, db, "firebase-uid-user-flow")

	createReq, err := authRequest(http.MethodPost, "/api/v1/users", map[string]any{
		"display_name":   "mimura",
		"bio":            "music lover",
		"birthdate":      "1995-04-01",
		"age_visibility": "by-10",
		"prefecture_id":  "13",
		"sex":            "male",
	})
	if err != nil {
		t.Fatalf("new request: %v", err)
	}
	createRec := httptest.NewRecorder()
	e.ServeHTTP(createRec, createReq)
	if createRec.Code != http.StatusCreated {
		t.Fatalf("expected 201, got %d: %s", createRec.Code, createRec.Body.String())
	}

	getReq, _ := authRequest(http.MethodGet, "/api/v1/users/me", nil)
	getRec := httptest.NewRecorder()
	e.ServeHTTP(getRec, getReq)
	if getRec.Code != http.StatusOK {
		t.Fatalf("expected 200, got %d: %s", getRec.Code, getRec.Body.String())
	}

	var getBody map[string]any
	if err := json.Unmarshal(getRec.Body.Bytes(), &getBody); err != nil {
		t.Fatalf("unmarshal get response: %v", err)
	}
	user := getBody["user"].(map[string]any)
	if user["display_name"].(string) != "mimura" {
		t.Fatalf("expected display_name mimura, got %v", user["display_name"])
	}

	patchReq, _ := authRequest(http.MethodPatch, "/api/v1/users/me", map[string]any{
		"display_name": "mimura_new",
		"bio":          "updated bio",
	})
	patchRec := httptest.NewRecorder()
	e.ServeHTTP(patchRec, patchReq)
	if patchRec.Code != http.StatusOK {
		t.Fatalf("expected 200, got %d: %s", patchRec.Code, patchRec.Body.String())
	}

	var patchBody map[string]any
	if err := json.Unmarshal(patchRec.Body.Bytes(), &patchBody); err != nil {
		t.Fatalf("unmarshal patch response: %v", err)
	}
	patchedUser := patchBody["user"].(map[string]any)
	if patchedUser["display_name"].(string) != "mimura_new" {
		t.Fatalf("expected updated display_name, got %v", patchedUser["display_name"])
	}

	deleteReq, _ := authRequest(http.MethodDelete, "/api/v1/users/me", nil)
	deleteRec := httptest.NewRecorder()
	e.ServeHTTP(deleteRec, deleteReq)
	if deleteRec.Code != http.StatusNoContent {
		t.Fatalf("expected 204, got %d: %s", deleteRec.Code, deleteRec.Body.String())
	}

	getAfterDeleteReq, _ := authRequest(http.MethodGet, "/api/v1/users/me", nil)
	getAfterDeleteRec := httptest.NewRecorder()
	e.ServeHTTP(getAfterDeleteRec, getAfterDeleteReq)
	if getAfterDeleteRec.Code != http.StatusNotFound {
		t.Fatalf("expected 404 after delete, got %d: %s", getAfterDeleteRec.Code, getAfterDeleteRec.Body.String())
	}
}

func TestDeleteMeCleansUpRelatedData(t *testing.T) {
	db := newTestDB(t)

	user := seedTestUser(t, db, "firebase-uid-delete-user")
	other := seedTestUser(t, db, "firebase-uid-delete-other")

	encounter := orderedEncounter(user.ID, other.ID, jsonDate(t, "2026-03-16"))
	if err := db.Create(&encounter).Error; err != nil {
		t.Fatalf("create encounter: %v", err)
	}

	if err := db.Create(&model.EncounterRead{ID: uuid.NewString(), UserID: user.ID, EncounterID: encounter.ID}).Error; err != nil {
		t.Fatalf("create encounter read: %v", err)
	}
	track := model.Track{ID: uuid.NewString(), ExternalID: "ext-del-1", Provider: "spotify", Title: "song", ArtistName: "artist"}
	if err := db.Create(&track).Error; err != nil {
		t.Fatalf("create track: %v", err)
	}
	if err := db.Create(&model.EncounterTrack{ID: uuid.NewString(), EncounterID: encounter.ID, TrackID: track.ID, SourceUserID: user.ID}).Error; err != nil {
		t.Fatalf("create encounter track: %v", err)
	}
	if err := db.Create(&model.Comment{ID: uuid.NewString(), EncounterID: encounter.ID, CommenterUserID: user.ID, Content: "hello"}).Error; err != nil {
		t.Fatalf("create comment: %v", err)
	}
	if err := db.Create(&model.DailyEncounterCount{ID: uuid.NewString(), UserID: user.ID, Date: jsonDate(t, "2026-03-16"), Count: 1}).Error; err != nil {
		t.Fatalf("create daily encounter count: %v", err)
	}
	if err := db.Create(&model.OutboxNotification{ID: uuid.NewString(), UserID: user.ID, EncounterID: encounter.ID, Status: "pending"}).Error; err != nil {
		t.Fatalf("create outbox notification: %v", err)
	}
	if err := db.Create(&model.Report{ID: uuid.NewString(), ReporterUserID: user.ID, ReportedUserID: other.ID, ReportType: "user", Reason: "spam"}).Error; err != nil {
		t.Fatalf("create report: %v", err)
	}
	if err := db.Create(&model.Block{ID: uuid.NewString(), BlockerUserID: user.ID, BlockedUserID: other.ID}).Error; err != nil {
		t.Fatalf("create block: %v", err)
	}
	if err := db.Create(&model.Mute{ID: uuid.NewString(), UserID: user.ID, TargetUserID: other.ID}).Error; err != nil {
		t.Fatalf("create mute: %v", err)
	}

	if err := db.Create(&model.UserTrack{ID: uuid.NewString(), UserID: user.ID, TrackID: track.ID}).Error; err != nil {
		t.Fatalf("create user track: %v", err)
	}
	if err := db.Create(&model.UserCurrentTrack{ID: uuid.NewString(), UserID: user.ID, TrackID: track.ID}).Error; err != nil {
		t.Fatalf("create user current track: %v", err)
	}
	if err := db.Create(&model.TrackFavorite{ID: uuid.NewString(), UserID: user.ID, TrackID: track.ID}).Error; err != nil {
		t.Fatalf("create track favorite: %v", err)
	}

	playlist := model.Playlist{ID: uuid.NewString(), UserID: user.ID, Name: "my list", IsPublic: true}
	if err := db.Create(&playlist).Error; err != nil {
		t.Fatalf("create playlist: %v", err)
	}
	if err := db.Create(&model.PlaylistTrack{ID: uuid.NewString(), PlaylistID: playlist.ID, TrackID: track.ID, SortOrder: 1}).Error; err != nil {
		t.Fatalf("create playlist track: %v", err)
	}
	if err := db.Create(&model.PlaylistFavorite{ID: uuid.NewString(), UserID: user.ID, PlaylistID: playlist.ID}).Error; err != nil {
		t.Fatalf("create playlist favorite: %v", err)
	}

	if err := db.Create(&model.SongLike{ID: uuid.NewString(), SongID: uuid.NewString(), UserID: user.ID}).Error; err != nil {
		t.Fatalf("create song like: %v", err)
	}

	if err := db.Create(&model.MusicConnection{ID: uuid.NewString(), UserID: user.ID, Provider: "spotify", ProviderUserID: "sp-user", AccessToken: "token"}).Error; err != nil {
		t.Fatalf("create music connection: %v", err)
	}
	if err := db.Create(&model.BleToken{ID: uuid.NewString(), UserID: user.ID, Token: "ble-token", ValidFrom: time.Now().UTC(), ValidTo: time.Now().UTC().Add(time.Hour)}).Error; err != nil {
		t.Fatalf("create ble token: %v", err)
	}
	if err := db.Create(&model.File{ID: uuid.NewString(), FilePath: "/tmp/a.png", FileType: "image", MimeType: "image/png", FileSize: 10, UploadedByUserID: user.ID}).Error; err != nil {
		t.Fatalf("create file: %v", err)
	}

	e := newTestServer(t, db, "firebase-uid-delete-user")
	deleteReq, _ := authRequest(http.MethodDelete, "/api/v1/users/me", nil)
	deleteRec := httptest.NewRecorder()
	e.ServeHTTP(deleteRec, deleteReq)
	if deleteRec.Code != http.StatusNoContent {
		t.Fatalf("expected 204, got %d: %s", deleteRec.Code, deleteRec.Body.String())
	}

	assertZero := func(name string, tableModel any, query string, args ...any) {
		t.Helper()
		var count int64
		if err := db.Model(tableModel).Where(query, args...).Count(&count).Error; err != nil {
			t.Fatalf("count %s: %v", name, err)
		}
		if count != 0 {
			t.Fatalf("expected %s count=0, got %d", name, count)
		}
	}

	assertZero("users", &model.User{}, "id = ?", user.ID)
	assertZero("user_settings", &model.UserSettings{}, "user_id = ?", user.ID)
	assertZero("encounters", &model.Encounter{}, "user_id1 = ? OR user_id2 = ?", user.ID, user.ID)
	assertZero("comments", &model.Comment{}, "commenter_user_id = ?", user.ID)
	assertZero("encounter_tracks", &model.EncounterTrack{}, "source_user_id = ? OR encounter_id = ?", user.ID, encounter.ID)
	assertZero("daily_encounter_counts", &model.DailyEncounterCount{}, "user_id = ?", user.ID)
	assertZero("outbox_notifications", &model.OutboxNotification{}, "user_id = ?", user.ID)
	assertZero("reports", &model.Report{}, "reporter_user_id = ? OR reported_user_id = ?", user.ID, user.ID)
	assertZero("blocks", &model.Block{}, "blocker_user_id = ? OR blocked_user_id = ?", user.ID, user.ID)
	assertZero("mutes", &model.Mute{}, "user_id = ? OR target_user_id = ?", user.ID, user.ID)
	assertZero("user_tracks", &model.UserTrack{}, "user_id = ?", user.ID)
	assertZero("user_current_tracks", &model.UserCurrentTrack{}, "user_id = ?", user.ID)
	assertZero("track_favorites", &model.TrackFavorite{}, "user_id = ?", user.ID)
	assertZero("playlists", &model.Playlist{}, "user_id = ?", user.ID)
	assertZero("playlist_favorites", &model.PlaylistFavorite{}, "user_id = ?", user.ID)
	assertZero("song_likes", &model.SongLike{}, "user_id = ?", user.ID)
	assertZero("music_connections", &model.MusicConnection{}, "user_id = ?", user.ID)
	assertZero("ble_tokens", &model.BleToken{}, "user_id = ?", user.ID)
	assertZero("files", &model.File{}, "uploaded_by_user_id = ?", user.ID)
}

func TestCreateEncounterRejectsInvalidRSSI(t *testing.T) {
	db := newTestDB(t)
	seedTestUser(t, db, "firebase-uid-enc-rssi-invalid")
	e := newTestServer(t, db, "firebase-uid-enc-rssi-invalid")

	req, err := authRequest(http.MethodPost, "/api/v1/encounters", map[string]any{
		"target_ble_token": "b2f2f0fa3c1d9e77",
		"type":             "ble",
		"rssi":             10,
		"occurred_at":      time.Now().UTC().Format(time.RFC3339),
	})
	if err != nil {
		t.Fatalf("new request: %v", err)
	}
	rec := httptest.NewRecorder()

	e.ServeHTTP(rec, req)

	if rec.Code != http.StatusBadRequest {
		t.Fatalf("expected 400, got %d: %s", rec.Code, rec.Body.String())
	}
}

func TestCreateEncounterReturns204WhenRSSIFiltered(t *testing.T) {
	db := newTestDB(t)
	seedTestUser(t, db, "firebase-uid-enc-rssi-filtered")
	e := newTestServer(t, db, "firebase-uid-enc-rssi-filtered")

	req, err := authRequest(http.MethodPost, "/api/v1/encounters", map[string]any{
		"target_ble_token": "b2f2f0fa3c1d9e77",
		"type":             "ble",
		"rssi":             -90,
		"occurred_at":      time.Now().UTC().Format(time.RFC3339),
	})
	if err != nil {
		t.Fatalf("new request: %v", err)
	}
	rec := httptest.NewRecorder()

	e.ServeHTTP(rec, req)

	if rec.Code != http.StatusNoContent {
		t.Fatalf("expected 204, got %d: %s", rec.Code, rec.Body.String())
	}

	var count int64
	if err := db.Model(&model.Encounter{}).Count(&count).Error; err != nil {
		t.Fatalf("count encounters: %v", err)
	}
	if count != 0 {
		t.Fatalf("expected no encounters, got %d", count)
	}
}

func TestCreateEncounterReturns201Then200ForDuplicate(t *testing.T) {
	db := newTestDB(t)
	_ = seedTestUser(t, db, "firebase-uid-enc-dedupe-req")
	target := seedTestUser(t, db, "firebase-uid-enc-dedupe-target")
	now := time.Now().UTC()
	seedBleToken(t, db, target.ID, "b2f2f0fa3c1d9e77", now)
	e := newTestServer(t, db, "firebase-uid-enc-dedupe-req")

	payload := map[string]any{
		"target_ble_token": "b2f2f0fa3c1d9e77",
		"type":             "ble",
		"rssi":             -50,
		"occurred_at":      now.Format(time.RFC3339),
	}

	firstReq, _ := authRequest(http.MethodPost, "/api/v1/encounters", payload)
	firstRec := httptest.NewRecorder()
	e.ServeHTTP(firstRec, firstReq)
	if firstRec.Code != http.StatusCreated {
		t.Fatalf("expected 201, got %d: %s", firstRec.Code, firstRec.Body.String())
	}

	var firstBody map[string]any
	if err := json.Unmarshal(firstRec.Body.Bytes(), &firstBody); err != nil {
		t.Fatalf("unmarshal first response: %v", err)
	}
	firstEncounter := firstBody["encounter"].(map[string]any)
	firstID := firstEncounter["id"].(string)

	secondReq, _ := authRequest(http.MethodPost, "/api/v1/encounters", payload)
	secondRec := httptest.NewRecorder()
	e.ServeHTTP(secondRec, secondReq)
	if secondRec.Code != http.StatusOK {
		t.Fatalf("expected 200, got %d: %s", secondRec.Code, secondRec.Body.String())
	}

	var secondBody map[string]any
	if err := json.Unmarshal(secondRec.Body.Bytes(), &secondBody); err != nil {
		t.Fatalf("unmarshal second response: %v", err)
	}
	secondEncounter := secondBody["encounter"].(map[string]any)
	secondID := secondEncounter["id"].(string)
	if secondID != firstID {
		t.Fatalf("expected duplicate encounter id %s, got %s", firstID, secondID)
	}
}

func TestCreateEncounterReturns409WhenDailyPairLimitExceeded(t *testing.T) {
	db := newTestDB(t)
	_ = seedTestUser(t, db, "firebase-uid-enc-pair-limit-req")
	target := seedTestUser(t, db, "firebase-uid-enc-pair-limit-target")
	now := time.Now().UTC()
	seedBleToken(t, db, target.ID, "c2f2f0fa3c1d9e88", now)
	e := newTestServer(t, db, "firebase-uid-enc-pair-limit-req")

	firstPayload := map[string]any{
		"target_ble_token": "c2f2f0fa3c1d9e88",
		"type":             "ble",
		"rssi":             -50,
		"occurred_at":      now.Add(-10 * time.Minute).Format(time.RFC3339),
	}
	firstReq, _ := authRequest(http.MethodPost, "/api/v1/encounters", firstPayload)
	firstRec := httptest.NewRecorder()
	e.ServeHTTP(firstRec, firstReq)
	if firstRec.Code != http.StatusCreated {
		t.Fatalf("expected 201, got %d: %s", firstRec.Code, firstRec.Body.String())
	}

	secondPayload := map[string]any{
		"target_ble_token": "c2f2f0fa3c1d9e88",
		"type":             "ble",
		"rssi":             -50,
		"occurred_at":      now.Format(time.RFC3339),
	}
	secondReq, _ := authRequest(http.MethodPost, "/api/v1/encounters", secondPayload)
	secondRec := httptest.NewRecorder()
	e.ServeHTTP(secondRec, secondReq)
	if secondRec.Code != http.StatusConflict {
		t.Fatalf("expected 409, got %d: %s", secondRec.Code, secondRec.Body.String())
	}
}

func TestCreateEncounterReturns429WhenDailyUserLimitExceeded(t *testing.T) {
	db := newTestDB(t)
	requester := seedTestUser(t, db, "firebase-uid-enc-user-limit-req")
	target := seedTestUser(t, db, "firebase-uid-enc-user-limit-target")
	now := time.Now().UTC()
	seedBleToken(t, db, target.ID, "d2f2f0fa3c1d9e99", now)

	limitDate := startOfUTCDate(now)
	if err := db.Create(&model.DailyEncounterCount{
		ID:     uuid.NewString(),
		UserID: requester.ID,
		Date:   limitDate,
		Count:  10,
	}).Error; err != nil {
		t.Fatalf("create daily encounter count: %v", err)
	}

	e := newTestServer(t, db, "firebase-uid-enc-user-limit-req")
	req, _ := authRequest(http.MethodPost, "/api/v1/encounters", map[string]any{
		"target_ble_token": "d2f2f0fa3c1d9e99",
		"type":             "ble",
		"rssi":             -50,
		"occurred_at":      now.Format(time.RFC3339),
	})
	rec := httptest.NewRecorder()
	e.ServeHTTP(rec, req)
	if rec.Code != http.StatusTooManyRequests {
		t.Fatalf("expected 429, got %d: %s", rec.Code, rec.Body.String())
	}
}

func TestListEncountersPaginationCursor(t *testing.T) {
	db := newTestDB(t)
	requester := seedTestUser(t, db, "firebase-uid-enc-list-req")
	other1 := seedTestUser(t, db, "firebase-uid-enc-list-1")
	other2 := seedTestUser(t, db, "firebase-uid-enc-list-2")

	older := orderedEncounter(requester.ID, other1.ID, jsonDate(t, "2026-03-16").Add(9*time.Hour))
	newer := orderedEncounter(requester.ID, other2.ID, jsonDate(t, "2026-03-16").Add(10*time.Hour))
	if err := db.Create(&older).Error; err != nil {
		t.Fatalf("create older encounter: %v", err)
	}
	if err := db.Create(&newer).Error; err != nil {
		t.Fatalf("create newer encounter: %v", err)
	}

	e := newTestServer(t, db, "firebase-uid-enc-list-req")
	firstReq, _ := authRequest(http.MethodGet, "/api/v1/encounters?limit=1", nil)
	firstRec := httptest.NewRecorder()
	e.ServeHTTP(firstRec, firstReq)
	if firstRec.Code != http.StatusOK {
		t.Fatalf("expected 200, got %d: %s", firstRec.Code, firstRec.Body.String())
	}

	var firstBody map[string]any
	if err := json.Unmarshal(firstRec.Body.Bytes(), &firstBody); err != nil {
		t.Fatalf("unmarshal first response: %v", err)
	}
	firstEncounters := firstBody["encounters"].([]any)
	if len(firstEncounters) != 1 {
		t.Fatalf("expected 1 encounter, got %d", len(firstEncounters))
	}
	firstEncounter := firstEncounters[0].(map[string]any)
	if firstEncounter["id"].(string) != newer.ID {
		t.Fatalf("expected newest encounter %s, got %s", newer.ID, firstEncounter["id"].(string))
	}
	firstPagination := firstBody["pagination"].(map[string]any)
	if firstPagination["has_more"].(bool) != true {
		t.Fatalf("expected has_more true")
	}
	nextCursor := firstPagination["next_cursor"].(string)
	if nextCursor == "" {
		t.Fatalf("expected next_cursor")
	}

	secondReq, _ := authRequest(http.MethodGet, "/api/v1/encounters?limit=1&cursor="+nextCursor, nil)
	secondRec := httptest.NewRecorder()
	e.ServeHTTP(secondRec, secondReq)
	if secondRec.Code != http.StatusOK {
		t.Fatalf("expected 200, got %d: %s", secondRec.Code, secondRec.Body.String())
	}

	var secondBody map[string]any
	if err := json.Unmarshal(secondRec.Body.Bytes(), &secondBody); err != nil {
		t.Fatalf("unmarshal second response: %v", err)
	}
	secondEncounters := secondBody["encounters"].([]any)
	if len(secondEncounters) != 1 {
		t.Fatalf("expected 1 encounter, got %d", len(secondEncounters))
	}
	secondEncounter := secondEncounters[0].(map[string]any)
	if secondEncounter["id"].(string) != older.ID {
		t.Fatalf("expected older encounter %s, got %s", older.ID, secondEncounter["id"].(string))
	}
	secondPagination := secondBody["pagination"].(map[string]any)
	if secondPagination["has_more"].(bool) != false {
		t.Fatalf("expected has_more false")
	}
	if secondPagination["next_cursor"] != nil {
		t.Fatalf("expected next_cursor nil, got %v", secondPagination["next_cursor"])
	}
}

func TestGetUserByIDMasksProfileAndTrack(t *testing.T) {
	db := newTestDB(t)
	requester := seedTestUser(t, db, "firebase-uid-requester")
	targetName := "target"
	bio := "secret bio"
	prefID := "13"
	birthdate := jsonDate(t, "1998-03-10")
	if err := db.Create(&model.Prefecture{ID: "13", Name: "東京都"}).Error; err != nil {
		t.Fatalf("create prefecture: %v", err)
	}
	target := model.User{
		ID:             uuid.NewString(),
		AuthProvider:   testFirebaseProvider,
		ProviderUserID: "firebase-uid-target",
		Name:           &targetName,
		Bio:            &bio,
		Birthdate:      &birthdate,
		AgeVisibility:  "by-10",
		PrefectureID:   &prefID,
		Sex:            "female",
	}
	if err := db.Create(&target).Error; err != nil {
		t.Fatalf("create target user: %v", err)
	}
	settings := model.UserSettings{ID: uuid.NewString(), UserID: target.ID}
	if err := db.Create(&settings).Error; err != nil {
		t.Fatalf("create user settings: %v", err)
	}
	if err := db.Model(&model.UserSettings{}).Where("id = ?", settings.ID).Updates(map[string]any{
		"profile_visible": false,
		"track_visible":   false,
	}).Error; err != nil {
		t.Fatalf("update user settings visibility: %v", err)
	}
	encounter := orderedEncounter(requester.ID, target.ID, jsonDate(t, "2026-03-16"))
	if err := db.Create(&encounter).Error; err != nil {
		t.Fatalf("create encounter: %v", err)
	}
	e := newTestServer(t, db, "firebase-uid-requester")

	req, _ := authRequest(http.MethodGet, "/api/v1/users/"+target.ID, nil)
	rec := httptest.NewRecorder()
	e.ServeHTTP(rec, req)
	if rec.Code != http.StatusOK {
		t.Fatalf("expected 200, got %d: %s", rec.Code, rec.Body.String())
	}

	var body map[string]any
	if err := json.Unmarshal(rec.Body.Bytes(), &body); err != nil {
		t.Fatalf("unmarshal public user response: %v", err)
	}
	publicUser := body["user"].(map[string]any)
	if publicUser["bio"] != nil {
		t.Fatalf("expected bio to be masked, got %v", publicUser["bio"])
	}
	if publicUser["birthplace"] != nil {
		t.Fatalf("expected birthplace to be masked, got %v", publicUser["birthplace"])
	}
	if publicUser["age_range"] != nil {
		t.Fatalf("expected age_range to be masked, got %v", publicUser["age_range"])
	}
	if publicUser["shared_track"] != nil {
		t.Fatalf("expected shared_track to be masked, got %v", publicUser["shared_track"])
	}
	if publicUser["encounter_count"].(float64) != 1 {
		t.Fatalf("expected encounter_count 1, got %v", publicUser["encounter_count"])
	}
}

func TestGetUserByIDReturns404WhenBlocked(t *testing.T) {
	db := newTestDB(t)
	requester := seedTestUser(t, db, "firebase-uid-requester-block")
	target := seedTestUser(t, db, "firebase-uid-target-block")
	if err := db.Create(&model.Block{ID: uuid.NewString(), BlockerUserID: requester.ID, BlockedUserID: target.ID}).Error; err != nil {
		t.Fatalf("create block: %v", err)
	}
	e := newTestServer(t, db, "firebase-uid-requester-block")

	req, _ := authRequest(http.MethodGet, "/api/v1/users/"+target.ID, nil)
	rec := httptest.NewRecorder()
	e.ServeHTTP(rec, req)
	if rec.Code != http.StatusNotFound {
		t.Fatalf("expected 404, got %d: %s", rec.Code, rec.Body.String())
	}
}

func jsonDate(t *testing.T, raw string) time.Time {
	t.Helper()
	parsed, err := time.Parse("2006-01-02", raw)
	if err != nil {
		t.Fatalf("parse date: %v", err)
	}
	return parsed.UTC()
}

func startOfUTCDate(date time.Time) time.Time {
	return time.Date(date.Year(), date.Month(), date.Day(), 0, 0, 0, 0, time.UTC)
}

func orderedEncounter(userA string, userB string, encounteredAt time.Time) model.Encounter {
	user1 := userA
	user2 := userB
	if user2 < user1 {
		user1, user2 = user2, user1
	}
	return model.Encounter{
		ID:            uuid.NewString(),
		UserID1:       user1,
		UserID2:       user2,
		EncounteredAt: encounteredAt,
		EncounterType: "ble",
	}
}

func TestMusicConnectionsAuthorizeCallbackListDeleteAndTrackEndpoints(t *testing.T) {
	db := newTestDB(t)
	user := seedTestUser(t, db, "firebase-uid-music")

	providerServer := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		switch {
		case r.URL.Path == "/api/token":
			w.Header().Set("Content-Type", "application/json")
			_, _ = w.Write([]byte(`{"access_token":"spotify-access","refresh_token":"spotify-refresh","expires_in":3600}`))
		case r.URL.Path == "/v1/me":
			if got := r.Header.Get("Authorization"); got != "Bearer spotify-access" {
				t.Fatalf("unexpected auth header for /me: %s", got)
			}
			w.Header().Set("Content-Type", "application/json")
			_, _ = w.Write([]byte(`{"id":"spotify-user-1","display_name":"Spotify Tester"}`))
		case r.URL.Path == "/v1/search":
			if q := r.URL.Query().Get("q"); q != "hello" {
				t.Fatalf("unexpected q: %s", q)
			}
			w.Header().Set("Content-Type", "application/json")
			_, _ = w.Write([]byte(`{"tracks":{"items":[{"id":"track-1","name":"Song A","duration_ms":225000,"preview_url":"https://preview.example/song-a.mp3","album":{"name":"Album A","images":[{"url":"https://img.example/song-a.jpg"}]},"artists":[{"name":"Artist A"}]}],"offset":0,"limit":20,"total":1,"next":null}}`))
		case r.URL.Path == "/v1/tracks/track-1":
			w.Header().Set("Content-Type", "application/json")
			_, _ = w.Write([]byte(`{"id":"track-1","name":"Song A","duration_ms":225000,"preview_url":"https://preview.example/song-a.mp3","album":{"name":"Album A","images":[{"url":"https://img.example/song-a.jpg"}]},"artists":[{"name":"Artist A"}]}`))
		default:
			http.NotFound(w, r)
		}
	}))
	defer providerServer.Close()

	spotifyProvider := music.NewSpotifyProvider(music.SpotifyConfig{
		ClientID:     "spotify-client",
		ClientSecret: "spotify-secret",
		RedirectURL:  "http://localhost:8000/api/v1/music-connections/spotify/callback",
		AuthorizeURL: providerServer.URL + "/authorize",
		TokenURL:     providerServer.URL + "/api/token",
		APIBaseURL:   providerServer.URL + "/v1",
	})
	appleProvider := music.NewAppleMusicProvider(music.AppleMusicConfig{
		ClientID:     "apple-client",
		RedirectURL:  "http://localhost:8000/api/v1/music-connections/apple_music/callback",
		AuthorizeURL: providerServer.URL + "/apple-authorize",
	})

	e := newTestServerWithProviders(t, db, "firebase-uid-music", []usecaseport.MusicProvider{spotifyProvider, appleProvider})

	authorizeReq, _ := authRequest(http.MethodGet, "/api/v1/music-connections/spotify/authorize", nil)
	authorizeRec := httptest.NewRecorder()
	e.ServeHTTP(authorizeRec, authorizeReq)
	if authorizeRec.Code != http.StatusOK {
		t.Fatalf("expected 200, got %d: %s", authorizeRec.Code, authorizeRec.Body.String())
	}
	var authorizeBody map[string]any
	if err := json.Unmarshal(authorizeRec.Body.Bytes(), &authorizeBody); err != nil {
		t.Fatalf("unmarshal authorize response: %v", err)
	}
	state := authorizeBody["state"].(string)
	if state == "" {
		t.Fatal("expected non-empty state")
	}

	callbackReq := httptest.NewRequest(http.MethodGet, "/api/v1/music-connections/spotify/callback?code=auth-code&state="+state, nil)
	callbackRec := httptest.NewRecorder()
	e.ServeHTTP(callbackRec, callbackReq)
	if callbackRec.Code != http.StatusFound {
		t.Fatalf("expected 302, got %d: %s", callbackRec.Code, callbackRec.Body.String())
	}
	if got := callbackRec.Header().Get("Location"); got != "digix://music-connections/spotify/callback?result=success" {
		t.Fatalf("unexpected callback location: %s", got)
	}

	listReq, _ := authRequest(http.MethodGet, "/api/v1/users/me/music-connections", nil)
	listRec := httptest.NewRecorder()
	e.ServeHTTP(listRec, listReq)
	if listRec.Code != http.StatusOK {
		t.Fatalf("expected 200, got %d: %s", listRec.Code, listRec.Body.String())
	}
	var listBody map[string]any
	if err := json.Unmarshal(listRec.Body.Bytes(), &listBody); err != nil {
		t.Fatalf("unmarshal list response: %v", err)
	}
	connections := listBody["music_connections"].([]any)
	if len(connections) != 1 {
		t.Fatalf("expected 1 connection, got %d", len(connections))
	}
	connection := connections[0].(map[string]any)
	if connection["provider"].(string) != "spotify" {
		t.Fatalf("expected spotify provider, got %v", connection["provider"])
	}
	if connection["provider_user_id"].(string) != "spotify-user-1" {
		t.Fatalf("expected provider user id spotify-user-1, got %v", connection["provider_user_id"])
	}

	searchReq, _ := authRequest(http.MethodGet, "/api/v1/tracks/search?q=hello", nil)
	searchRec := httptest.NewRecorder()
	e.ServeHTTP(searchRec, searchReq)
	if searchRec.Code != http.StatusOK {
		t.Fatalf("expected 200, got %d: %s", searchRec.Code, searchRec.Body.String())
	}
	var searchBody map[string]any
	if err := json.Unmarshal(searchRec.Body.Bytes(), &searchBody); err != nil {
		t.Fatalf("unmarshal search response: %v", err)
	}
	tracks := searchBody["tracks"].([]any)
	if len(tracks) != 1 {
		t.Fatalf("expected 1 track, got %d", len(tracks))
	}
	track := tracks[0].(map[string]any)
	if track["id"].(string) != "spotify:track:track-1" {
		t.Fatalf("unexpected track id: %v", track["id"])
	}
	if track["preview_url"].(string) != "https://preview.example/song-a.mp3" {
		t.Fatalf("unexpected preview_url: %v", track["preview_url"])
	}

	getTrackReq, _ := authRequest(http.MethodGet, "/api/v1/tracks/spotify:track:track-1", nil)
	getTrackRec := httptest.NewRecorder()
	e.ServeHTTP(getTrackRec, getTrackReq)
	if getTrackRec.Code != http.StatusOK {
		t.Fatalf("expected 200, got %d: %s", getTrackRec.Code, getTrackRec.Body.String())
	}

	deleteReq, _ := authRequest(http.MethodDelete, "/api/v1/users/me/music-connections/spotify", nil)
	deleteRec := httptest.NewRecorder()
	e.ServeHTTP(deleteRec, deleteReq)
	if deleteRec.Code != http.StatusNoContent {
		t.Fatalf("expected 204, got %d: %s", deleteRec.Code, deleteRec.Body.String())
	}

	var count int64
	if err := db.Model(&model.MusicConnection{}).Where("user_id = ?", user.ID).Count(&count).Error; err != nil {
		t.Fatalf("count music connections: %v", err)
	}
	if count != 0 {
		t.Fatalf("expected 0 connections after delete, got %d", count)
	}
}

func seedBleToken(t *testing.T, db *gorm.DB, userID string, token string, now time.Time) model.BleToken {
	t.Helper()
	bleToken := model.BleToken{
		ID:        uuid.NewString(),
		UserID:    userID,
		Token:     token,
		ValidFrom: now.Add(-time.Hour),
		ValidTo:   now.Add(time.Hour),
	}
	if err := db.Create(&bleToken).Error; err != nil {
		t.Fatalf("create ble token: %v", err)
	}
	return bleToken
}
