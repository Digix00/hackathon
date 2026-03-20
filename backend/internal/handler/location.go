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

type locationHandler struct {
	log     *zap.Logger
	usecase usecase.LocationUsecase
}

func newLocationHandler(log *zap.Logger, u usecase.LocationUsecase) *locationHandler {
	return &locationHandler{log: log, usecase: u}
}

// postLocation godoc
// @ID           postLocation
// @Summary      現在位置送信・エンカウント判定
// @Description  現在位置をサーバーに送信し、近くにいるユーザーとのエンカウントを判定・作成する
// @Tags         locations
// @Accept       json
// @Produce      json
// @Security     BearerAuth
// @Param        body  body      schemareq.PostLocationRequest  true  "位置情報リクエスト"
// @Success      200   {object}  schemares.LocationResponse
// @Failure      400   {object}  errorResponse
// @Failure      401   {object}  errorResponse
// @Failure      500   {object}  errorResponse
// @Router       /api/v1/locations [post]
func (h *locationHandler) postLocation(c echo.Context) error {
	ctx := c.Request().Context()
	authUID, ok := middleware.UserIDFromContext(c)
	if !ok {
		return errUnauthorized()
	}

	var req schemareq.PostLocationRequest
	if err := c.Bind(&req); err != nil {
		return errBadRequest("Invalid request body")
	}
	if req.Lat == nil {
		return errBadRequest("lat is required")
	}
	if req.Lng == nil {
		return errBadRequest("lng is required")
	}
	if *req.Lat < -90 || *req.Lat > 90 {
		return errBadRequest("lat must be between -90 and 90")
	}
	if *req.Lng < -180 || *req.Lng > 180 {
		return errBadRequest("lng must be between -180 and 180")
	}
	if req.RecordedAt == "" {
		return errBadRequest("recorded_at is required")
	}
	recordedAt, err := time.Parse(time.RFC3339, req.RecordedAt)
	if err != nil {
		return errBadRequest("recorded_at must be RFC3339")
	}

	out, err := h.usecase.PostLocation(ctx, authUID, usecasedto.PostLocationInput{
		Lat:        *req.Lat,
		Lng:        *req.Lng,
		AccuracyM:  req.AccuracyM,
		RecordedAt: recordedAt,
	})
	if err != nil {
		return err
	}

	items := make([]schemares.EncounterSummary, 0, len(out.Encounters))
	for _, enc := range out.Encounters {
		items = append(items, encounterSummaryDTOToResponse(enc))
	}

	return c.JSON(http.StatusOK, schemares.LocationResponse{
		EncounterCount: out.EncounterCount,
		Encounters:     items,
	})
}
