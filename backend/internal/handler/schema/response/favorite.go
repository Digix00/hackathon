package response

// @name TrackFavoriteResponse

type TrackFavoriteResponse struct {
	Favorite TrackFavorite `json:"favorite"`
}

// @name TrackFavorite

type TrackFavorite struct {
	ResourceType string `json:"resource_type"`
	ResourceID   string `json:"resource_id"`
	Favorited    bool   `json:"favorited"`
	CreatedAt    string `json:"created_at"`
}

// @name TrackFavoriteListResponse

type TrackFavoriteListResponse struct {
	Tracks     []PublicTrack       `json:"tracks"`
	Pagination UserTrackPagination `json:"pagination"`
}

// @name PlaylistFavoriteListResponse

type PlaylistFavoriteListResponse struct {
	Playlists  []PlaylistSummary   `json:"playlists"`
	Pagination UserTrackPagination `json:"pagination"`
}
