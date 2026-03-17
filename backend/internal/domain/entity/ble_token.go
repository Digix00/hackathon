package entity

import (
	"crypto/rand"
	"encoding/hex"
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
// Token is 8 random bytes encoded as a 16-character hex string, matching the
// BLE design spec (ble_token = 8 bytes, used as the TOKEN portion of TOKEN_UUID).
func NewBleToken(userID string, ttlHours int) (BleToken, error) {
	token, err := newBleTokenString()
	if err != nil {
		return BleToken{}, err
	}
	now := time.Now().UTC()
	return BleToken{
		ID:        uuid.NewString(),
		UserID:    userID,
		Token:     token,
		ValidFrom: now,
		ValidTo:   now.Add(time.Duration(ttlHours) * time.Hour),
		CreatedAt: now,
	}, nil
}

// newBleTokenString generates 8 cryptographically random bytes and returns
// them as a 16-character lowercase hex string.
func newBleTokenString() (string, error) {
	b := make([]byte, 8)
	if _, err := rand.Read(b); err != nil {
		return "", err
	}
	return hex.EncodeToString(b), nil
}

// IsValid checks if the token is currently within its validity period.
func (b *BleToken) IsValid(at time.Time) bool {
	return !at.Before(b.ValidFrom) && at.Before(b.ValidTo)
}
