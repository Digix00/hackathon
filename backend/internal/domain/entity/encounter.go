package entity

import (
	"time"

	"hackathon/internal/domain/vo"
)

type Encounter struct {
	ID            string
	UserID1       string
	UserID2       string
	EncounterType vo.EncounterType
	OccurredAt    time.Time
	Latitude      *float64
	Longitude     *float64
	CreatedAt     time.Time
}
