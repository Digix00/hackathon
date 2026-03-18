package request

// @name CreateEncounterRequest
type CreateEncounterRequest struct {
	TargetBleToken string `json:"target_ble_token"`
	Type           string `json:"type"`
	RSSI           *int   `json:"rssi"`
	OccurredAt     string `json:"occurred_at"`
}
