package vo

import domainerrs "hackathon/internal/domain/errs"

type EncounterType string

const (
	EncounterTypeBLE      EncounterType = "ble"
	EncounterTypeLocation EncounterType = "location"
)

func ParseEncounterType(s string) (EncounterType, error) {
	switch EncounterType(s) {
	case EncounterTypeBLE, EncounterTypeLocation:
		return EncounterType(s), nil
	}
	return "", domainerrs.BadRequest("encounter type is invalid")
}
