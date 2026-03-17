package dto

import "time"

type CreateReportInput struct {
	ReportedUserID  string
	ReportType      string // 'user' | 'comment'
	TargetCommentID *string
	Reason          string
}

type ReportDTO struct {
	ID              string
	ReportedUserID  string
	ReportType      string
	TargetCommentID *string
	Reason          string
	CreatedAt       time.Time
}
