package handler

import (
	"net/http"
	"time"

	"github.com/labstack/echo/v4"

	"hackathon/internal/handler/middleware"
	schemareq "hackathon/internal/handler/schema/request"
	schemares "hackathon/internal/handler/schema/response"
	"hackathon/internal/usecase"
	usecasedto "hackathon/internal/usecase/dto"
)

type muteHandler struct {
	usecase usecase.MuteUsecase
}

func newMuteHandler(u usecase.MuteUsecase) *muteHandler {
	return &muteHandler{usecase: u}
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
