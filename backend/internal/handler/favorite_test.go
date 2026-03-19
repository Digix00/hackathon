package handler

import (
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"testing"

	"github.com/google/uuid"

	"hackathon/internal/infra/rdb/model"
)

func TestAddAndRemoveTrackFavorite(t *testing.T) {
	db := newTestDB(t)
	seedTestUser(t, db, "firebase-uid-track-fav")
	e := newTestServer(t, db, "firebase-uid-track-fav")

	track := model.Track{ID: uuid.NewString(), ExternalID: "fav-track-1", Provider: "spotify", Title: "Fav Song", ArtistName: "Artist"}
	if err := db.Create(&track).Error; err != nil {
		t.Fatalf("create track: %v", err)
	}

	trackID := "spotify:track:fav-track-1"

	// Add favorite - expect 201
	addReq, err := authRequest(http.MethodPost, "/api/v1/tracks/"+trackID+"/favorites", nil)
	if err != nil {
		t.Fatalf("new request: %v", err)
	}
	addRec := httptest.NewRecorder()
	e.ServeHTTP(addRec, addReq)
	if addRec.Code != http.StatusCreated {
		t.Fatalf("expected 201, got %d: %s", addRec.Code, addRec.Body.String())
	}

	var addBody map[string]any
	if err := json.Unmarshal(addRec.Body.Bytes(), &addBody); err != nil {
		t.Fatalf("unmarshal response: %v", err)
	}
	fav := addBody["favorite"].(map[string]any)
	if fav["resource_type"].(string) != "track" {
		t.Fatalf("expected resource_type track, got %v", fav["resource_type"])
	}
	if fav["resource_id"].(string) != trackID {
		t.Fatalf("expected resource_id %s, got %v", trackID, fav["resource_id"])
	}
	if fav["favorited"].(bool) != true {
		t.Fatalf("expected favorited true, got %v", fav["favorited"])
	}

	// Add same favorite again - expect 200 (idempotent)
	addReq2, err := authRequest(http.MethodPost, "/api/v1/tracks/"+trackID+"/favorites", nil)
	if err != nil {
		t.Fatalf("new request 2: %v", err)
	}
	addRec2 := httptest.NewRecorder()
	e.ServeHTTP(addRec2, addReq2)
	if addRec2.Code != http.StatusOK {
		t.Fatalf("expected 200 on duplicate, got %d: %s", addRec2.Code, addRec2.Body.String())
	}

	// Verify only one record exists
	var count int64
	if err := db.Model(&model.TrackFavorite{}).Where("track_id = ?", track.ID).Count(&count).Error; err != nil {
		t.Fatalf("count track favorites: %v", err)
	}
	if count != 1 {
		t.Fatalf("expected 1 track favorite, got %d", count)
	}

	// Remove favorite
	removeReq, err := authRequest(http.MethodDelete, "/api/v1/tracks/"+trackID+"/favorites", nil)
	if err != nil {
		t.Fatalf("new request: %v", err)
	}
	removeRec := httptest.NewRecorder()
	e.ServeHTTP(removeRec, removeReq)
	if removeRec.Code != http.StatusNoContent {
		t.Fatalf("expected 204, got %d: %s", removeRec.Code, removeRec.Body.String())
	}

	if err := db.Model(&model.TrackFavorite{}).Where("track_id = ?", track.ID).Count(&count).Error; err != nil {
		t.Fatalf("count track favorites after remove: %v", err)
	}
	if count != 0 {
		t.Fatalf("expected 0 track favorites after remove, got %d", count)
	}
}

func TestAddTrackFavoriteNotFound(t *testing.T) {
	db := newTestDB(t)
	seedTestUser(t, db, "firebase-uid-track-fav-404")
	e := newTestServer(t, db, "firebase-uid-track-fav-404")

	req, err := authRequest(http.MethodPost, "/api/v1/tracks/spotify:track:nonexistent/favorites", nil)
	if err != nil {
		t.Fatalf("new request: %v", err)
	}
	rec := httptest.NewRecorder()
	e.ServeHTTP(rec, req)

	if rec.Code != http.StatusNotFound {
		t.Fatalf("expected 404, got %d: %s", rec.Code, rec.Body.String())
	}
}

