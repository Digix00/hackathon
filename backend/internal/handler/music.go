package handler

import (
	"net/http"
	"strconv"

	"github.com/labstack/echo/v4"

	"hackathon/internal/handler/middleware"
	schemares "hackathon/internal/handler/schema/response"
	"hackathon/internal/usecase"
	usecasedto "hackathon/internal/usecase/dto"
)

type musicHandler struct {
	musicUsecase usecase.MusicUsecase
}

func newMusicHandler(musicUsecase usecase.MusicUsecase) *musicHandler {
	return &musicHandler{musicUsecase: musicUsecase}
}

// getMusicAuthorizeURL godoc
// @ID           getMusicAuthorizeURL
// @Summary      音楽サービス OAuth 認可 URL 取得
// @Description  指定プロバイダーの OAuth 認可フローを開始し authorize_url を返す
// @Tags         music-connections
// @Produce      json
// @Security     BearerAuth
// @Param        provider  path      string  true  "spotify | apple_music"
// @Success      200       {object}  schemares.MusicAuthorizeResponse
// @Failure      400       {object}  errorResponse
// @Failure      401       {object}  errorResponse
// @Router       /api/v1/music-connections/{provider}/authorize [get]
func (h *musicHandler) getMusicAuthorizeURL(c echo.Context) error {
	uid, ok := middleware.UserIDFromContext(c)
	if !ok {
		return errUnauthorized()
	}
	provider := c.Param("provider")

	authorizeURL, state, err := h.musicUsecase.AuthorizeURL(c.Request().Context(), uid, provider)
	if err != nil {
		return err
	}
	return c.JSON(http.StatusOK, schemares.MusicAuthorizeResponse{
		AuthorizeURL: authorizeURL,
		State:        state,
	})
}

// handleMusicCallback godoc
// @ID           handleMusicCallback
// @Summary      音楽サービス OAuth コールバック
// @Description  OAuth コールバックを処理し、認可コードをトークンに交換してアプリへリダイレクト
// @Tags         music-connections
// @Param        provider  path   string  true   "spotify | apple_music"
// @Param        code      query  string  true   "認可コード"
// @Param        state     query  string  true   "CSRF state"
// @Success      302
// @Failure      302
// @Router       /api/v1/music-connections/{provider}/callback [get]
func (h *musicHandler) handleMusicCallback(c echo.Context) error {
	provider := c.Param("provider")
	code := c.QueryParam("code")
	state := c.QueryParam("state")

	if code == "" || state == "" {
		redirectURL := "digix://music-connections/" + provider + "/callback?result=error&error_code=MISSING_PARAMS"
		return c.Redirect(http.StatusFound, redirectURL)
	}

	_, err := h.musicUsecase.HandleCallback(c.Request().Context(), provider, code, state)
	if err != nil {
		c.Logger().Errorf("music callback failed: provider=%s err=%v", provider, err)
		redirectURL := "digix://music-connections/" + provider + "/callback?result=error&error_code=CALLBACK_FAILED"
		return c.Redirect(http.StatusFound, redirectURL)
	}

	redirectURL := "digix://music-connections/" + provider + "/callback?result=success"
	return c.Redirect(http.StatusFound, redirectURL)
}

// getMyMusicConnections godoc
// @ID           getMyMusicConnections
// @Summary      音楽サービス連携一覧取得
// @Description  自分の音楽サービス連携一覧を返す
// @Tags         music-connections
// @Produce      json
// @Security     BearerAuth
// @Success      200  {object}  schemares.MusicConnectionsResponse
// @Failure      401  {object}  errorResponse
// @Router       /api/v1/users/me/music-connections [get]
func (h *musicHandler) getMyMusicConnections(c echo.Context) error {
	uid, ok := middleware.UserIDFromContext(c)
	if !ok {
		return errUnauthorized()
	}

	conns, err := h.musicUsecase.ListMusicConnections(c.Request().Context(), uid)
	if err != nil {
		return err
	}

	items := make([]schemares.MusicConnectionItem, len(conns))
	for i, conn := range conns {
		items[i] = musicConnectionDTOToItem(conn)
	}
	return c.JSON(http.StatusOK, schemares.MusicConnectionsResponse{MusicConnections: items})
}

