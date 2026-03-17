package handler

import (
	"bytes"
	"context"
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"os"
	"testing"
	"time"

	firebaseauth "firebase.google.com/go/v4/auth"
	"github.com/google/uuid"
	"github.com/labstack/echo/v4"
	"gorm.io/driver/postgres"
	"gorm.io/gorm"

	"hackathon/internal/infra/rdb"
	"hackathon/internal/infra/rdb/model"
	"hackathon/internal/usecase"
)

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

	dsn := os.Getenv("PG_TEST_DATABASE_URL")
	if dsn == "" {
		dsn = "postgres://postgres:postgres@127.0.0.1:5432/hackathon?sslmode=disable"
	}

	db, err := gorm.Open(postgres.Open(dsn), &gorm.Config{})
	if err != nil {
		t.Skipf("skip postgres-backed router test: postgres is not reachable (%v)", err)
	}

	sqlDB, err := db.DB()
	if err != nil {
		t.Fatalf("get sql.DB: %v", err)
	}

	ctx, cancel := context.WithTimeout(context.Background(), 2*time.Second)
	defer cancel()
	if err := sqlDB.PingContext(ctx); err != nil {
		t.Skipf("skip postgres-backed router test: postgres ping failed (%v)", err)
	}

	if err := rdb.Migrate(db); err != nil {
		t.Fatalf("migrate postgres: %v", err)
	}

	cleanupPostgresTestDataForRouter(t, db)
	t.Cleanup(func() {
		cleanupPostgresTestDataForRouter(t, db)
	})

	return db
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

	userRepo := rdb.NewUserRepository(db)
	userSettingsRepo := rdb.NewUserSettingsRepository(db)
	userDeviceRepo := rdb.NewUserDeviceRepository(db)
	blockRepo := rdb.NewBlockRepository(db)
	encounterRepo := rdb.NewEncounterRepository(db)
	trackRepo := rdb.NewUserCurrentTrackRepository(db)

	e := echo.New()
	RegisterRoutes(e, Dependencies{
		AuthTokenVerifier: testTokenVerifier{uid: authUID},
		AuthUserManager:   testAuthUserManager{},
		UserUsecase:       usecase.NewUserUsecase(userRepo, userSettingsRepo, blockRepo, encounterRepo, trackRepo),
		SettingsUsecase:   usecase.NewSettingsUsecase(userRepo, userSettingsRepo),
		PushTokenUsecase:  usecase.NewPushTokenUsecase(userRepo, userDeviceRepo),
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

	track := model.Track{ID: uuid.NewString(), ExternalID: "ext-del-1", Provider: "spotify", Title: "song", ArtistName: "artist"}
	if err := db.Create(&track).Error; err != nil {
		t.Fatalf("create track: %v", err)
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
