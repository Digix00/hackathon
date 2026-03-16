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

type pushTokenHandler struct {
	pushTokenUsecase usecase.PushTokenUsecase
}

func newPushTokenHandler(pushTokenUsecase usecase.PushTokenUsecase) *pushTokenHandler {
	return &pushTokenHandler{pushTokenUsecase: pushTokenUsecase}
}

func (h *pushTokenHandler) createPushToken(c echo.Context) error {
	uid, ok := middleware.UserIDFromContext(c)
	if !ok {
		return errUnauthorized()
	}

	var req schemareq.CreatePushTokenRequest
	if err := c.Bind(&req); err != nil {
		return errBadRequest("Invalid request body")
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

func (h *pushTokenHandler) patchPushToken(c echo.Context) error {
	uid, ok := middleware.UserIDFromContext(c)
	if !ok {
		return errUnauthorized()
	}

	var req schemareq.UpdatePushTokenRequest
	if err := c.Bind(&req); err != nil {
		return errBadRequest("Invalid request body")
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

func (h *pushTokenHandler) deletePushToken(c echo.Context) error {
	uid, ok := middleware.UserIDFromContext(c)
	if !ok {
		return errUnauthorized()
	}

	if err := h.pushTokenUsecase.DeletePushToken(c.Request().Context(), uid, c.Param("id")); err != nil {
		return err
	}

	return c.NoContent(http.StatusNoContent)
}
