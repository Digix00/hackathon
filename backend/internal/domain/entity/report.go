package entity

import (
	"time"

	"github.com/google/uuid"
)

type Report struct {
	ID              string
	ReporterUserID  string
	ReportedUserID  string
	ReportType      string // 'user' | 'comment'
	TargetCommentID *string
	Reason          string
	CreatedAt       time.Time
}

func NewReport(reporterUserID, reportedUserID, reportType, reason string, targetCommentID *string) Report {
	return Report{
		ID:              uuid.NewString(),
		ReporterUserID:  reporterUserID,
		ReportedUserID:  reportedUserID,
		ReportType:      reportType,
		TargetCommentID: targetCommentID,
		Reason:          reason,
		CreatedAt:       time.Now().UTC(),
	}
}
