package entity

import "time"

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
	NotificationFrequency           string
	CommentNotificationEnabled      bool
	LikeNotificationEnabled         bool
	AnnouncementNotificationEnabled bool
	ThemeMode                       string
	CreatedAt                       time.Time
	UpdatedAt                       time.Time
}
