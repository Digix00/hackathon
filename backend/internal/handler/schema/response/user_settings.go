package response

// @name SettingsResponse
type SettingsResponse struct {
	Settings Settings `json:"settings"`
}

// @name Settings
type Settings struct {
	BleEnabled                      bool    `json:"ble_enabled"`
	LocationEnabled                 bool    `json:"location_enabled"`
	DetectionDistance               int     `json:"detection_distance"`
	ScheduleEnabled                 bool    `json:"schedule_enabled"`
	ScheduleStartTime               *string `json:"schedule_start_time"`
	ScheduleEndTime                 *string `json:"schedule_end_time"`
	ProfileVisible                  bool    `json:"profile_visible"`
	TrackVisible                    bool    `json:"track_visible"`
	NotificationEnabled             bool    `json:"notification_enabled"`
	EncounterNotificationEnabled    bool    `json:"encounter_notification_enabled"`
	BatchNotificationEnabled        bool    `json:"batch_notification_enabled"`
	NotificationFrequency           string  `json:"notification_frequency"`
	CommentNotificationEnabled      bool    `json:"comment_notification_enabled"`
	LikeNotificationEnabled         bool    `json:"like_notification_enabled"`
	AnnouncementNotificationEnabled bool    `json:"announcement_notification_enabled"`
	ThemeMode                       string  `json:"theme_mode"`
	UpdatedAt                       string  `json:"updated_at"`
}
