package entity

import "time"

type User struct {
	ID             string
	AuthProvider   string
	ProviderUserID string
	Name           *string
	Bio            *string
	Birthdate      *time.Time
	AgeVisibility  string
	PrefectureID   *string
	PrefectureName *string
	Sex            string
	AvatarFileID   *string
	AvatarURL      *string
	CreatedAt      time.Time
	UpdatedAt      time.Time
}
