package response

// @name DeviceResponse
type DeviceResponse struct {
	Device Device `json:"device"`
}

// @name Device
type Device struct {
	ID        string `json:"id"`
	Platform  string `json:"platform" enums:"ios,android"`
	DeviceID  string `json:"device_id"`
	Enabled   bool   `json:"enabled"`
	UpdatedAt string `json:"updated_at"`
}
