package entity

import (
	"time"

	"hackathon/internal/domain/vo"
)

type UserSettings struct {
	ID                              string
	UserID                          string
	BleEnabled                      bool
	LocationEnabled                 bool
	DetectionDistance               int
	ScheduleEnabled                 bool
	ScheduleStartTime               *string
	ScheduleEndTime                 *string
	ProfileVisible                  bool
	TrackVisible                    bool
	NotificationEnabled             bool
	EncounterNotificationEnabled    bool
	BatchNotificationEnabled        bool
	NotificationFrequency           vo.NotificationFrequency
	CommentNotificationEnabled      bool
	LikeNotificationEnabled         bool
	AnnouncementNotificationEnabled bool
	ThemeMode                       vo.ThemeMode
	CreatedAt                       time.Time
	UpdatedAt                       time.Time
}

// NewUserSettings はデフォルト値を設定した新規UserSettingsを生成する。
func NewUserSettings(id, userID string) UserSettings {
	return UserSettings{
		ID:                              id,
		UserID:                          userID,
		BleEnabled:                      true,
		LocationEnabled:                 true,
		DetectionDistance:               50,
		ScheduleEnabled:                 false,
		ProfileVisible:                  true,
		TrackVisible:                    true,
		NotificationEnabled:             true,
		EncounterNotificationEnabled:    true,
		BatchNotificationEnabled:        true,
		NotificationFrequency:           vo.NotificationFrequencyHourly,
		CommentNotificationEnabled:      true,
		LikeNotificationEnabled:         true,
		AnnouncementNotificationEnabled: true,
		ThemeMode:                       vo.ThemeModeSystem,
	}
}
