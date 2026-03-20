package handler

import (
	"net/http"
	"strconv"
	"time"

	"github.com/labstack/echo/v4"
	"go.uber.org/zap"

	"hackathon/internal/handler/middleware"
	schemareq "hackathon/internal/handler/schema/request"
	schemares "hackathon/internal/handler/schema/response"
	"hackathon/internal/usecase"
	usecasedto "hackathon/internal/usecase/dto"
)

type muteHandler struct {
	log     *zap.Logger
	usecase usecase.MuteUsecase
}

func newMuteHandler(log *zap.Logger, u usecase.MuteUsecase) *muteHandler {
	return &muteHandler{log: log, usecase: u}
}

// createMute godoc
// @ID           createMute
// @Summary      ミュート作成
// @Description  指定したユーザーをミュートする。自分自身や存在しないユーザーへのミュート、重複ミュートはエラーになる。
// @Tags         mutes
// @Accept       json
// @Produce      json
// @Security     BearerAuth
// @Param        body  body      schemareq.CreateMuteRequest  true  "ミュートリクエスト"
// @Success      201   {object}  schemares.MuteResponse
// @Failure      400   {object}  errorResponse
// @Failure      401   {object}  errorResponse
// @Failure      404   {object}  errorResponse
// @Failure      409   {object}  errorResponse
// @Failure      500   {object}  errorResponse
// @Router       /api/v1/users/me/mutes [post]
func (h *muteHandler) createMute(c echo.Context) error {
	ctx := c.Request().Context()
	authUID, ok := middleware.UserIDFromContext(c)
	if !ok {
		return errUnauthorized()
	}

	var req schemareq.CreateMuteRequest
	if err := c.Bind(&req); err != nil {
		return errBadRequest("Invalid request body")
	}

	if req.TargetUserID == "" {
		return errBadRequest("target_user_id is required")
	}

	dto, err := h.usecase.CreateMute(ctx, authUID, usecasedto.CreateMuteInput{
		TargetUserID: req.TargetUserID,
	})
	if err != nil {
		return err
	}

	return c.JSON(http.StatusCreated, schemares.MuteResponse{
		Mute: schemares.Mute{
			ID:           dto.ID,
			TargetUserID: dto.TargetUserID,
			CreatedAt:    dto.CreatedAt.UTC().Format(time.RFC3339),
		},
	})
}

// deleteMute godoc
// @ID           deleteMute
// @Summary      ミュート解除
// @Description  指定したユーザーのミュートを解除する。ミュートが存在しない場合はエラーになる。
// @Tags         mutes
// @Produce      json
// @Security     BearerAuth
// @Param        target_user_id  path  string  true  "ミュート解除対象のユーザーID"
// @Success      204
// @Failure      401   {object}  errorResponse
// @Failure      404   {object}  errorResponse
// @Failure      500   {object}  errorResponse
// @Router       /api/v1/users/me/mutes/{target_user_id} [delete]
func (h *muteHandler) deleteMute(c echo.Context) error {
	ctx := c.Request().Context()
	authUID, ok := middleware.UserIDFromContext(c)
	if !ok {
		return errUnauthorized()
	}

	targetUserID := c.Param("target_user_id")
	if targetUserID == "" {
		return errBadRequest("target_user_id is required")
	}

	if err := h.usecase.DeleteMute(ctx, authUID, targetUserID); err != nil {
		return err
	}

	return c.NoContent(http.StatusNoContent)
}

// listMutes godoc
// @ID           listMutes
// @Summary      ミュート一覧取得
// @Description  認証済みユーザーがミュートしているユーザーの一覧をカーソルページネーションで取得する
// @Tags         mutes
// @Produce      json
// @Security     BearerAuth
// @Param        limit   query     int     false  "取得件数（省略時 20、最大 50）"
// @Param        cursor  query     string  false  "ページネーションカーソル"
// @Success      200  {object}  schemares.MuteListResponse
// @Failure      400  {object}  errorResponse
// @Failure      401  {object}  errorResponse
// @Failure      500  {object}  errorResponse
// @Router       /api/v1/users/me/mutes [get]
func (h *muteHandler) listMutes(c echo.Context) error {
	ctx := c.Request().Context()
	authUID, ok := middleware.UserIDFromContext(c)
	if !ok {
		return errUnauthorized()
	}

	limit := 20
	if l := c.QueryParam("limit"); l != "" {
		parsed, err := strconv.Atoi(l)
		if err != nil || parsed <= 0 {
			return errBadRequest("limit must be a positive integer")
		}
		limit = parsed
	}

	var cursor *string
	if raw := c.QueryParam("cursor"); raw != "" {
		cursor = &raw
	}

	result, err := h.usecase.ListMutes(ctx, authUID, limit, cursor)
	if err != nil {
		return err
	}

	mutes := make([]schemares.Mute, len(result.Mutes))
	for i, m := range result.Mutes {
		mutes[i] = schemares.Mute{
			ID:           m.ID,
			TargetUserID: m.TargetUserID,
			CreatedAt:    m.CreatedAt.UTC().Format(time.RFC3339),
		}
	}

	return c.JSON(http.StatusOK, schemares.MuteListResponse{
		Mutes: mutes,
		Pagination: schemares.MuteListPagination{
			NextCursor: result.NextCursor,
			HasMore:    result.HasMore,
		},
	})
}
