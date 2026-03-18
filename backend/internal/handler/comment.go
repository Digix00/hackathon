package handler

import (
	"net/http"
	"strconv"
	"time"

	"github.com/labstack/echo/v4"

	"hackathon/internal/handler/middleware"
	schemareq "hackathon/internal/handler/schema/request"
	schemares "hackathon/internal/handler/schema/response"
	"hackathon/internal/usecase"
	usecasedto "hackathon/internal/usecase/dto"
)

type commentHandler struct {
	usecase usecase.CommentUsecase
}

func newCommentHandler(u usecase.CommentUsecase) *commentHandler {
	return &commentHandler{usecase: u}
}

// createComment godoc
// @ID           createComment
// @Summary      コメント作成
// @Description  エンカウントにコメントを投稿する
// @Tags         comments
// @Accept       json
// @Produce      json
// @Security     BearerAuth
// @Param        id    path      string                     true  "エンカウント ID"
// @Param        body  body      schemareq.CreateCommentRequest  true  "コメントリクエスト"
// @Success      201   {object}  schemares.CommentResponse
// @Failure      400   {object}  errorResponse
// @Failure      401   {object}  errorResponse
// @Failure      404   {object}  errorResponse
// @Failure      500   {object}  errorResponse
// @Router       /api/v1/encounters/{id}/comments [post]
func (h *commentHandler) createComment(c echo.Context) error {
	ctx := c.Request().Context()
	authUID, ok := middleware.UserIDFromContext(c)
	if !ok {
		return errUnauthorized()
	}

	encounterID := c.Param("id")
	if encounterID == "" {
		return errBadRequest("encounter id is required")
	}

	var req schemareq.CreateCommentRequest
	if err := c.Bind(&req); err != nil {
		return errBadRequest("invalid request body")
	}

	if req.Content == "" {
		return errBadRequest("content is required")
	}

	dto, err := h.usecase.CreateComment(ctx, authUID, encounterID, req.Content)
	if err != nil {
		return err
	}

	return c.JSON(http.StatusCreated, schemares.CommentResponse{
		Comment: toCommentSchema(dto),
	})
}

// listComments godoc
// @ID           listComments
// @Summary      コメント一覧取得
// @Description  エンカウントのコメント一覧を取得する
// @Tags         comments
// @Produce      json
// @Security     BearerAuth
// @Param        id      path   string  true   "エンカウント ID"
// @Param        limit   query  int     false  "取得件数（デフォルト: 20, 最大: 50）"
// @Param        cursor  query  string  false  "ページングカーソル"
// @Success      200   {object}  schemares.CommentListResponse
// @Failure      401   {object}  errorResponse
// @Failure      404   {object}  errorResponse
// @Failure      500   {object}  errorResponse
// @Router       /api/v1/encounters/{id}/comments [get]
func (h *commentHandler) listComments(c echo.Context) error {
	ctx := c.Request().Context()
	authUID, ok := middleware.UserIDFromContext(c)
	if !ok {
		return errUnauthorized()
	}

	encounterID := c.Param("id")
	if encounterID == "" {
		return errBadRequest("encounter id is required")
	}

	limit := 20
	if v := c.QueryParam("limit"); v != "" {
		n, err := strconv.Atoi(v)
		if err != nil || n <= 0 {
			return errBadRequest("limit must be a positive integer")
		}
		if n > 50 {
			n = 50
		}
		limit = n
	}

	cursor := c.QueryParam("cursor")

	out, err := h.usecase.ListComments(ctx, authUID, encounterID, limit, cursor)
	if err != nil {
		return err
	}

	comments := make([]schemares.Comment, len(out.Comments))
	for i, dto := range out.Comments {
		comments[i] = toCommentSchema(dto)
	}

	var nextCursor *string
	if out.NextCursor != "" {
		nc := out.NextCursor
		nextCursor = &nc
	}

	return c.JSON(http.StatusOK, schemares.CommentListResponse{
		Comments: comments,
		Pagination: schemares.Pagination{
			NextCursor: nextCursor,
			HasMore:    out.HasMore,
		},
	})
}

// deleteComment godoc
// @ID           deleteComment
// @Summary      コメント削除
// @Description  自分のコメントを削除する
// @Tags         comments
// @Produce      json
// @Security     BearerAuth
// @Param        id  path  string  true  "コメント ID"
// @Success      204
// @Failure      401  {object}  errorResponse
// @Failure      403  {object}  errorResponse
// @Failure      404  {object}  errorResponse
// @Failure      500  {object}  errorResponse
// @Router       /api/v1/comments/{id} [delete]
func (h *commentHandler) deleteComment(c echo.Context) error {
	ctx := c.Request().Context()
	authUID, ok := middleware.UserIDFromContext(c)
	if !ok {
		return errUnauthorized()
	}

	commentID := c.Param("id")
	if commentID == "" {
		return errBadRequest("comment id is required")
	}

	if err := h.usecase.DeleteComment(ctx, authUID, commentID); err != nil {
		return err
	}

	return c.NoContent(http.StatusNoContent)
}

func toCommentSchema(dto usecasedto.CommentDTO) schemares.Comment {
	return schemares.Comment{
		ID:          dto.ID,
		EncounterID: dto.EncounterID,
		User: schemares.CommentUser{
			ID:          dto.UserID,
			DisplayName: dto.UserName,
			AvatarURL:   dto.UserAvatarURL,
		},
		Content:   dto.Content,
		CreatedAt: dto.CreatedAt.UTC().Format(time.RFC3339),
	}
}
