package request

// @name AddUserTrackRequest
type AddUserTrackRequest struct {
	TrackID string `json:"track_id"`
}

// @name UpsertSharedTrackRequest
type UpsertSharedTrackRequest struct {
	TrackID string `json:"track_id"`
}
