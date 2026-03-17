package response

import "time"

type BleTokenResponse struct {
	BleToken BleToken `json:"ble_token"`
}

type BleToken struct {
	Token     string    `json:"token"`
	ExpiresAt time.Time `json:"expires_at"`
}

// BleTokenUserResponse is the response for GET /ble-tokens/{token}/user.
// Only minimal fields are exposed since BLE tokens can be scanned by any nearby device.
type BleTokenUserResponse struct {
	User BleTokenUser `json:"user"`
}

type BleTokenUser struct {
	ID          string  `json:"id"`
	DisplayName string  `json:"display_name"`
	AvatarURL   *string `json:"avatar_url"`
}
