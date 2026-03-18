package response

// @name CommentResponse
type CommentResponse struct {
	Comment Comment `json:"comment"`
}

// @name CommentListResponse
type CommentListResponse struct {
	Comments   []Comment  `json:"comments"`
	Pagination Pagination `json:"pagination"`
}

// @name Comment
type Comment struct {
	ID          string      `json:"id"`
	EncounterID string      `json:"encounter_id"`
	User        CommentUser `json:"user"`
	Content     string      `json:"content"`
	CreatedAt   string      `json:"created_at"`
}

// @name CommentUser
type CommentUser struct {
	ID          string  `json:"id"`
	DisplayName string  `json:"display_name"`
	AvatarURL   *string `json:"avatar_url"`
}

// @name Pagination
type Pagination struct {
	NextCursor *string `json:"next_cursor"`
	HasMore    bool    `json:"has_more"`
}
