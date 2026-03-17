package handler

import (
	"net/http"

	"github.com/labstack/echo/v4"

	"hackathon/internal/handler/middleware"
	"hackathon/internal/handler/schema/response"
	"hackathon/internal/usecase"
)

type bleTokenHandler struct {
	usecase usecase.BleTokenUsecase
}

func newBleTokenHandler(u usecase.BleTokenUsecase) *bleTokenHandler {
	return &bleTokenHandler{usecase: u}
}

// createBleToken godoc
// @Summary      BLE トークン発行
// @Description  現在ログインしているユーザーの新規 BLE トークンを発行する（24時間有効）
// @Tags         ble-tokens
// @Produce      json
// @Success      201  {object}  response.BleTokenResponse
// @Failure      401  {object}  errorResponse
// @Failure      500  {object}  errorResponse
// @Security     BearerAuth
// @Router       /api/v1/ble-tokens [post]
func (h *bleTokenHandler) createBleToken(c echo.Context) error {
	ctx := c.Request().Context()
	authUID, ok := middleware.UserIDFromContext(c)
	if !ok {
		return errUnauthorized()
	}

	dto, err := h.usecase.CreateBleToken(ctx, authUID)
	if err != nil {
		return err
	}

	return c.JSON(http.StatusCreated, response.BleTokenResponse{
		BleToken: response.BleToken{
			Token:     dto.Token,
			ExpiresAt: dto.ValidTo,
		},
	})
}

// getCurrentBleToken godoc
// @Summary      有効な BLE トークン取得
// @Description  現在ログインしているユーザーの有効な最新の BLE トークンを取得する
// @Tags         ble-tokens
// @Produce      json
// @Success      200  {object}  response.BleTokenResponse
// @Failure      401  {object}  errorResponse
// @Failure      404  {object}  errorResponse
// @Failure      500  {object}  errorResponse
// @Security     BearerAuth
// @Router       /api/v1/ble-tokens/current [get]
func (h *bleTokenHandler) getCurrentBleToken(c echo.Context) error {
	ctx := c.Request().Context()
	authUID, ok := middleware.UserIDFromContext(c)
	if !ok {
		return errUnauthorized()
	}

	dto, err := h.usecase.GetCurrentBleToken(ctx, authUID)
	if err != nil {
		return err
	}

	return c.JSON(http.StatusOK, response.BleTokenResponse{
		BleToken: response.BleToken{
			Token:     dto.Token,
			ExpiresAt: dto.ValidTo,
		},
	})
}

// getUserByBleToken godoc
// @Summary      BLE トークンからユーザー情報取得
// @Description  指定した BLE トークンに紐づくユーザーの公開プロフィールを取得する
// @Tags         ble-tokens
// @Produce      json
// @Param        token path string true "対象の BLE トークン"
// @Success      200  {object}  response.PublicUserResponse
// @Failure      401  {object}  errorResponse
// @Failure      404  {object}  errorResponse
// @Failure      500  {object}  errorResponse
// @Security     BearerAuth
// @Router       /api/v1/ble-tokens/{token}/user [get]
func (h *bleTokenHandler) getUserByBleToken(c echo.Context) error {
	ctx := c.Request().Context()
	authUID, ok := middleware.UserIDFromContext(c)
	if !ok {
		return errUnauthorized()
	}
	targetToken := c.Param("token")
	if targetToken == "" {
		return errBadRequest("token path param is required")
	}

	dto, err := h.usecase.GetBleUserByToken(ctx, authUID, targetToken)
	if err != nil {
		return err
	}

	return c.JSON(http.StatusOK, response.PublicUserResponse{
		User: publicUserDTOToResponse(dto),
	})
}
