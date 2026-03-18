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
