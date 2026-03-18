package request

// @name CreatePlaylistRequest
type CreatePlaylistRequest struct {
	Name        string  `json:"name"`
	Description *string `json:"description"`
	IsPublic    *bool   `json:"is_public"`
}

// @name UpdatePlaylistRequest
type UpdatePlaylistRequest struct {
	Name        *string `json:"name"`
	Description *string `json:"description"`
	IsPublic    *bool   `json:"is_public"`
}

// @name AddPlaylistTrackRequest
type AddPlaylistTrackRequest struct {
	TrackID string `json:"track_id"`
}
