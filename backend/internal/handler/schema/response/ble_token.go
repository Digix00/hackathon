package response

import "time"

type BleTokenResponse struct {
	BleToken BleToken `json:"ble_token"`
}

type BleToken struct {
	Token     string    `json:"token"`
	ValidFrom time.Time `json:"valid_from"`
	ValidTo   time.Time `json:"valid_to"`
}
