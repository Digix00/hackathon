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

type blockHandler struct {
	usecase usecase.BlockUsecase
}

func newBlockHandler(u usecase.BlockUsecase) *blockHandler {
	return &blockHandler{usecase: u}
}

// createBlock godoc
// @ID           createBlock
// @Summary      ブロック作成
// @Description  指定したユーザーをブロックする。自分自身や存在しないユーザーへのブロック、重複ブロックはエラーになる。
// @Tags         blocks
// @Accept       json
// @Produce      json
// @Security     BearerAuth
// @Param        body  body      schemareq.CreateBlockRequest  true  "ブロックリクエスト"
// @Success      201   {object}  schemares.BlockResponse
// @Failure      400   {object}  errorResponse
// @Failure      401   {object}  errorResponse
// @Failure      404   {object}  errorResponse
// @Failure      409   {object}  errorResponse
// @Failure      500   {object}  errorResponse
// @Router       /api/v1/users/me/blocks [post]
func (h *blockHandler) createBlock(c echo.Context) error {
	ctx := c.Request().Context()
	authUID, ok := middleware.UserIDFromContext(c)
	if !ok {
		return errUnauthorized()
	}

	var req schemareq.CreateBlockRequest
	if err := c.Bind(&req); err != nil {
		return errBadRequest("Invalid request body")
	}

	if req.BlockedUserID == "" {
		return errBadRequest("blocked_user_id is required")
	}

	dto, err := h.usecase.CreateBlock(ctx, authUID, usecasedto.CreateBlockInput{
		BlockedUserID: req.BlockedUserID,
	})
	if err != nil {
		return err
	}

	return c.JSON(http.StatusCreated, schemares.BlockResponse{
		Block: schemares.Block{
			ID:            dto.ID,
			BlockedUserID: dto.BlockedUserID,
			CreatedAt:     dto.CreatedAt.UTC().Format(time.RFC3339),
		},
	})
}

// deleteBlock godoc
// @ID           deleteBlock
// @Summary      ブロック解除
// @Description  指定したユーザーのブロックを解除する。ブロックが存在しない場合はエラーになる。
// @Tags         blocks
// @Produce      json
// @Security     BearerAuth
// @Param        blocked_user_id  path  string  true  "ブロック解除対象のユーザーID"
// @Success      204
// @Failure      401   {object}  errorResponse
// @Failure      404   {object}  errorResponse
// @Failure      500   {object}  errorResponse
// @Router       /api/v1/users/me/blocks/{blocked_user_id} [delete]
func (h *blockHandler) deleteBlock(c echo.Context) error {
	ctx := c.Request().Context()
	authUID, ok := middleware.UserIDFromContext(c)
	if !ok {
		return errUnauthorized()
	}

	blockedUserID := c.Param("blocked_user_id")
	if blockedUserID == "" {
		return errBadRequest("blocked_user_id is required")
	}

	if err := h.usecase.DeleteBlock(ctx, authUID, blockedUserID); err != nil {
		return err
	}

	return c.NoContent(http.StatusNoContent)
}
