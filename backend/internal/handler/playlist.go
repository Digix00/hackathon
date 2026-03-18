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

type playlistHandler struct {
	usecase usecase.PlaylistUsecase
}

func newPlaylistHandler(u usecase.PlaylistUsecase) *playlistHandler {
	return &playlistHandler{usecase: u}
}

// createPlaylist godoc
// @ID           createPlaylist
// @Summary      プレイリスト作成
// @Description  認証済みユーザーの新規プレイリストを作成する
// @Tags         playlists
// @Accept       json
// @Produce      json
// @Security     BearerAuth
// @Param        body  body      schemareq.CreatePlaylistRequest  true  "プレイリスト作成リクエスト"
// @Success      201   {object}  schemares.PlaylistResponse
// @Failure      400   {object}  errorResponse
// @Failure      401   {object}  errorResponse
// @Failure      404   {object}  errorResponse
// @Failure      500   {object}  errorResponse
// @Router       /api/v1/playlists [post]
func (h *playlistHandler) createPlaylist(c echo.Context) error {
	ctx := c.Request().Context()
	authUID, ok := middleware.UserIDFromContext(c)
	if !ok {
		return errUnauthorized()
	}

	var req schemareq.CreatePlaylistRequest
	if err := c.Bind(&req); err != nil {
		return errBadRequest("Invalid request body")
	}
	if req.Name == "" {
		return errBadRequest("name is required")
	}

	dto, err := h.usecase.CreatePlaylist(ctx, authUID, usecasedto.CreatePlaylistInput{
		Name:        req.Name,
		Description: req.Description,
		IsPublic:    req.IsPublic,
	})
	if err != nil {
		return err
	}

	return c.JSON(http.StatusCreated, schemares.PlaylistResponse{
		Playlist: playlistDTOToResponse(dto),
	})
}

// getMyPlaylists godoc
// @ID           getMyPlaylists
// @Summary      自分のプレイリスト一覧取得
// @Description  認証済みユーザー自身のプレイリスト一覧を取得する
// @Tags         playlists
// @Produce      json
// @Security     BearerAuth
// @Success      200  {object}  schemares.PlaylistListResponse
// @Failure      401  {object}  errorResponse
// @Failure      404  {object}  errorResponse
// @Failure      500  {object}  errorResponse
// @Router       /api/v1/playlists/me [get]
func (h *playlistHandler) getMyPlaylists(c echo.Context) error {
	ctx := c.Request().Context()
	authUID, ok := middleware.UserIDFromContext(c)
	if !ok {
		return errUnauthorized()
	}

	dtos, err := h.usecase.ListMyPlaylists(ctx, authUID)
	if err != nil {
		return err
	}

	res := make([]schemares.Playlist, len(dtos))
	for i, dto := range dtos {
		res[i] = playlistDTOToResponse(dto)
	}

	return c.JSON(http.StatusOK, schemares.PlaylistListResponse{Playlists: res})
}

// getPlaylist godoc
// @ID           getPlaylist
// @Summary      プレイリスト取得
// @Description  指定したプレイリストをトラック情報付きで取得する（公開プレイリストは誰でも取得可能、非公開は所有者のみ）
// @Tags         playlists
// @Produce      json
// @Security     BearerAuth
// @Param        id   path      string  true  "プレイリストID"
// @Success      200  {object}  schemares.PlaylistResponse
// @Failure      401  {object}  errorResponse
// @Failure      403  {object}  errorResponse
// @Failure      404  {object}  errorResponse
// @Failure      500  {object}  errorResponse
// @Router       /api/v1/playlists/{id} [get]
func (h *playlistHandler) getPlaylist(c echo.Context) error {
	ctx := c.Request().Context()
	authUID, ok := middleware.UserIDFromContext(c)
	if !ok {
		return errUnauthorized()
	}

	playlistID := c.Param("id")
	if playlistID == "" {
		return errBadRequest("id path param is required")
	}

	dto, err := h.usecase.GetPlaylist(ctx, authUID, playlistID)
	if err != nil {
		return err
	}

	return c.JSON(http.StatusOK, schemares.PlaylistResponse{
		Playlist: playlistDTOToResponse(dto),
	})
}

