package dto

import "time"

type Settings struct {
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
	NotificationFrequency           string
	CommentNotificationEnabled      bool
	LikeNotificationEnabled         bool
	AnnouncementNotificationEnabled bool
	ThemeMode                       string
	UpdatedAt                       time.Time
}

type UpdateSettingsInput struct {
	DetectionDistance               *int
	NotificationFrequency           *string
	ThemeMode                       *string
	ScheduleStartTime               *string
	ScheduleEndTime                 *string
	BleEnabled                      *bool
	LocationEnabled                 *bool
	ScheduleEnabled                 *bool
	ProfileVisible                  *bool
	TrackVisible                    *bool
	NotificationEnabled             *bool
	EncounterNotificationEnabled    *bool
	BatchNotificationEnabled        *bool
	CommentNotificationEnabled      *bool
	LikeNotificationEnabled         *bool
	AnnouncementNotificationEnabled *bool
}
