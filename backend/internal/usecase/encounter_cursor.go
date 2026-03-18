package usecase

import (
	"encoding/base64"
	"encoding/json"

	domainerrs "hackathon/internal/domain/errs"
	"hackathon/internal/domain/repository"
)

func parseEncounterCursor(raw string) (*repository.EncounterCursor, error) {
	if raw == "" {
		return nil, nil
	}

	decoded, err := base64.RawURLEncoding.DecodeString(raw)
	if err != nil {
		return nil, domainerrs.BadRequest("cursor is invalid")
	}

	var cursor repository.EncounterCursor
	if err := json.Unmarshal(decoded, &cursor); err != nil {
		return nil, domainerrs.BadRequest("cursor is invalid")
	}
	if cursor.ID == "" || cursor.OccurredAt.IsZero() {
		return nil, domainerrs.BadRequest("cursor is invalid")
	}

	return &cursor, nil
}

func encodeEncounterCursor(cursor *repository.EncounterCursor) (string, error) {
	if cursor == nil {
		return "", nil
	}
	payload, err := json.Marshal(cursor)
	if err != nil {
		return "", err
	}
	return base64.RawURLEncoding.EncodeToString(payload), nil
}
