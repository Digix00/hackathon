package dto

import "time"

type Device struct {
	ID        string
	Platform  string
	DeviceID  string
	Enabled   bool
	UpdatedAt time.Time
}

type CreatePushTokenInput struct {
	Platform   string
	DeviceID   string
	PushToken  string
	AppVersion *string
}

type UpdatePushTokenInput struct {
	PushToken  *string
	Enabled    *bool
	AppVersion *string
}
