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
)

type userTrackHandler struct {
	log     *zap.Logger
	usecase usecase.UserTrackUsecase
}

func newUserTrackHandler(log *zap.Logger, u usecase.UserTrackUsecase) *userTrackHandler {
	return &userTrackHandler{log: log, usecase: u}
}

// addUserTrack godoc
// @ID           addUserTrack
// @Summary      マイトラックに楽曲追加
// @Description  認証済みユーザーのマイトラックに楽曲を追加する。既に登録済みの場合は 200 を返す。
// @Tags         user-tracks
// @Accept       json
// @Produce      json
// @Security     BearerAuth
// @Param        body  body      schemareq.AddUserTrackRequest  true  "トラック追加リクエスト"
// @Success      201   {object}  schemares.UserTrackResponse
// @Success      200   {object}  schemares.UserTrackResponse
// @Failure      400   {object}  errorResponse
// @Failure      401   {object}  errorResponse
// @Failure      404   {object}  errorResponse
// @Failure      500   {object}  errorResponse
// @Router       /api/v1/users/me/tracks [post]
func (h *userTrackHandler) addUserTrack(c echo.Context) error {
	ctx := c.Request().Context()
	authUID, ok := middleware.UserIDFromContext(c)
	if !ok {
		return errUnauthorized()
	}

	var req schemareq.AddUserTrackRequest
	if err := c.Bind(&req); err != nil {
		return errBadRequest("Invalid request body")
	}
	if req.TrackID == "" {
		return errBadRequest("track_id is required")
	}

	dto, isNew, err := h.usecase.AddTrack(ctx, authUID, req.TrackID)
	if err != nil {
		return err
	}

	res := schemares.UserTrackResponse{
		Track: schemares.PublicTrack{
			ID:         dto.TrackID,
			Title:      dto.Title,
			ArtistName: dto.ArtistName,
			ArtworkURL: dto.ArtworkURL,
			PreviewURL: dto.PreviewURL,
		},
	}
	if isNew {
		return c.JSON(http.StatusCreated, res)
	}
	return c.JSON(http.StatusOK, res)
}

// listUserTracks godoc
// @ID           listUserTracks
// @Summary      マイトラック一覧取得
// @Description  認証済みユーザーのマイトラック一覧をカーソルページネーションで取得する
// @Tags         user-tracks
// @Produce      json
// @Security     BearerAuth
// @Param        limit   query     int     false  "取得件数（省略時 20、最大 50）"
// @Param        cursor  query     string  false  "ページネーションカーソル"
// @Success      200  {object}  schemares.UserTrackListResponse
// @Failure      400  {object}  errorResponse
// @Failure      401  {object}  errorResponse
// @Failure      500  {object}  errorResponse
// @Router       /api/v1/users/me/tracks [get]
func (h *userTrackHandler) listUserTracks(c echo.Context) error {
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

	result, err := h.usecase.ListTracks(ctx, authUID, limit, cursor)
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

	return c.JSON(http.StatusOK, schemares.UserTrackListResponse{
		Tracks: tracks,
		Pagination: schemares.UserTrackPagination{
			NextCursor: result.NextCursor,
			HasMore:    result.HasMore,
		},
	})
}

// deleteUserTrack godoc
// @ID           deleteUserTrack
// @Summary      マイトラックから楽曲削除
// @Description  認証済みユーザーのマイトラックから楽曲を削除する
// @Tags         user-tracks
// @Security     BearerAuth
// @Param        id  path  string  true  "トラックID（例: spotify:track:123）"
// @Success      204
// @Failure      401  {object}  errorResponse
// @Failure      404  {object}  errorResponse
// @Failure      500  {object}  errorResponse
// @Router       /api/v1/users/me/tracks/{id} [delete]
func (h *userTrackHandler) deleteUserTrack(c echo.Context) error {
	ctx := c.Request().Context()
	authUID, ok := middleware.UserIDFromContext(c)
	if !ok {
		return errUnauthorized()
	}

	trackID := c.Param("id")
	if trackID == "" {
		return errBadRequest("id path param is required")
	}

	if err := h.usecase.DeleteTrack(ctx, authUID, trackID); err != nil {
		return err
	}

	return c.NoContent(http.StatusNoContent)
}

