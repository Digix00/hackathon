package request

type CreatePushTokenRequest struct {
	Platform   string  `json:"platform"`
	DeviceID   string  `json:"device_id"`
	PushToken  string  `json:"push_token"`
	AppVersion *string `json:"app_version"`
}

type UpdatePushTokenRequest struct {
	PushToken  *string `json:"push_token"`
	Enabled    *bool   `json:"enabled"`
	AppVersion *string `json:"app_version"`
}
