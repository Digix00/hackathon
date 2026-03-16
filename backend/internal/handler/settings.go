package handler

import (
	"net/http"

	"github.com/labstack/echo/v4"

	schemareq "hackathon/internal/handler/schema/request"
	schemares "hackathon/internal/handler/schema/response"
	usecasedto "hackathon/internal/usecase/dto"
)

func (h *userHandler) getMySettings(c echo.Context) error {
	uid, ok := userIDFromAuthContext(c)
	if !ok {
		return echo.NewHTTPError(http.StatusUnauthorized, map[string]any{"code": "UNAUTHORIZED", "message": "User context is missing", "details": nil})
	}

	settings, err := h.settingsUsecase.GetMySettings(c.Request().Context(), uid)
	if err != nil {
		return err
	}

	return c.JSON(http.StatusOK, schemares.SettingsResponse{Settings: settingsDTOToResponse(settings)})
}

func (h *userHandler) patchMySettings(c echo.Context) error {
	uid, ok := userIDFromAuthContext(c)
	if !ok {
		return echo.NewHTTPError(http.StatusUnauthorized, map[string]any{"code": "UNAUTHORIZED", "message": "User context is missing", "details": nil})
	}

	var req schemareq.UpdateSettingsRequest
	if err := c.Bind(&req); err != nil {
		return echo.NewHTTPError(http.StatusBadRequest, map[string]any{"code": "BAD_REQUEST", "message": "Invalid request body", "details": err.Error()})
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
