package rdb

import (
	"context"

	"go.uber.org/zap"
	"gorm.io/gorm"

	"hackathon/internal/domain/entity"
	domainerrs "hackathon/internal/domain/errs"
	"hackathon/internal/domain/repository"
	"hackathon/internal/infra/rdb/model"
)

type reportRepository struct {
	log *zap.Logger
	db  *gorm.DB
}

func NewReportRepository(log *zap.Logger, db *gorm.DB) repository.ReportRepository {
	return &reportRepository{log: log, db: db}
}

func (r *reportRepository) Create(ctx context.Context, report entity.Report) error {
	m := model.Report{
		ID:              report.ID,
		ReporterUserID:  report.ReporterUserID,
		ReportedUserID:  report.ReportedUserID,
		ReportType:      report.ReportType,
		TargetCommentID: report.TargetCommentID,
		Reason:          report.Reason,
	}
	if err := r.db.WithContext(ctx).Create(&m).Error; err != nil {
		if isUniqueConstraintViolation(err) {
			return domainerrs.Conflict("Report already exists")
		}
		return err
	}
	return nil
}

func (r *reportRepository) ExistsByReporterAndTarget(ctx context.Context, reporterUserID, reportedUserID, reportType string, targetCommentID *string) (bool, error) {
	var count int64
	q := r.db.WithContext(ctx).
		Model(&model.Report{}).
		Where("reporter_user_id = ? AND reported_user_id = ? AND report_type = ?", reporterUserID, reportedUserID, reportType)

	if targetCommentID != nil {
		q = q.Where("target_comment_id = ?", *targetCommentID)
	} else {
		q = q.Where("target_comment_id IS NULL")
	}

	if err := q.Count(&count).Error; err != nil {
		return false, err
	}
	return count > 0, nil
}