// updatePlaylist godoc
// @ID           updatePlaylist
// @Summary      プレイリスト更新
// @Description  プレイリストの名前・説明・公開設定を更新する（所有者のみ）
// @Tags         playlists
// @Accept       json
// @Produce      json
// @Security     BearerAuth
// @Param        id    path      string                          true  "プレイリストID"
// @Param        body  body      schemareq.UpdatePlaylistRequest  true  "プレイリスト更新リクエスト"
// @Success      200  {object}  schemares.PlaylistResponse
// @Failure      400  {object}  errorResponse
// @Failure      401  {object}  errorResponse
// @Failure      403  {object}  errorResponse
// @Failure      404  {object}  errorResponse
// @Failure      500  {object}  errorResponse
// @Router       /api/v1/playlists/{id} [patch]
func (h *playlistHandler) updatePlaylist(c echo.Context) error {
	ctx := c.Request().Context()
	authUID, ok := middleware.UserIDFromContext(c)
	if !ok {
		return errUnauthorized()
	}

	playlistID := c.Param("id")
	if playlistID == "" {
		return errBadRequest("id path param is required")
	}

	var req schemareq.UpdatePlaylistRequest
	if err := c.Bind(&req); err != nil {
		return errBadRequest("Invalid request body")
	}

	dto, err := h.usecase.UpdatePlaylist(ctx, authUID, playlistID, usecasedto.UpdatePlaylistInput{
		Name:        req.Name,
		Description: req.Description,
		IsPublic:    req.IsPublic,
	})
	if err != nil {
		return err
	}

	return c.JSON(http.StatusOK, schemares.PlaylistResponse{
		Playlist: playlistDTOToResponse(dto),
	})
}

// deletePlaylist godoc
// @ID           deletePlaylist
// @Summary      プレイリスト削除
// @Description  プレイリストを削除する（所有者のみ）
// @Tags         playlists
// @Security     BearerAuth
// @Param        id  path  string  true  "プレイリストID"
// @Success      204
// @Failure      401  {object}  errorResponse
// @Failure      403  {object}  errorResponse
// @Failure      404  {object}  errorResponse
// @Failure      500  {object}  errorResponse
// @Router       /api/v1/playlists/{id} [delete]
func (h *playlistHandler) deletePlaylist(c echo.Context) error {
	ctx := c.Request().Context()
	authUID, ok := middleware.UserIDFromContext(c)
	if !ok {
		return errUnauthorized()
	}

	playlistID := c.Param("id")
	if playlistID == "" {
		return errBadRequest("id path param is required")
	}

	if err := h.usecase.DeletePlaylist(ctx, authUID, playlistID); err != nil {
		return err
	}

	return c.NoContent(http.StatusNoContent)
}

// addPlaylistTrack godoc
// @ID           addPlaylistTrack
// @Summary      プレイリストにトラック追加
// @Description  プレイリストにトラックを追加する（所有者のみ）
// @Tags         playlists
// @Accept       json
// @Produce      json
// @Security     BearerAuth
// @Param        id    path      string                            true  "プレイリストID"
// @Param        body  body      schemareq.AddPlaylistTrackRequest  true  "トラック追加リクエスト"
// @Success      204
// @Failure      400  {object}  errorResponse
// @Failure      401  {object}  errorResponse
// @Failure      403  {object}  errorResponse
// @Failure      404  {object}  errorResponse
// @Failure      409  {object}  errorResponse
// @Failure      500  {object}  errorResponse
// @Router       /api/v1/playlists/{id}/tracks [post]
func (h *playlistHandler) addPlaylistTrack(c echo.Context) error {
	ctx := c.Request().Context()
	authUID, ok := middleware.UserIDFromContext(c)
	if !ok {
		return errUnauthorized()
	}

	playlistID := c.Param("id")
	if playlistID == "" {
		return errBadRequest("id path param is required")
	}

	var req schemareq.AddPlaylistTrackRequest
	if err := c.Bind(&req); err != nil {
		return errBadRequest("Invalid request body")
	}
	if req.TrackID == "" {
		return errBadRequest("track_id is required")
	}

	if err := h.usecase.AddTrack(ctx, authUID, playlistID, req.TrackID); err != nil {
		return err
	}

	return c.NoContent(http.StatusNoContent)
}

