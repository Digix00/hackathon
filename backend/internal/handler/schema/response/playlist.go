package response

// PlaylistTrack はプレイリスト内のトラック情報。
type PlaylistTrack struct {
	ID         string  `json:"id"          validate:"required"`
	TrackID    string  `json:"track_id"    validate:"required"`
	Title      string  `json:"title"       validate:"required"`
	ArtistName string  `json:"artist_name" validate:"required"`
	ArtworkURL *string `json:"artwork_url"`
	SortOrder  int     `json:"sort_order"  validate:"required"`
	CreatedAt  string  `json:"created_at"  validate:"required"`
}

// Playlist はプレイリスト情報。
type Playlist struct {
	ID          string          `json:"id"          validate:"required"`
	UserID      string          `json:"user_id"     validate:"required"`
	Name        string          `json:"name"        validate:"required"`
	Description *string         `json:"description"`
	IsPublic    bool            `json:"is_public"   validate:"required"`
	Tracks      []PlaylistTrack `json:"tracks"      validate:"required"`
	CreatedAt   string          `json:"created_at"  validate:"required"`
	UpdatedAt   string          `json:"updated_at"  validate:"required"`
}

// PlaylistResponse はプレイリスト単体のレスポンス。
// @name PlaylistResponse
type PlaylistResponse struct {
	Playlist Playlist `json:"playlist" validate:"required"`
}

// PlaylistListResponse はプレイリスト一覧のレスポンス。
// @name PlaylistListResponse
type PlaylistListResponse struct {
	Playlists []Playlist `json:"playlists" validate:"required"`
}
