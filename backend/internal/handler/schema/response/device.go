package response

type DeviceResponse struct {
	Device Device `json:"device"`
}

type Device struct {
	ID        string `json:"id"`
	Platform  string `json:"platform"`
	DeviceID  string `json:"device_id"`
	Enabled   bool   `json:"enabled"`
	UpdatedAt string `json:"updated_at"`
}
