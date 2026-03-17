package request

// @name CreateUserRequest
type CreateUserRequest struct {
	DisplayName   string  `json:"display_name"`
	AvatarURL     *string `json:"avatar_url"`
	Bio           *string `json:"bio"`
	Birthdate     *string `json:"birthdate"`
	AgeVisibility *string `json:"age_visibility"`
	PrefectureID  *string `json:"prefecture_id"`
	Sex           *string `json:"sex"`
}

// @name UpdateUserRequest
type UpdateUserRequest struct {
	DisplayName   *string `json:"display_name"`
	AvatarURL     *string `json:"avatar_url"`
	Bio           *string `json:"bio"`
	Birthdate     *string `json:"birthdate"`
	AgeVisibility *string `json:"age_visibility"`
	PrefectureID  *string `json:"prefecture_id"`
	Sex           *string `json:"sex"`
}
