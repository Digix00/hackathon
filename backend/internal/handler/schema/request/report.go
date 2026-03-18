package request

// @name CreateReportRequest
type CreateReportRequest struct {
	ReportedUserID  string  `json:"reported_user_id"`
	ReportType      string  `json:"report_type" enums:"user,comment"`
	TargetCommentID *string `json:"target_comment_id"`
	Reason          string  `json:"reason"`
}
