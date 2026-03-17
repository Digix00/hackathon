package request

// @name PostLyricRequest
type PostLyricRequest struct {
	EncounterID string `json:"encounter_id"`
	Content     string `json:"content"`
}
