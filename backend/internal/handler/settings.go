package handler

import (
	"context"
	"errors"
	"net/http"
	"time"

	"github.com/google/uuid"
	"github.com/labstack/echo/v4"
	"gorm.io/gorm"

	schemareq "hackathon/internal/handler/schema/request"
	schemares "hackathon/internal/handler/schema/response"
	"hackathon/internal/infra/rdb/model"
)

var validNotificationFrequencies = map[string]struct{}{
	"immediate": {},
	"hourly":    {},
	"daily":     {},
}

var validThemeModes = map[string]struct{}{
	"light":  {},
	"dark":   {},
	"system": {},
}

func (h *userHandler) getMySettings(c echo.Context) error {
	uid, ok := userIDFromAuthContext(c)
	if !ok {
		return echo.NewHTTPError(http.StatusUnauthorized, map[string]any{"code": "UNAUTHORIZED", "message": "User context is missing", "details": nil})
	}

	user, err := h.loadCurrentUser(c.Request().Context(), uid)
	if err != nil {
		return err
	}

	settings, err := h.getOrCreateSettings(c.Request().Context(), user.ID)
	if err != nil {
		return err
	}

	return c.JSON(http.StatusOK, schemares.SettingsResponse{Settings: settingsToResponse(settings)})
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

	user, err := h.loadCurrentUser(c.Request().Context(), uid)
	if err != nil {
		return err
	}

	var settings model.UserSettings
	err = h.db.WithContext(c.Request().Context()).Transaction(func(tx *gorm.DB) error {
		var innerErr error
		settings, innerErr = h.getOrCreateSettingsTx(tx, user.ID)
		if innerErr != nil {
			return innerErr
		}

		if req.DetectionDistance != nil {
			if *req.DetectionDistance < 10 || *req.DetectionDistance > 100 {
				return echo.NewHTTPError(http.StatusBadRequest, map[string]any{"code": "BAD_REQUEST", "message": "detection_distance must be between 10 and 100", "details": nil})
			}
			settings.DetectionDistance = *req.DetectionDistance
		}
		if req.NotificationFrequency != nil {
			if _, exists := validNotificationFrequencies[*req.NotificationFrequency]; !exists {
				return echo.NewHTTPError(http.StatusBadRequest, map[string]any{"code": "BAD_REQUEST", "message": "notification_frequency is invalid", "details": nil})
			}
			settings.NotificationFrequency = *req.NotificationFrequency
		}
		if req.ThemeMode != nil {
			if _, exists := validThemeModes[*req.ThemeMode]; !exists {
				return echo.NewHTTPError(http.StatusBadRequest, map[string]any{"code": "BAD_REQUEST", "message": "theme_mode is invalid", "details": nil})
			}
			settings.ThemeMode = *req.ThemeMode
		}
		if req.ScheduleStartTime != nil {
			if err := validateClockTime(*req.ScheduleStartTime); err != nil {
				return echo.NewHTTPError(http.StatusBadRequest, map[string]any{"code": "BAD_REQUEST", "message": "schedule_start_time must be HH:MM", "details": nil})
			}
			settings.ScheduleStartTime = req.ScheduleStartTime
		}
		if req.ScheduleEndTime != nil {
			if err := validateClockTime(*req.ScheduleEndTime); err != nil {
				return echo.NewHTTPError(http.StatusBadRequest, map[string]any{"code": "BAD_REQUEST", "message": "schedule_end_time must be HH:MM", "details": nil})
			}
			settings.ScheduleEndTime = req.ScheduleEndTime
		}
		if req.BleEnabled != nil {
			settings.BleEnabled = *req.BleEnabled
		}
		if req.LocationEnabled != nil {
			settings.LocationEnabled = *req.LocationEnabled
		}
		if req.ScheduleEnabled != nil {
			settings.ScheduleEnabled = *req.ScheduleEnabled
		}
		if req.ProfileVisible != nil {
			settings.ProfileVisible = *req.ProfileVisible
		}
		if req.TrackVisible != nil {
			settings.TrackVisible = *req.TrackVisible
		}
		if req.NotificationEnabled != nil {
			settings.NotificationEnabled = *req.NotificationEnabled
		}
		if req.EncounterNotificationEnabled != nil {
			settings.EncounterNotificationEnabled = *req.EncounterNotificationEnabled
		}
		if req.BatchNotificationEnabled != nil {
			settings.BatchNotificationEnabled = *req.BatchNotificationEnabled
		}
		if req.CommentNotificationEnabled != nil {
			settings.CommentNotificationEnabled = *req.CommentNotificationEnabled
		}
		if req.LikeNotificationEnabled != nil {
			settings.LikeNotificationEnabled = *req.LikeNotificationEnabled
		}
		if req.AnnouncementNotificationEnabled != nil {
			settings.AnnouncementNotificationEnabled = *req.AnnouncementNotificationEnabled
		}

		return tx.Save(&settings).Error
	})
	if err != nil {
		return err
	}

	return c.JSON(http.StatusOK, schemares.SettingsResponse{Settings: settingsToResponse(settings)})
}

func (h *userHandler) getOrCreateSettings(ctx context.Context, userID string) (model.UserSettings, error) {
	return h.getOrCreateSettingsTx(h.db.WithContext(ctx), userID)
}

func (h *userHandler) getOrCreateSettingsTx(tx *gorm.DB, userID string) (model.UserSettings, error) {
	var settings model.UserSettings
	err := tx.Where("user_id = ?", userID).First(&settings).Error
	if err == nil {
		return settings, nil
	}
	if !errors.Is(err, gorm.ErrRecordNotFound) {
		return model.UserSettings{}, err
	}

	settings = model.UserSettings{ID: uuid.NewString(), UserID: userID}
	if err := tx.Create(&settings).Error; err != nil {
		return model.UserSettings{}, err
	}
	if err := tx.First(&settings, "id = ?", settings.ID).Error; err != nil {
		return model.UserSettings{}, err
	}
	return settings, nil
}

func validateClockTime(value string) error {
	if value == "" {
		return nil
	}
	_, err := time.Parse("15:04", value)
	return err
}
