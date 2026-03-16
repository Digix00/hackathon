package handler

import (
	"errors"
	"net/http"

	"github.com/google/uuid"
	"github.com/labstack/echo/v4"
	"gorm.io/gorm"

	schemareq "hackathon/internal/handler/schema/request"
	schemares "hackathon/internal/handler/schema/response"
	"hackathon/internal/infra/rdb/model"
)

var validPlatforms = map[string]struct{}{
	"ios":     {},
	"android": {},
}

func (h *userHandler) createPushToken(c echo.Context) error {
	uid, ok := userIDFromAuthContext(c)
	if !ok {
		return echo.NewHTTPError(http.StatusUnauthorized, map[string]any{"code": "UNAUTHORIZED", "message": "User context is missing", "details": nil})
	}

	var req schemareq.CreatePushTokenRequest
	if err := c.Bind(&req); err != nil {
		return echo.NewHTTPError(http.StatusBadRequest, map[string]any{"code": "BAD_REQUEST", "message": "Invalid request body", "details": err.Error()})
	}
	if req.Platform == "" || req.DeviceID == "" || req.PushToken == "" {
		return echo.NewHTTPError(http.StatusBadRequest, map[string]any{"code": "BAD_REQUEST", "message": "platform, device_id and push_token are required", "details": nil})
	}
	if _, ok := validPlatforms[req.Platform]; !ok {
		return echo.NewHTTPError(http.StatusBadRequest, map[string]any{"code": "BAD_REQUEST", "message": "platform is invalid", "details": nil})
	}

	user, err := h.loadCurrentUser(c.Request().Context(), uid)
	if err != nil {
		return err
	}

	status := http.StatusCreated
	var device model.UserDevice
	err = h.db.WithContext(c.Request().Context()).Transaction(func(tx *gorm.DB) error {
		findErr := tx.Where("user_id = ? AND platform = ? AND device_id = ?", user.ID, req.Platform, req.DeviceID).First(&device).Error
		if findErr == nil {
			status = http.StatusOK
			device.DeviceToken = req.PushToken
			device.AppVersion = req.AppVersion
			device.Enabled = true
			return tx.Save(&device).Error
		}
		if !errors.Is(findErr, gorm.ErrRecordNotFound) {
			return findErr
		}

		device = model.UserDevice{
			ID:          uuid.NewString(),
			UserID:      user.ID,
			Platform:    req.Platform,
			DeviceID:    req.DeviceID,
			DeviceToken: req.PushToken,
			AppVersion:  req.AppVersion,
			Enabled:     true,
		}
		return tx.Create(&device).Error
	})
	if err != nil {
		return err
	}

	return c.JSON(status, schemares.DeviceResponse{Device: deviceToResponse(device)})
}

func (h *userHandler) patchPushToken(c echo.Context) error {
	uid, ok := userIDFromAuthContext(c)
	if !ok {
		return echo.NewHTTPError(http.StatusUnauthorized, map[string]any{"code": "UNAUTHORIZED", "message": "User context is missing", "details": nil})
	}

	var req schemareq.UpdatePushTokenRequest
	if err := c.Bind(&req); err != nil {
		return echo.NewHTTPError(http.StatusBadRequest, map[string]any{"code": "BAD_REQUEST", "message": "Invalid request body", "details": err.Error()})
	}

	user, err := h.loadCurrentUser(c.Request().Context(), uid)
	if err != nil {
		return err
	}

	var device model.UserDevice
	err = h.db.WithContext(c.Request().Context()).Where("id = ? AND user_id = ?", c.Param("id"), user.ID).First(&device).Error
	if errors.Is(err, gorm.ErrRecordNotFound) {
		return echo.NewHTTPError(http.StatusNotFound, map[string]any{"code": "NOT_FOUND", "message": "Device was not found", "details": nil})
	}
	if err != nil {
		return err
	}

	if req.PushToken != nil && *req.PushToken != "" {
		device.DeviceToken = *req.PushToken
	}
	if req.Enabled != nil {
		device.Enabled = *req.Enabled
	}
	if req.AppVersion != nil {
		device.AppVersion = req.AppVersion
	}

	if err := h.db.WithContext(c.Request().Context()).Save(&device).Error; err != nil {
		return err
	}

	return c.JSON(http.StatusOK, schemares.DeviceResponse{Device: deviceToResponse(device)})
}

func (h *userHandler) deletePushToken(c echo.Context) error {
	uid, ok := userIDFromAuthContext(c)
	if !ok {
		return echo.NewHTTPError(http.StatusUnauthorized, map[string]any{"code": "UNAUTHORIZED", "message": "User context is missing", "details": nil})
	}

	user, err := h.loadCurrentUser(c.Request().Context(), uid)
	if err != nil {
		return err
	}

	result := h.db.WithContext(c.Request().Context()).Where("id = ? AND user_id = ?", c.Param("id"), user.ID).Delete(&model.UserDevice{})
	if result.Error != nil {
		return result.Error
	}
	if result.RowsAffected == 0 {
		return echo.NewHTTPError(http.StatusNotFound, map[string]any{"code": "NOT_FOUND", "message": "Device was not found", "details": nil})
	}

	return c.NoContent(http.StatusNoContent)
}
