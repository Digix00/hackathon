package handler

import (
	"net/http"
	"regexp"
	"strconv"
	"time"

	"github.com/labstack/echo/v4"

	"hackathon/internal/handler/middleware"
	schemareq "hackathon/internal/handler/schema/request"
	schemares "hackathon/internal/handler/schema/response"
	"hackathon/internal/usecase"
	usecasedto "hackathon/internal/usecase/dto"
)

var bleTokenRegex = regexp.MustCompile("^[0-9a-f]{16}$")

type encounterHandler struct {
	usecase usecase.EncounterUsecase
}

func newEncounterHandler(u usecase.EncounterUsecase) *encounterHandler {
	return &encounterHandler{usecase: u}
}

// createEncounter godoc
// @ID           createEncounter
// @Summary      すれ違い登録
// @Description  BLE 検出トークンからすれ違いを登録する（同一ペア・短時間内は冪等）
// @Tags         encounters
// @Accept       json
// @Produce      json
// @Security     BearerAuth
// @Param        body  body      schemareq.CreateEncounterRequest  true  "すれ違い登録リクエスト"
// @Success      201   {object}  schemares.EncounterResponse
// @Success      200   {object}  schemares.EncounterResponse
// @Failure      400   {object}  errorResponse
// @Failure      401   {object}  errorResponse
// @Failure      404   {object}  errorResponse
// @Failure      409   {object}  errorResponse
// @Failure      429   {object}  errorResponse
// @Failure      500   {object}  errorResponse
// @Router       /api/v1/encounters [post]
func (h *encounterHandler) createEncounter(c echo.Context) error {
	ctx := c.Request().Context()
	authUID, ok := middleware.UserIDFromContext(c)
	if !ok {
		return errUnauthorized()
	}

	var req schemareq.CreateEncounterRequest
	if err := c.Bind(&req); err != nil {
		return errBadRequest("Invalid request body")
	}
	if req.TargetBleToken == "" {
		return errBadRequest("target_ble_token is required")
	}
	if !bleTokenRegex.MatchString(req.TargetBleToken) {
		return errBadRequest("target_ble_token must be 16 lowercase hex characters")
	}
	if req.Type == "" {
		return errBadRequest("type is required")
	}
	if req.Type != "ble" {
		return errBadRequest("type must be ble")
	}
	if req.RSSI == nil {
		return errBadRequest("rssi is required")
	}
	if *req.RSSI < -100 || *req.RSSI > 0 {
		return errBadRequest("rssi must be between -100 and 0")
	}
	if req.OccurredAt == "" {
		return errBadRequest("occurred_at is required")
	}
	occurredAt, err := time.Parse(time.RFC3339, req.OccurredAt)
	if err != nil {
		return errBadRequest("occurred_at must be RFC3339")
	}

	dto, created, err := h.usecase.CreateEncounter(ctx, authUID, usecasedto.CreateEncounterInput{
		TargetBleToken: req.TargetBleToken,
		Type:           req.Type,
		RSSI:           *req.RSSI,
		OccurredAt:     occurredAt,
	})
	if err != nil {
		return err
	}

	status := http.StatusOK
	if created {
		status = http.StatusCreated
	}

	return c.JSON(status, schemares.EncounterResponse{
		Encounter: encounterSummaryDTOToResponse(dto),
	})
}

// listEncounters godoc
// @ID           listEncounters
// @Summary      すれ違い履歴一覧取得
// @Description  認証ユーザーのすれ違い履歴を取得する
// @Tags         encounters
// @Produce      json
// @Security     BearerAuth
// @Param        limit  query     int     false  "取得件数（省略時 20, 最大 50）"
// @Param        cursor query     string  false  "次ページ取得用カーソル"
// @Success      200   {object}  schemares.EncounterListResponse
// @Failure      400   {object}  errorResponse
// @Failure      401   {object}  errorResponse
// @Failure      500   {object}  errorResponse
// @Router       /api/v1/encounters [get]
func (h *encounterHandler) listEncounters(c echo.Context) error {
	ctx := c.Request().Context()
	authUID, ok := middleware.UserIDFromContext(c)
	if !ok {
		return errUnauthorized()
	}

	limit := 20
	limitRaw := c.QueryParam("limit")
	if limitRaw != "" {
		parsed, err := strconv.Atoi(limitRaw)
		if err != nil || parsed <= 0 {
			return errBadRequest("limit must be a positive integer")
		}
		if parsed > 50 {
			parsed = 50
		}
		limit = parsed
	}

	cursor := c.QueryParam("cursor")
	encounters, nextCursor, hasMore, err := h.usecase.ListEncounters(ctx, authUID, limit, cursor)
	if err != nil {
		return err
	}

	items := make([]schemares.EncounterListItem, 0, len(encounters))
	for _, enc := range encounters {
		items = append(items, encounterListItemDTOToResponse(enc))
	}

	return c.JSON(http.StatusOK, schemares.EncounterListResponse{
		Encounters: items,
		Pagination: schemares.Pagination{
			NextCursor: nextCursor,
			HasMore:    hasMore,
		},
	})
}

// getEncounterByID godoc
// @ID           getEncounterByID
// @Summary      すれ違い詳細取得
// @Description  指定した ID のすれ違い詳細を取得する
// @Tags         encounters
// @Produce      json
// @Security     BearerAuth
// @Param        id   path      string  true  "対象すれ違い ID"
// @Success      200  {object}  schemares.EncounterDetailResponse
// @Failure      400  {object}  errorResponse
// @Failure      401  {object}  errorResponse
// @Failure      404  {object}  errorResponse
// @Failure      500  {object}  errorResponse
// @Router       /api/v1/encounters/{id} [get]
func (h *encounterHandler) getEncounterByID(c echo.Context) error {
	ctx := c.Request().Context()
	authUID, ok := middleware.UserIDFromContext(c)
	if !ok {
		return errUnauthorized()
	}

	encounterID := c.Param("id")
	if encounterID == "" {
		return errBadRequest("id path param is required")
	}

	dto, err := h.usecase.GetEncounterByID(ctx, authUID, encounterID)
	if err != nil {
		return err
	}

	return c.JSON(http.StatusOK, schemares.EncounterDetailResponse{
		Encounter: encounterDetailDTOToResponse(dto),
	})
}
