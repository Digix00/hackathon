package response

// @name BlockResponse
type BlockResponse struct {
	Block Block `json:"block"`
}

// @name Block
type Block struct {
	ID            string `json:"id"`
	BlockedUserID string `json:"blocked_user_id"`
	CreatedAt     string `json:"created_at"`
}

// @name BlockListResponse
type BlockListResponse struct {
	Blocks     []Block             `json:"blocks"`
	Pagination BlockListPagination `json:"pagination"`
}

// @name BlockListPagination
type BlockListPagination struct {
	NextCursor *string `json:"next_cursor"`
	HasMore    bool    `json:"has_more"`
}
