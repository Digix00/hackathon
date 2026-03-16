package dto

import "time"

// UserDTO is the output for the authenticated user's own profile.
type UserDTO struct {
	ID            string
	DisplayName   string
	AvatarURL     *string
	Bio           *string
	Birthdate     *string // formatted as YYYY-MM-DD
	AgeVisibility string
	PrefectureID  *string
	Sex           string
	CreatedAt     time.Time
	UpdatedAt     time.Time
}

// PublicUserDTO is the output for viewing another user's profile.
type PublicUserDTO struct {
	ID             string
	DisplayName    string
	AvatarURL      *string
	Bio            *string
	Birthplace     *string // prefecture name
	AgeRange       *string // computed from birthdate + visibility
	EncounterCount int64
	SharedTrack    *TrackInfoDTO
	UpdatedAt      time.Time
}

// TrackInfoDTO holds minimal info for the shared track on a public profile.
type TrackInfoDTO struct {
	ID         string
	Title      string
	ArtistName string
	ArtworkURL *string
}

// CreateUserInput holds validated data for creating a new user.
type CreateUserInput struct {
	DisplayName   string
	Bio           *string
	Birthdate     *time.Time
	AgeVisibility string
	PrefectureID  *string
	Sex           string
	AvatarURL     *string
}

// UpdateUserInput holds patch intentions; pointer fields = nil means "not provided".
type UpdateUserInput struct {
	DisplayName   *string
	Bio           *string
	BirthdateSet  bool
	Birthdate     *time.Time
	AgeVisibility *string
	PrefectureID  *string
	Sex           *string
	AvatarURLSet  bool
	AvatarURL     *string // nil+set=clear avatar; non-empty+set=new avatar URL
}
