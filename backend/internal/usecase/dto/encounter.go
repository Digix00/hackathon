package dto

import "time"

// CreateEncounterInput is the payload for creating an encounter.
type CreateEncounterInput struct {
	TargetBleToken string
	Type           string
	RSSI           int
	OccurredAt     time.Time
}

type EncounterUserDTO struct {
	ID          string
	DisplayName string
	AvatarURL   *string
}

type EncounterTrackDTO struct {
	ID         string
	Title      string
	ArtistName string
	ArtworkURL *string
	PreviewURL *string
}

type EncounterSummaryDTO struct {
	ID         string
	Type       string
	User       EncounterUserDTO
	OccurredAt time.Time
}

type EncounterListItemDTO struct {
	ID         string
	Type       string
	User       EncounterUserDTO
	IsRead     bool
	Tracks     []EncounterTrackDTO
	OccurredAt time.Time
}

type EncounterDetailDTO struct {
	ID         string
	Type       string
	User       EncounterUserDTO
	OccurredAt time.Time
	Tracks     []EncounterTrackDTO
}
