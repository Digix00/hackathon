package dto

import "time"

// BleTokenDTO represents a BLE token for proximity tracking.
type BleTokenDTO struct {
	Token   string
	ValidTo time.Time
}
