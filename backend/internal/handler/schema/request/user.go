package request

// @name CreateUserRequest
type CreateUserRequest struct {
	DisplayName   string  `json:"display_name"`
	AvatarURL     *string `json:"avatar_url"`
	Bio           *string `json:"bio"`
	Birthdate     *string `json:"birthdate"`
	AgeVisibility *string `json:"age_visibility" enums:"hidden,exact,by-10"`
	PrefectureID  *string `json:"prefecture_id"`
	Sex           *string `json:"sex" enums:"male,female,other,no-answer"`
}

// @name UpdateUserRequest
type UpdateUserRequest struct {
	DisplayName   *string `json:"display_name"`
	AvatarURL     *string `json:"avatar_url"`
	Bio           *string `json:"bio"`
	Birthdate     *string `json:"birthdate"`
	AgeVisibility *string `json:"age_visibility" enums:"hidden,exact,by-10"`
	PrefectureID  *string `json:"prefecture_id"`
	Sex           *string `json:"sex" enums:"male,female,other,no-answer"`
}
