package response

// @name ReportResponse
type ReportResponse struct {
	Report Report `json:"report"`
}

// @name Report
type Report struct {
	ID              string  `json:"id"`
	ReportedUserID  string  `json:"reported_user_id"`
	ReportType      string  `json:"report_type" enums:"user,comment"`
	TargetCommentID *string `json:"target_comment_id"`
	Reason          string  `json:"reason"`
	CreatedAt       string  `json:"created_at"`
}
