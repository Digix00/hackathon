package response

import "time"

type BleTokenResponse struct {
	BleToken BleToken `json:"ble_token"`
}

type BleToken struct {
	Token     string    `json:"token"`
	ExpiresAt time.Time `json:"expires_at"`
}
