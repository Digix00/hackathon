package response

type BleTokenResponse struct {
	BleToken BleToken `json:"ble_token" validate:"required"`
}

type BleToken struct {
	Token     string `json:"token"      validate:"required"`
	ExpiresAt string `json:"expires_at" validate:"required"`
}

// BleTokenUserResponse is the response for GET /ble-tokens/{token}/user.
// Only minimal fields are exposed since BLE tokens can be scanned by any nearby device.
type BleTokenUserResponse struct {
	User BleTokenUser `json:"user" validate:"required"`
}

type BleTokenUser struct {
	ID          string  `json:"id"           validate:"required"`
	DisplayName string  `json:"display_name" validate:"required"`
	AvatarURL   *string `json:"avatar_url"`
}
