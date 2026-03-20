package handler

import (
	"net/http"
	"time"

	"github.com/labstack/echo/v4"
	"go.uber.org/zap"

	"hackathon/internal/handler/middleware"
	schemareq "hackathon/internal/handler/schema/request"
	schemares "hackathon/internal/handler/schema/response"
	"hackathon/internal/usecase"
	usecasedto "hackathon/internal/usecase/dto"
)

type lyricHandler struct {
	log     *zap.Logger
	usecase usecase.LyricUsecase
}

func newLyricHandler(log *zap.Logger, u usecase.LyricUsecase) *lyricHandler {
	return &lyricHandler{log: log, usecase: u}
}

// submitLyric godoc
// @ID           submitLyric
// @Summary      歌詞投稿
// @Description  すれ違い成立時に歌詞を投稿し、LyricChainに追加する。
// @Tags         lyrics
// @Accept       json
// @Produce      json
// @Security     BearerAuth
// @Param        body  body      schemareq.SubmitLyricRequest  true  "歌詞投稿リクエスト"
// @Success      201   {object}  schemares.SubmitLyricResponse
// @Failure      400   {object}  errorResponse
// @Failure      401   {object}  errorResponse
// @Failure      500   {object}  errorResponse
// @Router       /api/v1/lyrics [post]
func (h *lyricHandler) submitLyric(c echo.Context) error {
	ctx := c.Request().Context()
	authUID, ok := middleware.UserIDFromContext(c)
	if !ok {
		return errUnauthorized()
	}

	var req schemareq.SubmitLyricRequest
	if err := c.Bind(&req); err != nil {
		return errBadRequest("Invalid request body")
	}

	if req.EncounterID == "" {
		return errBadRequest("encounter_id is required")
	}
	if req.Content == "" {
		return errBadRequest("content is required")
	}
	if len([]rune(req.Content)) > 100 {
		return errBadRequest("content must be 100 characters or less")
	}

	result, err := h.usecase.SubmitLyric(ctx, authUID, usecasedto.SubmitLyricInput{
		EncounterID: req.EncounterID,
		Content:     req.Content,
	})
	if err != nil {
		return err
	}

	return c.JSON(http.StatusCreated, schemares.SubmitLyricResponse{
		LyricEntry: schemares.SubmitLyricEntry{
			ID:          result.Entry.ID,
			ChainID:     result.Entry.ChainID,
			SequenceNum: result.Entry.SequenceNum,
			Content:     result.Entry.Content,
			CreatedAt:   result.Entry.CreatedAt.UTC().Format(time.RFC3339),
		},
		Chain: schemares.SubmitLyricChain{
			ID:               result.Chain.ID,
			ParticipantCount: result.Chain.ParticipantCount,
			Threshold:        result.Chain.Threshold,
			Status:           result.Chain.Status,
		},
	})
}

// getChainDetail godoc
// @ID           getChainDetail
// @Summary      チェーン詳細取得
// @Description  チェーンの詳細と参加者の歌詞一覧、生成楽曲を取得する。
// @Tags         lyrics
// @Produce      json
// @Security     BearerAuth
// @Param        chain_id  path  string  true  "チェーンID"
// @Success      200  {object}  schemares.ChainDetailResponse
// @Failure      401  {object}  errorResponse
// @Failure      404  {object}  errorResponse
// @Failure      500  {object}  errorResponse
// @Router       /api/v1/lyrics/chains/{chain_id} [get]
func (h *lyricHandler) getChainDetail(c echo.Context) error {
	ctx := c.Request().Context()
	_, ok := middleware.UserIDFromContext(c)
	if !ok {
		return errUnauthorized()
	}

	chainID := c.Param("chain_id")
	if chainID == "" {
		return errBadRequest("chain_id is required")
	}

	detail, err := h.usecase.GetChainDetail(ctx, chainID)
	if err != nil {
		return err
	}

	chainRes := schemares.ChainDetail{
		ID:               detail.Chain.ID,
		Status:           detail.Chain.Status,
		ParticipantCount: detail.Chain.ParticipantCount,
		Threshold:        detail.Chain.Threshold,
		CreatedAt:        detail.Chain.CreatedAt.UTC().Format(time.RFC3339),
	}
	if detail.Chain.CompletedAt != nil {
		s := detail.Chain.CompletedAt.UTC().Format(time.RFC3339)
		chainRes.CompletedAt = &s
	}

	entries := make([]schemares.EntryDetail, 0, len(detail.Entries))
	for _, e := range detail.Entries {
		displayName := ""
		if e.DisplayName != nil {
			displayName = *e.DisplayName
		}
		entries = append(entries, schemares.EntryDetail{
			SequenceNum: e.SequenceNum,
			Content:     e.Content,
			User: schemares.EntryUser{
				ID:          e.UserID,
				DisplayName: displayName,
				AvatarURL:   e.AvatarURL,
			},
		})
	}

	res := schemares.ChainDetailResponse{
		Chain:   chainRes,
		Entries: entries,
	}

	if detail.Song != nil {
		res.Song = &schemares.SongDetail{
			ID:          detail.Song.ID,
			Title:       detail.Song.Title,
			AudioURL:    detail.Song.AudioURL,
			DurationSec: detail.Song.DurationSec,
			Mood:        detail.Song.Mood,
		}
	}

	return c.JSON(http.StatusOK, res)
}
