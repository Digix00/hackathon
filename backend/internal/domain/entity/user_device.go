package entity

import (
	"time"

	"hackathon/internal/domain/vo"
)

type UserDevice struct {
	ID          string
	UserID      string
	Platform    vo.Platform
	DeviceID    string
	DeviceToken string
	AppVersion  *string
	Enabled     bool
	CreatedAt   time.Time
	UpdatedAt   time.Time
}

// NewUserDevice は新規UserDeviceエンティティを生成する。
func NewUserDevice(id, userID string, platform vo.Platform, deviceID, deviceToken string, appVersion *string) UserDevice {
	return UserDevice{
		ID:          id,
		UserID:      userID,
		Platform:    platform,
		DeviceID:    deviceID,
		DeviceToken: deviceToken,
		AppVersion:  appVersion,
		Enabled:     true,
	}
}