// deleteMyMusicConnection godoc
// @ID           deleteMyMusicConnection
// @Summary      音楽サービス連携解除
// @Description  指定プロバイダーの連携を解除する
// @Tags         music-connections
// @Security     BearerAuth
// @Param        provider  path  string  true  "spotify | apple_music"
// @Success      204
// @Failure      401  {object}  errorResponse
// @Failure      404  {object}  errorResponse
// @Router       /api/v1/users/me/music-connections/{provider} [delete]
func (h *musicHandler) deleteMyMusicConnection(c echo.Context) error {
	uid, ok := middleware.UserIDFromContext(c)
	if !ok {
		return errUnauthorized()
	}
	provider := c.Param("provider")

	if err := h.musicUsecase.DeleteMusicConnection(c.Request().Context(), uid, provider); err != nil {
		return err
	}
	return c.NoContent(http.StatusNoContent)
}

// searchTracks godoc
// @ID           searchTracks
// @Summary      トラック検索
// @Description  Spotify Web API にプロキシするトラック検索
// @Tags         tracks
// @Produce      json
// @Security     BearerAuth
// @Param        q       query     string  true   "検索キーワード"
// @Param        limit   query     int     false  "件数（省略時20、最大50）"
// @Param        cursor  query     string  false  "次ページカーソル"
// @Success      200     {object}  schemares.TrackSearchResponse
// @Failure      400     {object}  errorResponse
// @Failure      401     {object}  errorResponse
// @Router       /api/v1/tracks/search [get]
func (h *musicHandler) searchTracks(c echo.Context) error {
	uid, ok := middleware.UserIDFromContext(c)
	if !ok {
		return errUnauthorized()
	}

	q := c.QueryParam("q")
	cursor := c.QueryParam("cursor")
	limit := 20
	if l := c.QueryParam("limit"); l != "" {
		if v, err := strconv.Atoi(l); err == nil && v > 0 {
			limit = v
		}
	}

	result, err := h.musicUsecase.SearchTracks(c.Request().Context(), uid, q, limit, cursor)
	if err != nil {
		return err
	}

	items := make([]schemares.TrackItem, len(result.Tracks))
	for i, t := range result.Tracks {
		items[i] = trackDTOToItem(t)
	}
	return c.JSON(http.StatusOK, schemares.TrackSearchResponse{
		Tracks: items,
		Pagination: schemares.PaginationResult{
			NextCursor: result.NextCursor,
			HasMore:    result.HasMore,
		},
	})
}

// getTrack godoc
// @ID           getTrack
// @Summary      トラック詳細取得
// @Description  指定トラックの詳細を返す（ID: <provider>:track:<external_id>）
// @Tags         tracks
// @Produce      json
// @Security     BearerAuth
// @Param        id  path      string  true  "トラック ID（例: spotify:track:123）"
// @Success      200 {object}  schemares.TrackDetailResponse
// @Failure      400 {object}  errorResponse
// @Failure      401 {object}  errorResponse
// @Failure      404 {object}  errorResponse
// @Router       /api/v1/tracks/{id} [get]
func (h *musicHandler) getTrack(c echo.Context) error {
	uid, ok := middleware.UserIDFromContext(c)
	if !ok {
		return errUnauthorized()
	}
	id := c.Param("id")

	track, err := h.musicUsecase.GetTrack(c.Request().Context(), uid, id)
	if err != nil {
		return err
	}
	return c.JSON(http.StatusOK, schemares.TrackDetailResponse{
		Track: schemares.TrackDetailItem{
			TrackItem:  trackDTOToItem(track),
			AlbumName:  track.AlbumName,
			DurationMs: track.DurationMs,
		},
	})
}

// ─── helpers ──────────────────────────────────────────────────────────────────

func musicConnectionDTOToItem(dto usecasedto.MusicConnectionDTO) schemares.MusicConnectionItem {
	return schemares.MusicConnectionItem{
		Provider:         dto.Provider,
		ProviderUserID:   dto.ProviderUserID,
		ProviderUsername: dto.ProviderUsername,
		ExpiresAt:        dto.ExpiresAt,
		UpdatedAt:        dto.UpdatedAt,
	}
}

func trackDTOToItem(dto usecasedto.TrackDTO) schemares.TrackItem {
	return schemares.TrackItem{
		ID:         dto.ID,
		Title:      dto.Title,
		ArtistName: dto.ArtistName,
		ArtworkURL: dto.ArtworkURL,
		PreviewURL: dto.PreviewURL,
	}
}
