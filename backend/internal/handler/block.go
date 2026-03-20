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

type blockHandler struct {
	log     *zap.Logger
	usecase usecase.BlockUsecase
}

func newBlockHandler(log *zap.Logger, u usecase.BlockUsecase) *blockHandler {
	return &blockHandler{log: log, usecase: u}
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

// listBlocks godoc
// @ID           listBlocks
// @Summary      ブロック一覧取得
// @Description  認証済みユーザーがブロックしているユーザーの一覧をカーソルページネーションで取得する
// @Tags         blocks
// @Produce      json
// @Security     BearerAuth
// @Param        limit   query     int     false  "取得件数（省略時 20、最大 50）"
// @Param        cursor  query     string  false  "ページネーションカーソル"
// @Success      200  {object}  schemares.BlockListResponse
// @Failure      400  {object}  errorResponse
// @Failure      401  {object}  errorResponse
// @Failure      500  {object}  errorResponse
// @Router       /api/v1/users/me/blocks [get]
func (h *blockHandler) listBlocks(c echo.Context) error {
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

	result, err := h.usecase.ListBlocks(ctx, authUID, limit, cursor)
	if err != nil {
		return err
	}

	blocks := make([]schemares.Block, len(result.Blocks))
	for i, b := range result.Blocks {
		blocks[i] = schemares.Block{
			ID:            b.ID,
			BlockedUserID: b.BlockedUserID,
			CreatedAt:     b.CreatedAt.UTC().Format(time.RFC3339),
		}
	}

	return c.JSON(http.StatusOK, schemares.BlockListResponse{
		Blocks: blocks,
		Pagination: schemares.BlockListPagination{
			NextCursor: result.NextCursor,
			HasMore:    result.HasMore,
		},
	})
}
