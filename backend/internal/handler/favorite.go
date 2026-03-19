package handler

import (
	"net/http"
	"strconv"
	"time"

	"github.com/labstack/echo/v4"

	"hackathon/internal/handler/middleware"
	schemares "hackathon/internal/handler/schema/response"
	"hackathon/internal/usecase"
)

type favoriteHandler struct {
	usecase usecase.FavoriteUsecase
}

func newFavoriteHandler(u usecase.FavoriteUsecase) *favoriteHandler {
	return &favoriteHandler{usecase: u}
}

// addTrackFavorite godoc
// @ID           addTrackFavorite
// @Summary      トラックをお気に入り登録
// @Description  指定したトラックをお気に入りに追加する。既にお気に入り済みの場合はべき等に処理し 200 を返す。
// @Tags         favorites
// @Produce      json
// @Security     BearerAuth
// @Param        id  path  string  true  "トラックID（例: spotify:track:123）"
// @Success      201  {object}  schemares.TrackFavoriteResponse
// @Success      200  {object}  schemares.TrackFavoriteResponse
// @Failure      401  {object}  errorResponse
// @Failure      404  {object}  errorResponse
// @Failure      500  {object}  errorResponse
// @Router       /api/v1/tracks/{id}/favorites [post]
func (h *favoriteHandler) addTrackFavorite(c echo.Context) error {
	ctx := c.Request().Context()
	authUID, ok := middleware.UserIDFromContext(c)
	if !ok {
		return errUnauthorized()
	}

	trackID := c.Param("id")
	if trackID == "" {
		return errBadRequest("id path param is required")
	}

	dto, isNew, err := h.usecase.AddTrackFavorite(ctx, authUID, trackID)
	if err != nil {
		return err
	}

	res := schemares.TrackFavoriteResponse{
		Favorite: schemares.TrackFavorite{
			ResourceType: dto.ResourceType,
			ResourceID:   dto.ResourceID,
			Favorited:    dto.Favorited,
			CreatedAt:    dto.CreatedAt.UTC().Format(time.RFC3339),
		},
	}
	if isNew {
		return c.JSON(http.StatusCreated, res)
	}
	return c.JSON(http.StatusOK, res)
}

// removeTrackFavorite godoc
// @ID           removeTrackFavorite
// @Summary      トラックのお気に入り解除
// @Description  指定したトラックをお気に入りから削除する
// @Tags         favorites
// @Security     BearerAuth
// @Param        id  path  string  true  "トラックID（例: spotify:track:123）"
// @Success      204
// @Failure      401  {object}  errorResponse
// @Failure      404  {object}  errorResponse
// @Failure      500  {object}  errorResponse
// @Router       /api/v1/tracks/{id}/favorites [delete]
func (h *favoriteHandler) removeTrackFavorite(c echo.Context) error {
	ctx := c.Request().Context()
	authUID, ok := middleware.UserIDFromContext(c)
	if !ok {
		return errUnauthorized()
	}

	trackID := c.Param("id")
	if trackID == "" {
		return errBadRequest("id path param is required")
	}

	if err := h.usecase.RemoveTrackFavorite(ctx, authUID, trackID); err != nil {
		return err
	}

	return c.NoContent(http.StatusNoContent)
}

// listTrackFavorites godoc
// @ID           listTrackFavorites
// @Summary      お気に入りトラック一覧取得
// @Description  認証済みユーザーのお気に入りトラック一覧をカーソルページネーションで取得する
// @Tags         favorites
// @Produce      json
// @Security     BearerAuth
// @Param        limit   query     int     false  "取得件数（省略時 20、最大 50）"
// @Param        cursor  query     string  false  "ページネーションカーソル"
// @Success      200  {object}  schemares.TrackFavoriteListResponse
// @Failure      400  {object}  errorResponse
// @Failure      401  {object}  errorResponse
// @Failure      500  {object}  errorResponse
// @Router       /api/v1/users/me/track-favorites [get]
func (h *favoriteHandler) listTrackFavorites(c echo.Context) error {
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

	result, err := h.usecase.ListTrackFavorites(ctx, authUID, limit, cursor)
	if err != nil {
		return err
	}

	tracks := make([]schemares.PublicTrack, len(result.Tracks))
	for i, t := range result.Tracks {
		tracks[i] = schemares.PublicTrack{
			ID:         t.TrackID,
			Title:      t.Title,
			ArtistName: t.ArtistName,
			ArtworkURL: t.ArtworkURL,
			PreviewURL: t.PreviewURL,
		}
	}

	return c.JSON(http.StatusOK, schemares.TrackFavoriteListResponse{
		Tracks: tracks,
		Pagination: schemares.UserTrackPagination{
			NextCursor: result.NextCursor,
			HasMore:    result.HasMore,
		},
	})
}

// listPlaylistFavorites godoc
// @ID           listPlaylistFavorites
// @Summary      お気に入りプレイリスト一覧取得
// @Description  認証済みユーザーのお気に入りプレイリスト一覧をカーソルページネーションで取得する
// @Tags         favorites
// @Produce      json
// @Security     BearerAuth
// @Param        limit   query     int     false  "取得件数（省略時 20、最大 50）"
// @Param        cursor  query     string  false  "ページネーションカーソル"
// @Success      200  {object}  schemares.PlaylistFavoriteListResponse
// @Failure      400  {object}  errorResponse
// @Failure      401  {object}  errorResponse
// @Failure      500  {object}  errorResponse
// @Router       /api/v1/users/me/playlist-favorites [get]
func (h *favoriteHandler) listPlaylistFavorites(c echo.Context) error {
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

	result, err := h.usecase.ListPlaylistFavorites(ctx, authUID, limit, cursor)
	if err != nil {
		return err
	}

	playlists := make([]schemares.PlaylistSummary, len(result.Playlists))
	for i, p := range result.Playlists {
		playlists[i] = playlistDTOToSummaryResponse(p)
	}

	return c.JSON(http.StatusOK, schemares.PlaylistFavoriteListResponse{
		Playlists: playlists,
		Pagination: schemares.UserTrackPagination{
			NextCursor: result.NextCursor,
			HasMore:    result.HasMore,
		},
	})
}
