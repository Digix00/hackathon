package entity

import (
	"time"

	"github.com/google/uuid"
)

type BleToken struct {
	ID        string
	UserID    string
	Token     string
	ValidFrom time.Time
	ValidTo   time.Time
	CreatedAt time.Time
}

// NewBleToken generates a new BleToken.
// To keep things simple, let's say a BLE Token is valid for 24 hours.
func NewBleToken(userID string, ttlHours int) BleToken {
	now := time.Now().UTC()
	return BleToken{
		ID:        uuid.NewString(), // assuming UUID is fine for ID
		UserID:    userID,
		Token:     uuid.NewString(), // this is the 128-bit BLE token payload identifier
		ValidFrom: now,
		ValidTo:   now.Add(time.Duration(ttlHours) * time.Hour),
		CreatedAt: now,
	}
}

// IsValid checks if the token is currently within its validity period.
func (b *BleToken) IsValid(at time.Time) bool {
	return !at.Before(b.ValidFrom) && at.Before(b.ValidTo)
}
