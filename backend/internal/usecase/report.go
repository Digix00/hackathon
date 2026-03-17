package usecase

import (
	"context"

	domainerrs "hackathon/internal/domain/errs"
	"hackathon/internal/domain/entity"
	"hackathon/internal/domain/repository"
	usecasedto "hackathon/internal/usecase/dto"
)

type ReportUsecase interface {
	CreateReport(ctx context.Context, authUID string, input usecasedto.CreateReportInput) (usecasedto.ReportDTO, error)
}

type reportUsecase struct {
	userRepo   repository.UserRepository
	reportRepo repository.ReportRepository
}

func NewReportUsecase(
	userRepo repository.UserRepository,
	reportRepo repository.ReportRepository,
) ReportUsecase {
	return &reportUsecase{
		userRepo:   userRepo,
		reportRepo: reportRepo,
	}
}

func (u *reportUsecase) CreateReport(ctx context.Context, authUID string, input usecasedto.CreateReportInput) (usecasedto.ReportDTO, error) {
	reporter, err := u.userRepo.FindByAuthProviderAndProviderUserID(ctx, firebaseProvider, authUID)
	if err != nil {
		return usecasedto.ReportDTO{}, err
	}

	if reporter.ID == input.ReportedUserID {
		return usecasedto.ReportDTO{}, domainerrs.BadRequest("cannot report yourself")
	}

	_, err = u.userRepo.FindByID(ctx, input.ReportedUserID)
	if err != nil {
		return usecasedto.ReportDTO{}, err
	}

	exists, err := u.reportRepo.ExistsByReporterAndTarget(ctx, reporter.ID, input.ReportedUserID, input.ReportType, input.TargetCommentID)
	if err != nil {
		return usecasedto.ReportDTO{}, err
	}
	if exists {
		return usecasedto.ReportDTO{}, domainerrs.Conflict("report already submitted")
	}

	report := entity.NewReport(reporter.ID, input.ReportedUserID, input.ReportType, input.Reason, input.TargetCommentID)

	if err := u.reportRepo.Create(ctx, report); err != nil {
		return usecasedto.ReportDTO{}, err
	}

	return usecasedto.ReportDTO{
		ID:              report.ID,
		ReportedUserID:  report.ReportedUserID,
		ReportType:      report.ReportType,
		TargetCommentID: report.TargetCommentID,
		Reason:          report.Reason,
		CreatedAt:       report.CreatedAt,
	}, nil
}
