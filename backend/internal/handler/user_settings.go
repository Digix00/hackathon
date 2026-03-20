package handler

import (
	"net/http"

	"github.com/labstack/echo/v4"
	"go.uber.org/zap"

	"hackathon/internal/handler/middleware"
	schemareq "hackathon/internal/handler/schema/request"
	schemares "hackathon/internal/handler/schema/response"
	"hackathon/internal/usecase"
	usecasedto "hackathon/internal/usecase/dto"
)

type settingsHandler struct {
	log             *zap.Logger
	settingsUsecase usecase.SettingsUsecase
}

func newSettingsHandler(log *zap.Logger, settingsUsecase usecase.SettingsUsecase) *settingsHandler {
	return &settingsHandler{log: log, settingsUsecase: settingsUsecase}
}

// getMySettings godoc
// @ID           getMySettings
// @Summary      自分の設定取得
// @Description  認証中のユーザーのアプリ設定を返す
// @Tags         settings
// @Produce      json
// @Security     BearerAuth
// @Success      200  {object}  schemares.SettingsResponse
// @Failure      401  {object}  errorResponse
// @Failure      404  {object}  errorResponse
// @Failure      500  {object}  errorResponse
// @Router       /api/v1/users/me/settings [get]
func (h *settingsHandler) getMySettings(c echo.Context) error {
	uid, ok := middleware.UserIDFromContext(c)
	if !ok {
		return errUnauthorized()
	}

	settings, err := h.settingsUsecase.GetMySettings(c.Request().Context(), uid)
	if err != nil {
		return err
	}

	return c.JSON(http.StatusOK, schemares.SettingsResponse{Settings: settingsDTOToResponse(settings)})
}

// patchMySettings godoc
// @ID           patchMySettings
// @Summary      自分の設定更新
// @Description  指定したフィールドだけを部分更新する（null フィールドは変更しない）
// @Tags         settings
// @Accept       json
// @Produce      json
// @Security     BearerAuth
// @Param        body  body      schemareq.UpdateSettingsRequest  true  "設定更新リクエスト"
// @Success      200   {object}  schemares.SettingsResponse
// @Failure      400   {object}  errorResponse
// @Failure      401   {object}  errorResponse
// @Failure      404   {object}  errorResponse
// @Failure      500   {object}  errorResponse
// @Router       /api/v1/users/me/settings [patch]
func (h *settingsHandler) patchMySettings(c echo.Context) error {
	uid, ok := middleware.UserIDFromContext(c)
	if !ok {
		return errUnauthorized()
	}

	var req schemareq.UpdateSettingsRequest
	if err := c.Bind(&req); err != nil {
		return errBadRequest("Invalid request body")
	}

	settings, err := h.settingsUsecase.PatchMySettings(c.Request().Context(), uid, usecasedto.UpdateSettingsInput{
		DetectionDistance:               req.DetectionDistance,
		NotificationFrequency:           req.NotificationFrequency,
		ThemeMode:                       req.ThemeMode,
		ScheduleStartTime:               req.ScheduleStartTime,
		ScheduleEndTime:                 req.ScheduleEndTime,
		BleEnabled:                      req.BleEnabled,
		LocationEnabled:                 req.LocationEnabled,
		ScheduleEnabled:                 req.ScheduleEnabled,
		ProfileVisible:                  req.ProfileVisible,
		TrackVisible:                    req.TrackVisible,
		NotificationEnabled:             req.NotificationEnabled,
		EncounterNotificationEnabled:    req.EncounterNotificationEnabled,
		BatchNotificationEnabled:        req.BatchNotificationEnabled,
		CommentNotificationEnabled:      req.CommentNotificationEnabled,
		LikeNotificationEnabled:         req.LikeNotificationEnabled,
		AnnouncementNotificationEnabled: req.AnnouncementNotificationEnabled,
	})
	if err != nil {
		return err
	}

	return c.JSON(http.StatusOK, schemares.SettingsResponse{Settings: settingsDTOToResponse(settings)})
}
