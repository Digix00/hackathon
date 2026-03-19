package request

type SubmitLyricRequest struct {
	EncounterID string `json:"encounter_id"`
	Content     string `json:"content"`
}
