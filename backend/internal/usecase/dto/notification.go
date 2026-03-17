package dto

import "time"

type NotificationOutput struct {
	ID          string
	EncounterID string
	Status      string
	ReadAt      *time.Time
	CreatedAt   time.Time
}

type NotificationListOutput struct {
	Notifications []NotificationOutput
	UnreadCount   int64
	Total         int64
}
