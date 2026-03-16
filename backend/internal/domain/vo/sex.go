package vo

import domainerrs "hackathon/internal/domain/errs"

type Sex string

const (
	SexMale     Sex = "male"
	SexFemale   Sex = "female"
	SexOther    Sex = "other"
	SexNoAnswer Sex = "no-answer"
)

func ParseSex(s string) (Sex, error) {
	switch Sex(s) {
	case SexMale, SexFemale, SexOther, SexNoAnswer:
		return Sex(s), nil
	}
	return "", domainerrs.BadRequest("sex is invalid")
}
