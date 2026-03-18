package handler

import (
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"testing"

	"github.com/google/uuid"

	"hackathon/internal/infra/rdb/model"
)

func TestCreatePlaylist(t *testing.T) {
	db := newTestDB(t)
	seedTestUser(t, db, "firebase-uid-playlist-create")
	e := newTestServer(t, db, "firebase-uid-playlist-create")

	req, err := authRequest(http.MethodPost, "/api/v1/playlists", map[string]any{
		"name":      "My Playlist",
		"is_public": true,
	})
	if err != nil {
		t.Fatalf("new request: %v", err)
	}
	rec := httptest.NewRecorder()
	e.ServeHTTP(rec, req)

	if rec.Code != http.StatusCreated {
		t.Fatalf("expected 201, got %d: %s", rec.Code, rec.Body.String())
	}

	var body map[string]any
	if err := json.Unmarshal(rec.Body.Bytes(), &body); err != nil {
		t.Fatalf("unmarshal response: %v", err)
	}
	playlist := body["playlist"].(map[string]any)
	if playlist["name"].(string) != "My Playlist" {
		t.Fatalf("expected name My Playlist, got %v", playlist["name"])
	}
	if playlist["is_public"].(bool) != true {
		t.Fatalf("expected is_public true, got %v", playlist["is_public"])
	}
	if playlist["tracks"] == nil {
		t.Fatalf("expected tracks field to be present")
	}
}

