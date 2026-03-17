package response

// @name UserResponse
type UserResponse struct {
	User User `json:"user"`
}

// @name PublicUserResponse
type PublicUserResponse struct {
	User PublicUser `json:"user"`
}

// @name User
type User struct {
	ID            string  `json:"id"`
	DisplayName   string  `json:"display_name"`
	AvatarURL     *string `json:"avatar_url"`
	Bio           *string `json:"bio"`
	Birthdate     *string `json:"birthdate"`
	AgeVisibility string  `json:"age_visibility" enums:"hidden,exact,by-10"`
	PrefectureID  *string `json:"prefecture_id"`
	Sex           string  `json:"sex" enums:"male,female,other,no-answer"`
	CreatedAt     string  `json:"created_at"`
	UpdatedAt     string  `json:"updated_at"`
}

// @name PublicUser
type PublicUser struct {
	ID             string       `json:"id"`
	DisplayName    string       `json:"display_name"`
	AvatarURL      *string      `json:"avatar_url"`
	Bio            *string      `json:"bio"`
	Birthplace     *string      `json:"birthplace"`
	AgeRange       *string      `json:"age_range"`
	EncounterCount int64        `json:"encounter_count"`
	SharedTrack    *PublicTrack `json:"shared_track"`
	UpdatedAt      string       `json:"updated_at"`
}

// @name PublicTrack
type PublicTrack struct {
	ID         string  `json:"id"`
	Title      string  `json:"title"`
	ArtistName string  `json:"artist_name"`
	ArtworkURL *string `json:"artwork_url"`
	PreviewURL *string `json:"preview_url"`
}
