package repository

import (
	"context"

	"hackathon/internal/domain/entity"
)

type ReportRepository interface {
	Create(ctx context.Context, report entity.Report) error
	ExistsByReporterAndTarget(ctx context.Context, reporterUserID, reportedUserID, reportType string, targetCommentID *string) (bool, error)
}
