package handler

import (
	"net/http"

	"github.com/labstack/echo/v4"

	schemareq "hackathon/internal/handler/schema/request"
	schemares "hackathon/internal/handler/schema/response"
	usecasedto "hackathon/internal/usecase/dto"
)

func (h *userHandler) createPushToken(c echo.Context) error {
	uid, ok := userIDFromAuthContext(c)
	if !ok {
		return echo.NewHTTPError(http.StatusUnauthorized, map[string]any{"code": "UNAUTHORIZED", "message": "User context is missing", "details": nil})
	}

	var req schemareq.CreatePushTokenRequest
	if err := c.Bind(&req); err != nil {
		return echo.NewHTTPError(http.StatusBadRequest, map[string]any{"code": "BAD_REQUEST", "message": "Invalid request body", "details": err.Error()})
	}

	device, created, err := h.pushTokenUsecase.CreatePushToken(c.Request().Context(), uid, usecasedto.CreatePushTokenInput{
		Platform:   req.Platform,
		DeviceID:   req.DeviceID,
		PushToken:  req.PushToken,
		AppVersion: req.AppVersion,
	})
	if err != nil {
		return err
	}

	status := http.StatusOK
	if created {
		status = http.StatusCreated
	}
	return c.JSON(status, schemares.DeviceResponse{Device: deviceDTOToResponse(device)})
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

	device, err := h.pushTokenUsecase.PatchPushToken(c.Request().Context(), uid, c.Param("id"), usecasedto.UpdatePushTokenInput{
		PushToken:  req.PushToken,
		Enabled:    req.Enabled,
		AppVersion: req.AppVersion,
	})
	if err != nil {
		return err
	}

	return c.JSON(http.StatusOK, schemares.DeviceResponse{Device: deviceDTOToResponse(device)})
}

func (h *userHandler) deletePushToken(c echo.Context) error {
	uid, ok := userIDFromAuthContext(c)
	if !ok {
		return echo.NewHTTPError(http.StatusUnauthorized, map[string]any{"code": "UNAUTHORIZED", "message": "User context is missing", "details": nil})
	}

	if err := h.pushTokenUsecase.DeletePushToken(c.Request().Context(), uid, c.Param("id")); err != nil {
		return err
	}

	return c.NoContent(http.StatusNoContent)
}
