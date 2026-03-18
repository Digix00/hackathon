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
