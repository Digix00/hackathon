package handler

import (
	"context"
	"errors"
	"net/http"
	"time"

	"github.com/labstack/echo/v4"
	"gorm.io/gorm"

	schemares "hackathon/internal/handler/schema/response"
	"hackathon/internal/infra/rdb/model"
)

func (h *userHandler) loadCurrentUser(ctx context.Context, authUID string) (model.User, error) {
	var user model.User
	err := h.db.WithContext(ctx).
		Where("auth_provider = ? AND provider_user_id = ?", firebaseProvider, authUID).
		First(&user).Error
	if errors.Is(err, gorm.ErrRecordNotFound) {
		return model.User{}, echo.NewHTTPError(http.StatusNotFound, map[string]any{
			"code":    "NOT_FOUND",
			"message": "User was not found",
			"details": nil,
		})
	}
	if err != nil {
		return model.User{}, err
	}
	return user, nil
}

func settingsToResponse(settings model.UserSettings) schemares.Settings {
	return schemares.Settings{
		BleEnabled:                      settings.BleEnabled,
		LocationEnabled:                 settings.LocationEnabled,
		DetectionDistance:               settings.DetectionDistance,
		ScheduleEnabled:                 settings.ScheduleEnabled,
		ScheduleStartTime:               settings.ScheduleStartTime,
		ScheduleEndTime:                 settings.ScheduleEndTime,
		ProfileVisible:                  settings.ProfileVisible,
		TrackVisible:                    settings.TrackVisible,
		NotificationEnabled:             settings.NotificationEnabled,
		EncounterNotificationEnabled:    settings.EncounterNotificationEnabled,
		BatchNotificationEnabled:        settings.BatchNotificationEnabled,
		NotificationFrequency:           settings.NotificationFrequency,
		CommentNotificationEnabled:      settings.CommentNotificationEnabled,
		LikeNotificationEnabled:         settings.LikeNotificationEnabled,
		AnnouncementNotificationEnabled: settings.AnnouncementNotificationEnabled,
		ThemeMode:                       settings.ThemeMode,
		UpdatedAt:                       settings.UpdatedAt.UTC().Format(time.RFC3339),
	}
}

func deviceToResponse(device model.UserDevice) schemares.Device {
	return schemares.Device{
		ID:        device.ID,
		Platform:  device.Platform,
		DeviceID:  device.DeviceID,
		Enabled:   device.Enabled,
		UpdatedAt: device.UpdatedAt.UTC().Format(time.RFC3339),
	}
}
