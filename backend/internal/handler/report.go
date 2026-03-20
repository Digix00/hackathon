package handler

import (
	"net/http"
	"time"

	"github.com/labstack/echo/v4"
	"go.uber.org/zap"

	"hackathon/internal/handler/middleware"
	schemareq "hackathon/internal/handler/schema/request"
	schemares "hackathon/internal/handler/schema/response"
	"hackathon/internal/usecase"
	usecasedto "hackathon/internal/usecase/dto"
)

type reportHandler struct {
	log     *zap.Logger
	usecase usecase.ReportUsecase
}

func newReportHandler(log *zap.Logger, u usecase.ReportUsecase) *reportHandler {
	return &reportHandler{log: log, usecase: u}
}

// createReport godoc
// @ID           createReport
// @Summary      通報作成
// @Description  ユーザーまたはコメントを通報する。同じ対象への重複通報はエラーになる。
// @Tags         reports
// @Accept       json
// @Produce      json
// @Security     BearerAuth
// @Param        body  body      schemareq.CreateReportRequest  true  "通報リクエスト"
// @Success      201   {object}  schemares.ReportResponse
// @Failure      400   {object}  errorResponse
// @Failure      401   {object}  errorResponse
// @Failure      404   {object}  errorResponse
// @Failure      409   {object}  errorResponse
// @Failure      500   {object}  errorResponse
// @Router       /api/v1/reports [post]
func (h *reportHandler) createReport(c echo.Context) error {
	ctx := c.Request().Context()
	authUID, ok := middleware.UserIDFromContext(c)
	if !ok {
		return errUnauthorized()
	}

	var req schemareq.CreateReportRequest
	if err := c.Bind(&req); err != nil {
		return errBadRequest("Invalid request body")
	}

	if req.ReportedUserID == "" {
		return errBadRequest("reported_user_id is required")
	}
	if req.ReportType != "user" && req.ReportType != "comment" {
		return errBadRequest("report_type must be 'user' or 'comment'")
	}
	if req.ReportType == "comment" && (req.TargetCommentID == nil || *req.TargetCommentID == "") {
		return errBadRequest("target_comment_id is required when report_type is 'comment'")
	}
	if req.ReportType == "user" && req.TargetCommentID != nil {
		return errBadRequest("target_comment_id must not be set when report_type is 'user'")
	}
	if req.Reason == "" {
		return errBadRequest("reason is required")
	}

	dto, err := h.usecase.CreateReport(ctx, authUID, usecasedto.CreateReportInput{
		ReportedUserID:  req.ReportedUserID,
		ReportType:      req.ReportType,
		TargetCommentID: req.TargetCommentID,
		Reason:          req.Reason,
	})
	if err != nil {
		return err
	}

	return c.JSON(http.StatusCreated, schemares.ReportResponse{
		Report: schemares.Report{
			ID:              dto.ID,
			ReportedUserID:  dto.ReportedUserID,
			ReportType:      dto.ReportType,
			TargetCommentID: dto.TargetCommentID,
			Reason:          dto.Reason,
			CreatedAt:       dto.CreatedAt.UTC().Format(time.RFC3339),
		},
	})
}
