package entity

import "time"

type UserDevice struct {
	ID          string
	UserID      string
	Platform    string
	DeviceID    string
	DeviceToken string
	AppVersion  *string
	Enabled     bool
	CreatedAt   time.Time
	UpdatedAt   time.Time
}
