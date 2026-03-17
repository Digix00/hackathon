package dto

import "time"

// BleTokenDTO represents a BLE token for proximity tracking.
type BleTokenDTO struct {
	Token     string
	ValidFrom time.Time
	ValidTo   time.Time
}