func TestRemoveTrackFavoriteNotFound(t *testing.T) {
	db := newTestDB(t)
	seedTestUser(t, db, "firebase-uid-track-fav-rm-404")
	e := newTestServer(t, db, "firebase-uid-track-fav-rm-404")

	// Create track but don't favorite it
	track := model.Track{ID: uuid.NewString(), ExternalID: "fav-track-rm", Provider: "spotify", Title: "Song", ArtistName: "Artist"}
	if err := db.Create(&track).Error; err != nil {
		t.Fatalf("create track: %v", err)
	}

	req, err := authRequest(http.MethodDelete, "/api/v1/tracks/spotify:track:fav-track-rm/favorites", nil)
	if err != nil {
		t.Fatalf("new request: %v", err)
	}
	rec := httptest.NewRecorder()
	e.ServeHTTP(rec, req)

	if rec.Code != http.StatusNotFound {
		t.Fatalf("expected 404, got %d: %s", rec.Code, rec.Body.String())
	}
}

func TestListTrackFavorites(t *testing.T) {
	db := newTestDB(t)
	user := seedTestUser(t, db, "firebase-uid-list-track-fav")
	e := newTestServer(t, db, "firebase-uid-list-track-fav")

	track1 := model.Track{ID: uuid.NewString(), ExternalID: "list-fav-1", Provider: "spotify", Title: "Song A", ArtistName: "Artist A"}
	track2 := model.Track{ID: uuid.NewString(), ExternalID: "list-fav-2", Provider: "spotify", Title: "Song B", ArtistName: "Artist B"}
	if err := db.Create(&track1).Error; err != nil {
		t.Fatalf("create track1: %v", err)
	}
	if err := db.Create(&track2).Error; err != nil {
		t.Fatalf("create track2: %v", err)
	}
	if err := db.Create(&model.TrackFavorite{ID: uuid.NewString(), UserID: user.ID, TrackID: track1.ID}).Error; err != nil {
		t.Fatalf("create favorite1: %v", err)
	}
	if err := db.Create(&model.TrackFavorite{ID: uuid.NewString(), UserID: user.ID, TrackID: track2.ID}).Error; err != nil {
		t.Fatalf("create favorite2: %v", err)
	}

	req, err := authRequest(http.MethodGet, "/api/v1/users/me/track-favorites", nil)
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
	tracks := body["tracks"].([]any)
	if len(tracks) != 2 {
		t.Fatalf("expected 2 tracks, got %d", len(tracks))
	}
	pagination := body["pagination"].(map[string]any)
	if pagination["has_more"].(bool) != false {
		t.Fatalf("expected has_more false, got %v", pagination["has_more"])
	}
}

func TestListTrackFavoritesPagination(t *testing.T) {
	db := newTestDB(t)
	user := seedTestUser(t, db, "firebase-uid-list-track-fav-page")
	e := newTestServer(t, db, "firebase-uid-list-track-fav-page")

	for i := 0; i < 3; i++ {
		extID := uuid.NewString()
		track := model.Track{ID: uuid.NewString(), ExternalID: extID, Provider: "spotify", Title: "Song", ArtistName: "Artist"}
		if err := db.Create(&track).Error; err != nil {
			t.Fatalf("create track: %v", err)
		}
		if err := db.Create(&model.TrackFavorite{ID: uuid.NewString(), UserID: user.ID, TrackID: track.ID}).Error; err != nil {
			t.Fatalf("create favorite: %v", err)
		}
	}

	req, err := authRequest(http.MethodGet, "/api/v1/users/me/track-favorites?limit=2", nil)
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
	tracks := body["tracks"].([]any)
	if len(tracks) != 2 {
		t.Fatalf("expected 2 tracks, got %d", len(tracks))
	}
	pagination := body["pagination"].(map[string]any)
	if pagination["has_more"].(bool) != true {
		t.Fatalf("expected has_more true")
	}
	if pagination["next_cursor"] == nil {
		t.Fatalf("expected next_cursor to be present")
	}
}

