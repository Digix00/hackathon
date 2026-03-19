package handler

import (
	"errors"
	"net/http"

	"github.com/labstack/echo/v4"

	domainerrs "hackathon/internal/domain/errs"
	"hackathon/internal/handler/middleware"
	schemares "hackathon/internal/handler/schema/response"
	"hackathon/internal/usecase"
)

type songHandler struct {
	usecase usecase.SongUsecase
}

func newSongHandler(u usecase.SongUsecase) *songHandler {
	return &songHandler{usecase: u}
}

// listMySongs godoc
// @ID           listMySongs
// @Summary      自分が参加した楽曲一覧
// @Description  自分がLyricChainに参加して生成された楽曲の一覧を返す。
// @Tags         songs
// @Produce      json
// @Security     BearerAuth
// @Param        cursor  query  string  false  "ページネーションカーソル"
// @Success      200  {object}  schemares.ListUserSongsResponse
// @Failure      401  {object}  errorResponse
// @Failure      500  {object}  errorResponse
// @Router       /api/v1/users/me/songs [get]
func (h *songHandler) listMySongs(c echo.Context) error {
	ctx := c.Request().Context()
	authUID, ok := middleware.UserIDFromContext(c)
	if !ok {
		return errUnauthorized()
	}

	cursor := c.QueryParam("cursor")

	result, err := h.usecase.ListMySongs(ctx, authUID, cursor, 20)
	if err != nil {
		return err
	}

	songs := make([]schemares.UserSong, 0, len(result.Songs))
	for _, s := range result.Songs {
		songs = append(songs, schemares.UserSong{
			ID:               s.ID,
			Title:            s.Title,
			AudioURL:         s.AudioURL,
			ParticipantCount: s.ParticipantCount,
			MyLyric:          s.MyLyric,
			GeneratedAt:      s.GeneratedAt,
			ChainID:          s.ChainID,
		})
	}

	return c.JSON(http.StatusOK, schemares.ListUserSongsResponse{
		Songs: songs,
		Pagination: schemares.SongPagination{
			NextCursor: result.NextCursor,
			HasMore:    result.HasMore,
		},
	})
}

// likeSong godoc
// @ID           likeSong
// @Summary      楽曲にいいね
// @Description  指定した楽曲にいいねする。すでにいいね済みの場合は既存状態を返す。
// @Tags         songs
// @Produce      json
// @Security     BearerAuth
// @Param        id  path  string  true  "楽曲ID"
// @Success      200  {object}  schemares.LikeSongResponse
// @Success      201  {object}  schemares.LikeSongResponse
// @Failure      401  {object}  errorResponse
// @Failure      404  {object}  errorResponse
// @Failure      409  {object}  errorResponse
// @Failure      500  {object}  errorResponse
// @Router       /api/v1/songs/{id}/likes [post]
func (h *songHandler) likeSong(c echo.Context) error {
	ctx := c.Request().Context()
	authUID, ok := middleware.UserIDFromContext(c)
	if !ok {
		return errUnauthorized()
	}

	songID := c.Param("id")
	if songID == "" {
		return errBadRequest("id is required")
	}

	status := http.StatusCreated
	if err := h.usecase.LikeSong(ctx, authUID, songID); err != nil {
		if !errors.Is(err, domainerrs.ErrConflict) {
			return err
		}
		status = http.StatusOK
	}

	songIDCopy := songID
	return c.JSON(status, schemares.LikeSongResponse{
		Like: schemares.LikeSongDetail{
			SongID: &songIDCopy,
			Liked:  true,
		},
	})
}

// unlikeSong godoc
// @ID           unlikeSong
// @Summary      楽曲のいいねを取り消す
// @Description  指定した楽曲のいいねを取り消す。いいねが存在しない場合はエラー。
// @Tags         songs
// @Produce      json
// @Security     BearerAuth
// @Param        id  path  string  true  "楽曲ID"
// @Success      204
// @Failure      401  {object}  errorResponse
// @Failure      404  {object}  errorResponse
// @Failure      500  {object}  errorResponse
// @Router       /api/v1/songs/{id}/likes [delete]
func (h *songHandler) unlikeSong(c echo.Context) error {
	ctx := c.Request().Context()
	authUID, ok := middleware.UserIDFromContext(c)
	if !ok {
		return errUnauthorized()
	}

	songID := c.Param("id")
	if songID == "" {
		return errBadRequest("id is required")
	}

	if err := h.usecase.UnlikeSong(ctx, authUID, songID); err != nil {
		return err
	}

	return c.NoContent(http.StatusNoContent)
}
