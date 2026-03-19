package dto

import "time"

// PostLocationInput は POST /locations のリクエスト入力。
type PostLocationInput struct {
	Lat        float64
	Lng        float64
	AccuracyM  *float64
	RecordedAt time.Time
}

// LocationResultDTO は POST /locations のレスポンス。
type LocationResultDTO struct {
	EncounterCount int
	Encounters     []EncounterSummaryDTO
}
