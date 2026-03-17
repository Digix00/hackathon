package handler

import (
	"net/http"

	"github.com/labstack/echo/v4"

	"hackathon/internal/handler/middleware"
	schemareq "hackathon/internal/handler/schema/request"
	schemares "hackathon/internal/handler/schema/response"
	"hackathon/internal/usecase"
	usecasedto "hackathon/internal/usecase/dto"
)

type lyricHandler struct {
	lyricUsecase usecase.LyricUsecase
}

func newLyricHandler(lyricUsecase usecase.LyricUsecase) *lyricHandler {
	return &lyricHandler{lyricUsecase: lyricUsecase}
}

// postLyric godoc
// @ID           postLyric
// @Summary      歌詞投稿
// @Description  エンカウントをきっかけに歌詞チェーンへ1行を投稿する。チェーンが threshold に達すると楽曲生成ジョブが登録される。
// @Tags         lyrics
// @Accept       json
// @Produce      json
// @Security     BearerAuth
// @Param        body  body      schemareq.PostLyricRequest  true  "歌詞投稿リクエスト"
// @Success      201   {object}  schemares.PostLyricResponse
// @Failure      400   {object}  errorResponse
// @Failure      401   {object}  errorResponse
// @Failure      409   {object}  errorResponse
// @Router       /api/v1/lyrics [post]
func (h *lyricHandler) postLyric(c echo.Context) error {
	uid, ok := middleware.UserIDFromContext(c)
	if !ok {
		return errUnauthorized()
	}

	var req schemareq.PostLyricRequest
	if err := c.Bind(&req); err != nil {
		return errBadRequest("Invalid request body")
	}
	if req.Content == "" {
		return errBadRequest("content is required")
	}
	if req.EncounterID == "" {
		return errBadRequest("encounter_id is required")
	}

	result, err := h.lyricUsecase.PostLyric(c.Request().Context(), uid, usecase.PostLyricInput{
		EncounterID: req.EncounterID,
		Content:     req.Content,
	})
	if err != nil {
		return err
	}

	return c.JSON(http.StatusCreated, schemares.PostLyricResponse{
		LyricEntry: lyricEntryItemFromDTO(result.Entry),
		Chain:      lyricChainItemFromDTO(result.Chain),
	})
}

// getLyricChain godoc
// @ID           getLyricChain
// @Summary      歌詞チェーン詳細取得
// @Description  チェーンの詳細と全歌詞エントリを返す。completed 時のみ song フィールドが含まれる。
// @Tags         lyrics
// @Produce      json
// @Security     BearerAuth
// @Param        chain_id  path      string  true  "チェーン ID"
// @Success      200       {object}  schemares.LyricChainDetailResponse
// @Failure      401       {object}  errorResponse
// @Failure      404       {object}  errorResponse
// @Router       /api/v1/lyrics/chains/{chain_id} [get]
func (h *lyricHandler) getLyricChain(c echo.Context) error {
	_, ok := middleware.UserIDFromContext(c)
	if !ok {
		return errUnauthorized()
	}
	chainID := c.Param("chain_id")
	if chainID == "" {
		return errBadRequest("chain_id is required")
	}

	detail, err := h.lyricUsecase.GetChain(c.Request().Context(), chainID)
	if err != nil {
		return err
	}

	entries := make([]schemares.LyricEntryWithUserItem, len(detail.Entries))
	for i, e := range detail.Entries {
		entries[i] = lyricEntryWithUserItemFromDTO(e)
	}

	resp := schemares.LyricChainDetailResponse{
		Chain:   lyricChainDetailItemFromDTO(detail.Chain),
		Entries: entries,
		Song:    generatedSongItemFromDTO(detail.Song),
	}

	return c.JSON(http.StatusOK, resp)
}

// ─── helpers ──────────────────────────────────────────────────────────────────

func lyricEntryItemFromDTO(dto usecasedto.LyricEntryDTO) schemares.LyricEntryItem {
	return schemares.LyricEntryItem{
		ID:          dto.ID,
		ChainID:     dto.ChainID,
		SequenceNum: dto.SequenceNum,
		Content:     dto.Content,
		CreatedAt:   dto.CreatedAt,
	}
}

func lyricChainItemFromDTO(dto usecasedto.LyricChainDTO) schemares.LyricChainItem {
	return schemares.LyricChainItem{
		ID:               dto.ID,
		ParticipantCount: dto.ParticipantCount,
		Threshold:        dto.Threshold,
		Status:           dto.Status,
	}
}

func lyricChainDetailItemFromDTO(dto usecasedto.LyricChainDTO) schemares.LyricChainDetailItem {
	return schemares.LyricChainDetailItem{
		ID:               dto.ID,
		Status:           dto.Status,
		ParticipantCount: dto.ParticipantCount,
		Threshold:        dto.Threshold,
	}
}

func lyricEntryWithUserItemFromDTO(dto usecasedto.LyricEntryWithUserDTO) schemares.LyricEntryWithUserItem {
	return schemares.LyricEntryWithUserItem{
		SequenceNum: dto.SequenceNum,
		Content:     dto.Content,
		User: schemares.UserBrief{
			ID:          dto.UserID,
			DisplayName: dto.DisplayName,
			AvatarURL:   dto.AvatarURL,
		},
	}
}

func generatedSongItemFromDTO(dto *usecasedto.GeneratedSongDTO) *schemares.GeneratedSongItem {
	if dto == nil {
		return nil
	}
	return &schemares.GeneratedSongItem{
		ID:          dto.ID,
		Title:       dto.Title,
		AudioURL:    dto.AudioURL,
		DurationSec: dto.DurationSec,
		Mood:        dto.Mood,
	}
}
