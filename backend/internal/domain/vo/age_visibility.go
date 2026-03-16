package vo

import domainerrs "hackathon/internal/domain/errs"

type AgeVisibility string

const (
	AgeVisibilityHidden AgeVisibility = "hidden"
	AgeVisibilityExact  AgeVisibility = "exact"
	AgeVisibilityByTen  AgeVisibility = "by-10"
)

func ParseAgeVisibility(s string) (AgeVisibility, error) {
	switch AgeVisibility(s) {
	case AgeVisibilityHidden, AgeVisibilityExact, AgeVisibilityByTen:
		return AgeVisibility(s), nil
	}
	return "", domainerrs.BadRequest("age_visibility is invalid")
}