// getSharedTrack godoc
// @ID           getSharedTrack
// @Summary      シェア中の楽曲取得
// @Description  認証済みユーザーが現在シェア中の楽曲を取得する。未設定の場合は shared_track: null を返す。
// @Tags         shared-track
// @Produce      json
// @Security     BearerAuth
// @Success      200  {object}  schemares.SharedTrackResponse
// @Failure      401  {object}  errorResponse
// @Failure      500  {object}  errorResponse
// @Router       /api/v1/users/me/shared-track [get]
func (h *userTrackHandler) getSharedTrack(c echo.Context) error {
	ctx := c.Request().Context()
	authUID, ok := middleware.UserIDFromContext(c)
	if !ok {
		return errUnauthorized()
	}

	dto, err := h.usecase.GetSharedTrack(ctx, authUID)
	if err != nil {
		return err
	}

	var shared *schemares.SharedTrack
	if dto != nil {
		shared = &schemares.SharedTrack{
			ID:         dto.ID,
			Title:      dto.Title,
			ArtistName: dto.ArtistName,
			ArtworkURL: dto.ArtworkURL,
			PreviewURL: dto.PreviewURL,
			UpdatedAt:  dto.UpdatedAt.UTC().Format(time.RFC3339),
		}
	}

	return c.JSON(http.StatusOK, schemares.SharedTrackResponse{SharedTrack: shared})
}

// upsertSharedTrack godoc
// @ID           upsertSharedTrack
// @Summary      シェア中の楽曲設定・更新
// @Description  認証済みユーザーのシェア中の楽曲を設定または更新する。初回設定時は 201、更新時は 200。
// @Tags         shared-track
// @Accept       json
// @Produce      json
// @Security     BearerAuth
// @Param        body  body      schemareq.UpsertSharedTrackRequest  true  "シェアトラック設定リクエスト"
// @Success      201   {object}  schemares.SharedTrackResponse
// @Success      200   {object}  schemares.SharedTrackResponse
// @Failure      400   {object}  errorResponse
// @Failure      401   {object}  errorResponse
// @Failure      404   {object}  errorResponse
// @Failure      500   {object}  errorResponse
// @Router       /api/v1/users/me/shared-track [put]
func (h *userTrackHandler) upsertSharedTrack(c echo.Context) error {
	ctx := c.Request().Context()
	authUID, ok := middleware.UserIDFromContext(c)
	if !ok {
		return errUnauthorized()
	}

	var req schemareq.UpsertSharedTrackRequest
	if err := c.Bind(&req); err != nil {
		return errBadRequest("Invalid request body")
	}
	if req.TrackID == "" {
		return errBadRequest("track_id is required")
	}

	dto, isNew, err := h.usecase.UpsertSharedTrack(ctx, authUID, req.TrackID)
	if err != nil {
		return err
	}

	res := schemares.SharedTrackResponse{
		SharedTrack: &schemares.SharedTrack{
			ID:         dto.ID,
			Title:      dto.Title,
			ArtistName: dto.ArtistName,
			ArtworkURL: dto.ArtworkURL,
			PreviewURL: dto.PreviewURL,
			UpdatedAt:  dto.UpdatedAt.UTC().Format(time.RFC3339),
		},
	}
	if isNew {
		return c.JSON(http.StatusCreated, res)
	}
	return c.JSON(http.StatusOK, res)
}

// deleteSharedTrack godoc
// @ID           deleteSharedTrack
// @Summary      シェア中の楽曲解除
// @Description  認証済みユーザーのシェア中の楽曲を解除する
// @Tags         shared-track
// @Security     BearerAuth
// @Success      204
// @Failure      401  {object}  errorResponse
// @Failure      404  {object}  errorResponse
// @Failure      500  {object}  errorResponse
// @Router       /api/v1/users/me/shared-track [delete]
func (h *userTrackHandler) deleteSharedTrack(c echo.Context) error {
	ctx := c.Request().Context()
	authUID, ok := middleware.UserIDFromContext(c)
	if !ok {
		return errUnauthorized()
	}

	if err := h.usecase.DeleteSharedTrack(ctx, authUID); err != nil {
		return err
	}

	return c.NoContent(http.StatusNoContent)
}