// removePlaylistTrack godoc
// @ID           removePlaylistTrack
// @Summary      プレイリストからトラック削除
// @Description  プレイリストからトラックを削除する（所有者のみ）
// @Tags         playlists
// @Security     BearerAuth
// @Param        id       path  string  true  "プレイリストID"
// @Param        trackId  path  string  true  "トラックID"
// @Success      204
// @Failure      401  {object}  errorResponse
// @Failure      403  {object}  errorResponse
// @Failure      404  {object}  errorResponse
// @Failure      500  {object}  errorResponse
// @Router       /api/v1/playlists/{id}/tracks/{trackId} [delete]
func (h *playlistHandler) removePlaylistTrack(c echo.Context) error {
	ctx := c.Request().Context()
	authUID, ok := middleware.UserIDFromContext(c)
	if !ok {
		return errUnauthorized()
	}

	playlistID := c.Param("id")
	if playlistID == "" {
		return errBadRequest("id path param is required")
	}

	trackID := c.Param("trackId")
	if trackID == "" {
		return errBadRequest("trackId path param is required")
	}

	if err := h.usecase.RemoveTrack(ctx, authUID, playlistID, trackID); err != nil {
		return err
	}

	return c.NoContent(http.StatusNoContent)
}

// addPlaylistFavorite godoc
// @ID           addPlaylistFavorite
// @Summary      プレイリストをお気に入り登録
// @Description  指定したプレイリストをお気に入りに追加する（公開プレイリストのみ、または所有者）
// @Tags         playlists
// @Security     BearerAuth
// @Param        id  path  string  true  "プレイリストID"
// @Success      204
// @Failure      401  {object}  errorResponse
// @Failure      404  {object}  errorResponse
// @Failure      409  {object}  errorResponse
// @Failure      500  {object}  errorResponse
// @Router       /api/v1/playlists/{id}/favorites [post]
func (h *playlistHandler) addPlaylistFavorite(c echo.Context) error {
	ctx := c.Request().Context()
	authUID, ok := middleware.UserIDFromContext(c)
	if !ok {
		return errUnauthorized()
	}

	playlistID := c.Param("id")
	if playlistID == "" {
		return errBadRequest("id path param is required")
	}

	if err := h.usecase.AddFavorite(ctx, authUID, playlistID); err != nil {
		return err
	}

	return c.NoContent(http.StatusNoContent)
}

// removePlaylistFavorite godoc
// @ID           removePlaylistFavorite
// @Summary      プレイリストのお気に入り解除
// @Description  指定したプレイリストをお気に入りから削除する
// @Tags         playlists
// @Security     BearerAuth
// @Param        id  path  string  true  "プレイリストID"
// @Success      204
// @Failure      401  {object}  errorResponse
// @Failure      404  {object}  errorResponse
// @Failure      500  {object}  errorResponse
// @Router       /api/v1/playlists/{id}/favorites [delete]
func (h *playlistHandler) removePlaylistFavorite(c echo.Context) error {
	ctx := c.Request().Context()
	authUID, ok := middleware.UserIDFromContext(c)
	if !ok {
		return errUnauthorized()
	}

	playlistID := c.Param("id")
	if playlistID == "" {
		return errBadRequest("id path param is required")
	}

	if err := h.usecase.RemoveFavorite(ctx, authUID, playlistID); err != nil {
		return err
	}

	return c.NoContent(http.StatusNoContent)
}

func playlistDTOToResponse(dto usecasedto.PlaylistDTO) schemares.Playlist {
	tracks := make([]schemares.PlaylistTrack, len(dto.Tracks))
	for i, t := range dto.Tracks {
		tracks[i] = schemares.PlaylistTrack{
			ID:         t.ID,
			TrackID:    t.TrackID,
			Title:      t.Title,
			ArtistName: t.ArtistName,
			ArtworkURL: t.ArtworkURL,
			SortOrder:  t.SortOrder,
			CreatedAt:  t.CreatedAt.UTC().Format(time.RFC3339),
		}
	}

	return schemares.Playlist{
		ID:          dto.ID,
		UserID:      dto.UserID,
		Name:        dto.Name,
		Description: dto.Description,
		IsPublic:    dto.IsPublic,
		Tracks:      tracks,
		CreatedAt:   dto.CreatedAt.UTC().Format(time.RFC3339),
		UpdatedAt:   dto.UpdatedAt.UTC().Format(time.RFC3339),
	}
}
