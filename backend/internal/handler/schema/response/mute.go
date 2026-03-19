package response

// @name MuteResponse
type MuteResponse struct {
	Mute Mute `json:"mute"`
}

// @name Mute
type Mute struct {
	ID           string `json:"id"`
	TargetUserID string `json:"target_user_id"`
	CreatedAt    string `json:"created_at"`
}

// @name MuteListResponse
type MuteListResponse struct {
	Mutes      []Mute             `json:"mutes"`
	Pagination MuteListPagination `json:"pagination"`
}

// @name MuteListPagination
type MuteListPagination struct {
	NextCursor *string `json:"next_cursor"`
	HasMore    bool    `json:"has_more"`
}