func TestListPlaylistFavorites(t *testing.T) {
	db := newTestDB(t)
	owner := seedTestUser(t, db, "firebase-uid-pl-fav-owner")
	user := seedTestUser(t, db, "firebase-uid-pl-fav-user")
	e := newTestServer(t, db, "firebase-uid-pl-fav-user")

	playlist1 := model.Playlist{ID: uuid.NewString(), UserID: owner.ID, Name: "Playlist 1", IsPublic: true}
	playlist2 := model.Playlist{ID: uuid.NewString(), UserID: owner.ID, Name: "Playlist 2", IsPublic: true}
	if err := db.Create(&playlist1).Error; err != nil {
		t.Fatalf("create playlist1: %v", err)
	}
	if err := db.Create(&playlist2).Error; err != nil {
		t.Fatalf("create playlist2: %v", err)
	}
	if err := db.Create(&model.PlaylistFavorite{ID: uuid.NewString(), UserID: user.ID, PlaylistID: playlist1.ID}).Error; err != nil {
		t.Fatalf("create favorite1: %v", err)
	}
	if err := db.Create(&model.PlaylistFavorite{ID: uuid.NewString(), UserID: user.ID, PlaylistID: playlist2.ID}).Error; err != nil {
		t.Fatalf("create favorite2: %v", err)
	}

	req, err := authRequest(http.MethodGet, "/api/v1/users/me/playlist-favorites", nil)
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
	pagination := body["pagination"].(map[string]any)
	if pagination["has_more"].(bool) != false {
		t.Fatalf("expected has_more false")
	}
}

func TestListPlaylistFavoritesPagination(t *testing.T) {
	db := newTestDB(t)
	owner := seedTestUser(t, db, "firebase-uid-pl-fav-page-owner")
	user := seedTestUser(t, db, "firebase-uid-pl-fav-page-user")
	e := newTestServer(t, db, "firebase-uid-pl-fav-page-user")

	for i := 0; i < 3; i++ {
		pl := model.Playlist{ID: uuid.NewString(), UserID: owner.ID, Name: "Playlist", IsPublic: true}
		if err := db.Create(&pl).Error; err != nil {
			t.Fatalf("create playlist: %v", err)
		}
		if err := db.Create(&model.PlaylistFavorite{ID: uuid.NewString(), UserID: user.ID, PlaylistID: pl.ID}).Error; err != nil {
			t.Fatalf("create favorite: %v", err)
		}
	}

	req, err := authRequest(http.MethodGet, "/api/v1/users/me/playlist-favorites?limit=2", nil)
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
	pagination := body["pagination"].(map[string]any)
	if pagination["has_more"].(bool) != true {
		t.Fatalf("expected has_more true")
	}
	if pagination["next_cursor"] == nil {
		t.Fatalf("expected next_cursor")
	}

	// Follow next cursor
	nextCursor := pagination["next_cursor"].(string)
	req2, err := authRequest(http.MethodGet, "/api/v1/users/me/playlist-favorites?limit=2&cursor="+nextCursor, nil)
	if err != nil {
		t.Fatalf("new request 2: %v", err)
	}
	rec2 := httptest.NewRecorder()
	e.ServeHTTP(rec2, req2)
	if rec2.Code != http.StatusOK {
		t.Fatalf("expected 200, got %d: %s", rec2.Code, rec2.Body.String())
	}
	var body2 map[string]any
	if err := json.Unmarshal(rec2.Body.Bytes(), &body2); err != nil {
		t.Fatalf("unmarshal response 2: %v", err)
	}
	playlists2 := body2["playlists"].([]any)
	if len(playlists2) != 1 {
		t.Fatalf("expected 1 playlist on second page, got %d", len(playlists2))
	}
	pagination2 := body2["pagination"].(map[string]any)
	if pagination2["has_more"].(bool) != false {
		t.Fatalf("expected has_more false on second page")
	}
}
