package response

// @name LocationResponse
type LocationResponse struct {
	EncounterCount int                `json:"encounter_count"`
	Encounters     []EncounterSummary `json:"encounters"`
}
