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

type pushTokenHandler struct {
	log              *zap.Logger
	pushTokenUsecase usecase.PushTokenUsecase
}

func newPushTokenHandler(log *zap.Logger, pushTokenUsecase usecase.PushTokenUsecase) *pushTokenHandler {
	return &pushTokenHandler{log: log, pushTokenUsecase: pushTokenUsecase}
}

// createPushToken godoc
// @ID           createPushToken
// @Summary      プッシュトークン登録（upsert）
// @Description  device_id が既存なら更新して 200、新規なら 201 を返す
// @Tags         push-tokens
// @Accept       json
// @Produce      json
// @Security     BearerAuth
// @Param        body  body      schemareq.CreatePushTokenRequest  true  "プッシュトークン登録リクエスト"
// @Success      200   {object}  schemares.DeviceResponse  "既存デバイスを更新"
// @Success      201   {object}  schemares.DeviceResponse  "新規デバイスを登録"
// @Failure      400   {object}  errorResponse
// @Failure      401   {object}  errorResponse
// @Failure      500   {object}  errorResponse
// @Router       /api/v1/users/me/push-tokens [post]
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

// patchPushToken godoc
// @ID           patchPushToken
// @Summary      プッシュトークン更新
// @Description  指定デバイスのトークン・有効フラグ・アプリバージョンを部分更新する
// @Tags         push-tokens
// @Accept       json
// @Produce      json
// @Security     BearerAuth
// @Param        id    path      string                            true  "デバイス ID"
// @Param        body  body      schemareq.UpdatePushTokenRequest  true  "プッシュトークン更新リクエスト"
// @Success      200   {object}  schemares.DeviceResponse
// @Failure      400   {object}  errorResponse
// @Failure      401   {object}  errorResponse
// @Failure      404   {object}  errorResponse
// @Failure      500   {object}  errorResponse
// @Router       /api/v1/users/me/push-tokens/{id} [patch]
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

// deletePushToken godoc
// @ID           deletePushToken
// @Summary      プッシュトークン削除
// @Description  指定デバイスのレコードを削除する
// @Tags         push-tokens
// @Security     BearerAuth
// @Param        id   path  string  true  "デバイス ID"
// @Success      204
// @Failure      401  {object}  errorResponse
// @Failure      404  {object}  errorResponse
// @Failure      500  {object}  errorResponse
// @Router       /api/v1/users/me/push-tokens/{id} [delete]
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
