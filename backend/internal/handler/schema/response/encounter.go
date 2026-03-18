package response

// @name EncounterResponse
type EncounterResponse struct {
	Encounter EncounterSummary `json:"encounter"`
}

// @name EncounterListResponse
type EncounterListResponse struct {
	Encounters []EncounterListItem `json:"encounters"`
	Pagination Pagination          `json:"pagination"`
}

// @name EncounterDetailResponse
type EncounterDetailResponse struct {
	Encounter EncounterDetail `json:"encounter"`
}

// @name EncounterSummary
type EncounterSummary struct {
	ID         string        `json:"id"`
	Type       string        `json:"type" enums:"ble,location"`
	User       EncounterUser `json:"user"`
	OccurredAt string        `json:"occurred_at"`
}

// @name EncounterListItem
type EncounterListItem struct {
	ID         string           `json:"id"`
	Type       string           `json:"type" enums:"ble,location"`
	User       EncounterUser    `json:"user"`
	IsRead     bool             `json:"is_read"`
	Tracks     []EncounterTrack `json:"tracks"`
	OccurredAt string           `json:"occurred_at"`
}

// @name EncounterDetail
type EncounterDetail struct {
	ID         string           `json:"id"`
	Type       string           `json:"type" enums:"ble,location"`
	User       EncounterUser    `json:"user"`
	OccurredAt string           `json:"occurred_at"`
	Tracks     []EncounterTrack `json:"tracks"`
}

// @name EncounterUser
type EncounterUser struct {
	ID          string  `json:"id"`
	DisplayName string  `json:"display_name"`
	AvatarURL   *string `json:"avatar_url"`
}

// @name EncounterTrack
type EncounterTrack struct {
	ID         string  `json:"id"`
	Title      string  `json:"title"`
	ArtistName string  `json:"artist_name"`
	ArtworkURL *string `json:"artwork_url"`
	PreviewURL *string `json:"preview_url"`
}
