package response

// @name UserTrackResponse

type UserTrackResponse struct {
	Track PublicTrack `json:"track"`
}

// @name UserTrackListResponse

type UserTrackListResponse struct {
	Tracks     []PublicTrack       `json:"tracks"`
	Pagination UserTrackPagination `json:"pagination"`
}

// @name UserTrackPagination

type UserTrackPagination struct {
	NextCursor *string `json:"next_cursor"`
	HasMore    bool    `json:"has_more"`
}

// @name SharedTrackResponse

type SharedTrackResponse struct {
	SharedTrack *SharedTrack `json:"shared_track"`
}

// @name SharedTrack

type SharedTrack struct {
	ID         string  `json:"id"`
	Title      string  `json:"title"`
	ArtistName string  `json:"artist_name"`
	ArtworkURL *string `json:"artwork_url"`
	PreviewURL *string `json:"preview_url"`
	UpdatedAt  string  `json:"updated_at"`
}
