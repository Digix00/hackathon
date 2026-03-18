package response

// @name MusicAuthorizeResponse

type MusicAuthorizeResponse struct {
	AuthorizeURL string `json:"authorize_url"`
	State        string `json:"state"`
}

// @name MusicConnectionsResponse

type MusicConnectionsResponse struct {
	MusicConnections []MusicConnection `json:"music_connections"`
}

// @name MusicConnection

type MusicConnection struct {
	Provider         string  `json:"provider" enums:"spotify,apple_music"`
	ProviderUserID   string  `json:"provider_user_id"`
	ProviderUsername *string `json:"provider_username"`
	ExpiresAt        *string `json:"expires_at"`
	UpdatedAt        string  `json:"updated_at"`
}

// @name TrackSearchResponse

type TrackSearchResponse struct {
	Tracks     []Track               `json:"tracks"`
	Pagination TrackSearchPagination `json:"pagination"`
}

// @name TrackSearchPagination

type TrackSearchPagination struct {
	NextCursor *string `json:"next_cursor"`
	HasMore    bool    `json:"has_more"`
}

// @name TrackResponse

type TrackResponse struct {
	Track Track `json:"track"`
}

// @name Track

type Track struct {
	ID         string  `json:"id"`
	Title      string  `json:"title"`
	ArtistName string  `json:"artist_name"`
	ArtworkURL *string `json:"artwork_url"`
	PreviewURL *string `json:"preview_url"`
	AlbumName  *string `json:"album_name,omitempty"`
	DurationMs *int    `json:"duration_ms,omitempty"`
}
