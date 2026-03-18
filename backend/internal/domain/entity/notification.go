package entity

import "time"

type Notification struct {
	ID          string
	UserID      string
	EncounterID string
	Status      string
	RetryCount  int
	ReadAt      *time.Time
	CreatedAt   time.Time
	ProcessedAt *time.Time
}