func TestCreatePlaylistRequiresName(t *testing.T) {
	db := newTestDB(t)
	seedTestUser(t, db, "firebase-uid-playlist-noname")
	e := newTestServer(t, db, "firebase-uid-playlist-noname")

	req, err := authRequest(http.MethodPost, "/api/v1/playlists", map[string]any{
		"is_public": true,
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

func TestGetMyPlaylists(t *testing.T) {
	db := newTestDB(t)
	user := seedTestUser(t, db, "firebase-uid-playlist-list")
	e := newTestServer(t, db, "firebase-uid-playlist-list")

	playlist1 := model.Playlist{ID: uuid.NewString(), UserID: user.ID, Name: "Playlist A", IsPublic: true}
	playlist2 := model.Playlist{ID: uuid.NewString(), UserID: user.ID, Name: "Playlist B", IsPublic: true}
	if err := db.Create(&playlist1).Error; err != nil {
		t.Fatalf("create playlist1: %v", err)
	}
	if err := db.Create(&playlist2).Error; err != nil {
		t.Fatalf("create playlist2: %v", err)
	}
	if err := db.Model(&playlist2).UpdateColumn("is_public", false).Error; err != nil {
		t.Fatalf("set playlist2 private: %v", err)
	}

	req, err := authRequest(http.MethodGet, "/api/v1/playlists/me", nil)
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
	playlists := body["playlists"].([]any)
	if len(playlists) != 2 {
		t.Fatalf("expected 2 playlists, got %d", len(playlists))
	}
}

func TestGetPlaylist(t *testing.T) {
	db := newTestDB(t)
	user := seedTestUser(t, db, "firebase-uid-playlist-get")
	e := newTestServer(t, db, "firebase-uid-playlist-get")

	playlist := model.Playlist{ID: uuid.NewString(), UserID: user.ID, Name: "Test Playlist", IsPublic: true}
	if err := db.Create(&playlist).Error; err != nil {
		t.Fatalf("create playlist: %v", err)
	}

	req, err := authRequest(http.MethodGet, "/api/v1/playlists/"+playlist.ID, nil)
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
	got := body["playlist"].(map[string]any)
	if got["id"].(string) != playlist.ID {
		t.Fatalf("expected playlist ID %s, got %v", playlist.ID, got["id"])
	}
}

func TestGetPrivatePlaylistForbiddenForOtherUser(t *testing.T) {
	db := newTestDB(t)
	owner := seedTestUser(t, db, "firebase-uid-playlist-owner")
	seedTestUser(t, db, "firebase-uid-playlist-other")

	playlist := model.Playlist{ID: uuid.NewString(), UserID: owner.ID, Name: "Private Playlist", IsPublic: true}
	if err := db.Create(&playlist).Error; err != nil {
		t.Fatalf("create playlist: %v", err)
	}
	if err := db.Model(&playlist).UpdateColumn("is_public", false).Error; err != nil {
		t.Fatalf("set playlist private: %v", err)
	}

	e := newTestServer(t, db, "firebase-uid-playlist-other")
	req, err := authRequest(http.MethodGet, "/api/v1/playlists/"+playlist.ID, nil)
	if err != nil {
		t.Fatalf("new request: %v", err)
	}
	rec := httptest.NewRecorder()
	e.ServeHTTP(rec, req)

	if rec.Code != http.StatusNotFound {
		t.Fatalf("expected 404, got %d: %s", rec.Code, rec.Body.String())
	}
}

func TestUpdatePlaylist(t *testing.T) {
	db := newTestDB(t)
	user := seedTestUser(t, db, "firebase-uid-playlist-update")
	e := newTestServer(t, db, "firebase-uid-playlist-update")

	playlist := model.Playlist{ID: uuid.NewString(), UserID: user.ID, Name: "Old Name", IsPublic: true}
	if err := db.Create(&playlist).Error; err != nil {
		t.Fatalf("create playlist: %v", err)
	}

	newName := "New Name"
	req, err := authRequest(http.MethodPatch, "/api/v1/playlists/"+playlist.ID, map[string]any{
		"name": newName,
	})
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
	got := body["playlist"].(map[string]any)
	if got["name"].(string) != newName {
		t.Fatalf("expected name %s, got %v", newName, got["name"])
	}
}

func TestUpdatePlaylistForbiddenForNonOwner(t *testing.T) {
	db := newTestDB(t)
	owner := seedTestUser(t, db, "firebase-uid-patchown-owner")
	seedTestUser(t, db, "firebase-uid-patchown-other")

	playlist := model.Playlist{ID: uuid.NewString(), UserID: owner.ID, Name: "Owner Playlist", IsPublic: true}
	if err := db.Create(&playlist).Error; err != nil {
		t.Fatalf("create playlist: %v", err)
	}

	e := newTestServer(t, db, "firebase-uid-patchown-other")
	req, err := authRequest(http.MethodPatch, "/api/v1/playlists/"+playlist.ID, map[string]any{
		"name": "Hijacked",
	})
	if err != nil {
		t.Fatalf("new request: %v", err)
	}
	rec := httptest.NewRecorder()
	e.ServeHTTP(rec, req)

	if rec.Code != http.StatusForbidden {
		t.Fatalf("expected 403, got %d: %s", rec.Code, rec.Body.String())
	}
}

func TestDeletePlaylist(t *testing.T) {
	db := newTestDB(t)
	user := seedTestUser(t, db, "firebase-uid-playlist-delete")
	e := newTestServer(t, db, "firebase-uid-playlist-delete")

	playlist := model.Playlist{ID: uuid.NewString(), UserID: user.ID, Name: "To Delete", IsPublic: true}
	if err := db.Create(&playlist).Error; err != nil {
		t.Fatalf("create playlist: %v", err)
	}

	req, err := authRequest(http.MethodDelete, "/api/v1/playlists/"+playlist.ID, nil)
	if err != nil {
		t.Fatalf("new request: %v", err)
	}
	rec := httptest.NewRecorder()
	e.ServeHTTP(rec, req)

	if rec.Code != http.StatusNoContent {
		t.Fatalf("expected 204, got %d: %s", rec.Code, rec.Body.String())
	}

	getReq, _ := authRequest(http.MethodGet, "/api/v1/playlists/"+playlist.ID, nil)
	getRec := httptest.NewRecorder()
	e.ServeHTTP(getRec, getReq)
	if getRec.Code != http.StatusNotFound {
		t.Fatalf("expected 404 after delete, got %d: %s", getRec.Code, getRec.Body.String())
	}
}

func TestAddAndRemovePlaylistTrack(t *testing.T) {
	db := newTestDB(t)
	user := seedTestUser(t, db, "firebase-uid-playlist-track")
	e := newTestServer(t, db, "firebase-uid-playlist-track")

	track := model.Track{ID: uuid.NewString(), ExternalID: "ext-pl-1", Provider: "spotify", Title: "Song", ArtistName: "Artist"}
	if err := db.Create(&track).Error; err != nil {
		t.Fatalf("create track: %v", err)
	}

	playlist := model.Playlist{ID: uuid.NewString(), UserID: user.ID, Name: "My Tracks", IsPublic: true}
	if err := db.Create(&playlist).Error; err != nil {
		t.Fatalf("create playlist: %v", err)
	}

	addReq, err := authRequest(http.MethodPost, "/api/v1/playlists/"+playlist.ID+"/tracks", map[string]any{
		"track_id": track.ID,
	})
	if err != nil {
		t.Fatalf("new request: %v", err)
	}
	addRec := httptest.NewRecorder()
	e.ServeHTTP(addRec, addReq)
	if addRec.Code != http.StatusNoContent {
		t.Fatalf("expected 204, got %d: %s", addRec.Code, addRec.Body.String())
	}

	getReq, _ := authRequest(http.MethodGet, "/api/v1/playlists/"+playlist.ID, nil)
	getRec := httptest.NewRecorder()
	e.ServeHTTP(getRec, getReq)
	if getRec.Code != http.StatusOK {
		t.Fatalf("expected 200, got %d: %s", getRec.Code, getRec.Body.String())
	}
	var getBody map[string]any
	if err := json.Unmarshal(getRec.Body.Bytes(), &getBody); err != nil {
		t.Fatalf("unmarshal response: %v", err)
	}
	tracks := getBody["playlist"].(map[string]any)["tracks"].([]any)
	if len(tracks) != 1 {
		t.Fatalf("expected 1 track, got %d", len(tracks))
	}

	removeReq, err := authRequest(http.MethodDelete, "/api/v1/playlists/"+playlist.ID+"/tracks/"+track.ID, nil)
	if err != nil {
		t.Fatalf("new request: %v", err)
	}
	removeRec := httptest.NewRecorder()
	e.ServeHTTP(removeRec, removeReq)
	if removeRec.Code != http.StatusNoContent {
		t.Fatalf("expected 204, got %d: %s", removeRec.Code, removeRec.Body.String())
	}
}

func TestAddAndRemovePlaylistFavorite(t *testing.T) {
	db := newTestDB(t)
	owner := seedTestUser(t, db, "firebase-uid-playlist-fav-owner")
	seedTestUser(t, db, "firebase-uid-playlist-fav-user")

	playlist := model.Playlist{ID: uuid.NewString(), UserID: owner.ID, Name: "Fav Playlist", IsPublic: true}
	if err := db.Create(&playlist).Error; err != nil {
		t.Fatalf("create playlist: %v", err)
	}

	e := newTestServer(t, db, "firebase-uid-playlist-fav-user")

	addReq, err := authRequest(http.MethodPost, "/api/v1/playlists/"+playlist.ID+"/favorites", nil)
	if err != nil {
		t.Fatalf("new request: %v", err)
	}
	addRec := httptest.NewRecorder()
	e.ServeHTTP(addRec, addReq)
	if addRec.Code != http.StatusNoContent {
		t.Fatalf("expected 204, got %d: %s", addRec.Code, addRec.Body.String())
	}

	var count int64
	if err := db.Model(&model.PlaylistFavorite{}).Where("playlist_id = ?", playlist.ID).Count(&count).Error; err != nil {
		t.Fatalf("count favorites: %v", err)
	}
	if count != 1 {
		t.Fatalf("expected 1 favorite, got %d", count)
	}

	removeReq, err := authRequest(http.MethodDelete, "/api/v1/playlists/"+playlist.ID+"/favorites", nil)
	if err != nil {
		t.Fatalf("new request: %v", err)
	}
	removeRec := httptest.NewRecorder()
	e.ServeHTTP(removeRec, removeReq)
	if removeRec.Code != http.StatusNoContent {
		t.Fatalf("expected 204, got %d: %s", removeRec.Code, removeRec.Body.String())
	}

	if err := db.Model(&model.PlaylistFavorite{}).Where("playlist_id = ?", playlist.ID).Count(&count).Error; err != nil {
		t.Fatalf("count favorites after remove: %v", err)
	}
	if count != 0 {
		t.Fatalf("expected 0 favorites after remove, got %d", count)
	}
}

func TestFavoritePrivatePlaylistForbiddenForOtherUser(t *testing.T) {
	db := newTestDB(t)
	owner := seedTestUser(t, db, "firebase-uid-fav-priv-owner")
	seedTestUser(t, db, "firebase-uid-fav-priv-other")

	playlist := model.Playlist{ID: uuid.NewString(), UserID: owner.ID, Name: "Private", IsPublic: true}
	if err := db.Create(&playlist).Error; err != nil {
		t.Fatalf("create playlist: %v", err)
	}
	if err := db.Model(&playlist).UpdateColumn("is_public", false).Error; err != nil {
		t.Fatalf("set playlist private: %v", err)
	}

	e := newTestServer(t, db, "firebase-uid-fav-priv-other")
	req, err := authRequest(http.MethodPost, "/api/v1/playlists/"+playlist.ID+"/favorites", nil)
	if err != nil {
		t.Fatalf("new request: %v", err)
	}
	rec := httptest.NewRecorder()
	e.ServeHTTP(rec, req)

	if rec.Code != http.StatusNotFound {
		t.Fatalf("expected 404, got %d: %s", rec.Code, rec.Body.String())
	}
}

func TestDuplicatePlaylistFavorite(t *testing.T) {
	db := newTestDB(t)
	owner := seedTestUser(t, db, "firebase-uid-dup-fav-owner")
	seedTestUser(t, db, "firebase-uid-dup-fav-user")

	playlist := model.Playlist{ID: uuid.NewString(), UserID: owner.ID, Name: "Fav Playlist", IsPublic: true}
	if err := db.Create(&playlist).Error; err != nil {
		t.Fatalf("create playlist: %v", err)
	}

	e := newTestServer(t, db, "firebase-uid-dup-fav-user")

	// Add favorite first time
	addReq1, err := authRequest(http.MethodPost, "/api/v1/playlists/"+playlist.ID+"/favorites", nil)
	if err != nil {
		t.Fatalf("new request 1: %v", err)
	}
	addRec1 := httptest.NewRecorder()
	e.ServeHTTP(addRec1, addReq1)
	if addRec1.Code != http.StatusNoContent {
		t.Fatalf("expected 204 first time, got %d: %s", addRec1.Code, addRec1.Body.String())
	}

	// Add favorite second time (duplicate)
	addReq2, err := authRequest(http.MethodPost, "/api/v1/playlists/"+playlist.ID+"/favorites", nil)
	if err != nil {
		t.Fatalf("new request 2: %v", err)
	}
	addRec2 := httptest.NewRecorder()
	e.ServeHTTP(addRec2, addReq2)

	if addRec2.Code != http.StatusConflict {
		t.Fatalf("expected 409 Conflict for duplicate favorite, got %d: %s", addRec2.Code, addRec2.Body.String())
	}
}

func TestDuplicatePlaylistTrack(t *testing.T) {
	db := newTestDB(t)
	user := seedTestUser(t, db, "firebase-uid-dup-track")
	e := newTestServer(t, db, "firebase-uid-dup-track")

	track := model.Track{ID: uuid.NewString(), ExternalID: "ext-pl-dup", Provider: "spotify", Title: "Song", ArtistName: "Artist"}
	if err := db.Create(&track).Error; err != nil {
		t.Fatalf("create track: %v", err)
	}

	playlist := model.Playlist{ID: uuid.NewString(), UserID: user.ID, Name: "My Tracks", IsPublic: true}
	if err := db.Create(&playlist).Error; err != nil {
		t.Fatalf("create playlist: %v", err)
	}

	// Add track first time
	addReq1, err := authRequest(http.MethodPost, "/api/v1/playlists/"+playlist.ID+"/tracks", map[string]any{
		"track_id": track.ID,
	})
	if err != nil {
		t.Fatalf("new request 1: %v", err)
	}
	addRec1 := httptest.NewRecorder()
	e.ServeHTTP(addRec1, addReq1)
	if addRec1.Code != http.StatusNoContent {
		t.Fatalf("expected 204 first time, got %d: %s", addRec1.Code, addRec1.Body.String())
	}

	// Add track second time (duplicate)
	addReq2, err := authRequest(http.MethodPost, "/api/v1/playlists/"+playlist.ID+"/tracks", map[string]any{
		"track_id": track.ID,
	})
	if err != nil {
		t.Fatalf("new request 2: %v", err)
	}
	addRec2 := httptest.NewRecorder()
	e.ServeHTTP(addRec2, addReq2)

	if addRec2.Code != http.StatusConflict {
		t.Fatalf("expected 409 Conflict for duplicate track, got %d: %s", addRec2.Code, addRec2.Body.String())
	}
}

func TestAddPlaylistTrackWithInvalidTrackID(t *testing.T) {
	db := newTestDB(t)
	user := seedTestUser(t, db, "firebase-uid-invalid-track")
	e := newTestServer(t, db, "firebase-uid-invalid-track")

	playlist := model.Playlist{ID: uuid.NewString(), UserID: user.ID, Name: "My Tracks", IsPublic: true}
	if err := db.Create(&playlist).Error; err != nil {
		t.Fatalf("create playlist: %v", err)
	}

	// Add non-existent track
	addReq, err := authRequest(http.MethodPost, "/api/v1/playlists/"+playlist.ID+"/tracks", map[string]any{
		"track_id": "non-existent-track-id",
	})
	if err != nil {
		t.Fatalf("new request: %v", err)
	}
	addRec := httptest.NewRecorder()
	e.ServeHTTP(addRec, addReq)

	if addRec.Code != http.StatusBadRequest {
		t.Fatalf("expected 400 Bad Request for invalid track ID, got %d: %s", addRec.Code, addRec.Body.String())
	}
}
