package entity

import (
	"time"

	"hackathon/internal/domain/vo"
)

type User struct {
	ID             string
	AuthProvider   string
	ProviderUserID string
	Name           *string
	Bio            *string
	Birthdate      *time.Time
	AgeVisibility  vo.AgeVisibility
	PrefectureID   *string
	PrefectureName *string
	Sex            vo.Sex
	AvatarFileID   *string
	AvatarURL      *string
	CreatedAt      time.Time
	UpdatedAt      time.Time
}
