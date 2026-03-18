package handler

import (
	"errors"
	"net/http"
	"strconv"

	"github.com/labstack/echo/v4"

	domainerrs "hackathon/internal/domain/errs"
	"hackathon/internal/handler/middleware"
	schemares "hackathon/internal/handler/schema/response"
	"hackathon/internal/usecase"
)

type musicHandler struct {
	musicUsecase usecase.MusicUsecase
}

func newMusicHandler(musicUsecase usecase.MusicUsecase) *musicHandler {
	return &musicHandler{musicUsecase: musicUsecase}
}

// authorize godoc
// @ID           getMusicAuthorizeURL
// @Summary      音楽サービス連携の認可 URL を取得
// @Description  Spotify / Apple Music の OAuth 認可開始 URL と state を返す
// @Tags         music-connections
// @Produce      json
// @Security     BearerAuth
// @Param        provider  path      string  true  "provider" Enums(spotify,apple_music)
// @Success      200       {object}  schemares.MusicAuthorizeResponse
// @Failure      400       {object}  errorResponse
// @Failure      401       {object}  errorResponse
// @Failure      404       {object}  errorResponse
// @Failure      500       {object}  errorResponse
// @Router       /api/v1/music-connections/{provider}/authorize [get]
func (h *musicHandler) authorize(c echo.Context) error {
	uid, ok := middleware.UserIDFromContext(c)
	if !ok {
		return errUnauthorized()
	}
	result, err := h.musicUsecase.GetAuthorizeURL(c.Request().Context(), uid, c.Param("provider"))
	if err != nil {
		return err
	}
	return c.JSON(http.StatusOK, schemares.MusicAuthorizeResponse{AuthorizeURL: result.AuthorizeURL, State: result.State})
}

// callback godoc
// @ID           handleMusicCallback
// @Summary      音楽サービス連携のコールバック
// @Description  OAuth コールバックを処理し、アプリ deep link へリダイレクトする
// @Tags         music-connections
// @Param        provider  path   string  true  "provider" Enums(spotify,apple_music)
// @Param        code      query  string  true  "authorization code"
// @Param        state     query  string  true  "signed state"
// @Success      302
// @Failure      302
// @Router       /api/v1/music-connections/{provider}/callback [get]
func (h *musicHandler) callback(c echo.Context) error {
	provider := c.Param("provider")
	if provider != "spotify" && provider != "apple_music" {
		provider = "unknown"
	}
	code := c.QueryParam("code")
	state := c.QueryParam("state")
	result := "success"
	errorCode := ""
	if err := h.musicUsecase.HandleCallback(c.Request().Context(), provider, code, state); err != nil {
		result = "error"
		errorCode = domainErrorCode(err)
	}
	return c.Redirect(http.StatusFound, h.musicUsecase.CallbackRedirectURL(provider, result, errorCode))
}

// listConnections godoc
// @ID           listMusicConnections
// @Summary      自分の音楽連携一覧を取得
// @Description  連携済み Spotify / Apple Music アカウント一覧を返す
// @Tags         music-connections
// @Produce      json
// @Security     BearerAuth
// @Success      200  {object}  schemares.MusicConnectionsResponse
// @Failure      401  {object}  errorResponse
// @Failure      404  {object}  errorResponse
// @Failure      500  {object}  errorResponse
// @Router       /api/v1/users/me/music-connections [get]
func (h *musicHandler) listConnections(c echo.Context) error {
	uid, ok := middleware.UserIDFromContext(c)
	if !ok {
		return errUnauthorized()
	}
	connections, err := h.musicUsecase.ListConnections(c.Request().Context(), uid)
	if err != nil {
		return err
	}
	return c.JSON(http.StatusOK, musicConnectionsToResponse(connections))
}

// deleteConnection godoc
// @ID           deleteMusicConnection
// @Summary      音楽連携を解除
// @Description  指定 provider の音楽連携を解除する
// @Tags         music-connections
// @Security     BearerAuth
// @Param        provider  path  string  true  "provider" Enums(spotify,apple_music)
// @Success      204
// @Failure      400  {object}  errorResponse
// @Failure      401  {object}  errorResponse
// @Failure      404  {object}  errorResponse
// @Failure      500  {object}  errorResponse
// @Router       /api/v1/users/me/music-connections/{provider} [delete]
func (h *musicHandler) deleteConnection(c echo.Context) error {
	uid, ok := middleware.UserIDFromContext(c)
	if !ok {
		return errUnauthorized()
	}
	if err := h.musicUsecase.DeleteConnection(c.Request().Context(), uid, c.Param("provider")); err != nil {
		return err
	}
	return c.NoContent(http.StatusNoContent)
}

// searchTracks godoc
// @ID           searchTracks
// @Summary      楽曲検索
// @Description  連携済み Spotify アカウントを使ってトラック検索する
// @Tags         tracks
// @Produce      json
// @Security     BearerAuth
// @Param        q       query     string  true   "query"
// @Param        limit   query     int     false  "limit (max 50)"
// @Param        cursor  query     string  false  "opaque cursor"
// @Success      200     {object}  schemares.TrackSearchResponse
// @Failure      400     {object}  errorResponse
// @Failure      401     {object}  errorResponse
// @Failure      404     {object}  errorResponse
// @Failure      500     {object}  errorResponse
// @Router       /api/v1/tracks/search [get]
func (h *musicHandler) searchTracks(c echo.Context) error {
	uid, ok := middleware.UserIDFromContext(c)
	if !ok {
		return errUnauthorized()
	}
	limit := 20
	if raw := c.QueryParam("limit"); raw != "" {
		parsed, err := strconv.Atoi(raw)
		if err != nil {
			return errBadRequest("limit must be an integer")
		}
		limit = parsed
	}
	var cursor *string
	if raw := c.QueryParam("cursor"); raw != "" {
		cursor = &raw
	}
	result, err := h.musicUsecase.SearchTracks(c.Request().Context(), uid, c.QueryParam("q"), limit, cursor)
	if err != nil {
		return err
	}
	tracks := make([]schemares.Track, 0, len(result.Tracks))
	for _, track := range result.Tracks {
		tracks = append(tracks, trackDTOToResponse(track))
	}
	return c.JSON(http.StatusOK, schemares.TrackSearchResponse{Tracks: tracks, Pagination: schemares.TrackSearchPagination{NextCursor: result.NextCursor, HasMore: result.HasMore}})
}

// getTrack godoc
// @ID           getTrack
// @Summary      楽曲詳細取得
// @Description  連携済み音楽アカウント経由でトラック詳細を取得する
// @Tags         tracks
// @Produce      json
// @Security     BearerAuth
// @Param        id   path      string  true  "track id"
// @Success      200  {object}  schemares.TrackResponse
// @Failure      400  {object}  errorResponse
// @Failure      401  {object}  errorResponse
// @Failure      404  {object}  errorResponse
// @Failure      500  {object}  errorResponse
// @Router       /api/v1/tracks/{id} [get]
func (h *musicHandler) getTrack(c echo.Context) error {
	uid, ok := middleware.UserIDFromContext(c)
	if !ok {
		return errUnauthorized()
	}
	track, err := h.musicUsecase.GetTrack(c.Request().Context(), uid, c.Param("id"))
	if err != nil {
		return err
	}
	return c.JSON(http.StatusOK, schemares.TrackResponse{Track: trackDTOToResponse(track)})
}

func domainErrorCode(err error) string {
	var domainErr *domainerrs.DomainError
	if errors.As(err, &domainErr) {
		return string(domainErr.Code)
	}
	return "INTERNAL"
}
