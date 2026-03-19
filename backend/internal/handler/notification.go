package handler

import (
	"net/http"
	"strconv"
	"time"

	"github.com/labstack/echo/v4"

	"hackathon/internal/handler/middleware"
	schemares "hackathon/internal/handler/schema/response"
	"hackathon/internal/usecase"
	usecasedto "hackathon/internal/usecase/dto"
)

type notificationHandler struct {
	notificationUsecase usecase.NotificationUsecase
}

func newNotificationHandler(u usecase.NotificationUsecase) *notificationHandler {
	return &notificationHandler{notificationUsecase: u}
}

// listNotifications godoc
// @ID           listNotifications
// @Summary      通知一覧取得
// @Description  現在ログインしているユーザーの通知一覧を取得する
// @Tags         notifications
// @Produce      json
// @Param        limit   query  int  false  "取得件数（デフォルト: 20, 最大: 100）"
// @Param        offset  query  int  false  "オフセット（デフォルト: 0）"
// @Success      200  {object}  schemares.NotificationListResponse
// @Failure      401  {object}  errorResponse
// @Failure      500  {object}  errorResponse
// @Security     BearerAuth
// @Router       /api/v1/users/me/notifications [get]
func (h *notificationHandler) listNotifications(c echo.Context) error {
	uid, ok := middleware.UserIDFromContext(c)
	if !ok {
		return errUnauthorized()
	}

	limit := 20
	offset := 0
	if v := c.QueryParam("limit"); v != "" {
		if n, err := strconv.Atoi(v); err == nil {
			limit = n
		}
	}
	if v := c.QueryParam("offset"); v != "" {
		if n, err := strconv.Atoi(v); err == nil {
			offset = n
		}
	}

	out, err := h.notificationUsecase.ListNotifications(c.Request().Context(), uid, limit, offset)
	if err != nil {
		return err
	}

	return c.JSON(http.StatusOK, schemares.NotificationListResponse{
		Notifications: toNotificationItems(out.Notifications),
		UnreadCount:   out.UnreadCount,
		Total:         out.Total,
	})
}

// markNotificationAsRead godoc
// @ID           markNotificationAsRead
// @Summary      通知を既読にする
// @Description  指定した通知を既読状態にする
// @Tags         notifications
// @Produce      json
// @Param        id  path  string  true  "通知 ID"
// @Success      204
// @Failure      401  {object}  errorResponse
// @Failure      404  {object}  errorResponse
// @Failure      500  {object}  errorResponse
// @Security     BearerAuth
// @Router       /api/v1/users/me/notifications/{id}/read [patch]
func (h *notificationHandler) markNotificationAsRead(c echo.Context) error {
	uid, ok := middleware.UserIDFromContext(c)
	if !ok {
		return errUnauthorized()
	}

	id := c.Param("id")
	if id == "" {
		return errBadRequest("id path param is required")
	}

	if err := h.notificationUsecase.MarkNotificationAsRead(c.Request().Context(), uid, id); err != nil {
		return err
	}

	return c.NoContent(http.StatusNoContent)
}

func toNotificationItems(notifications []usecasedto.NotificationOutput) []schemares.NotificationItem {
	items := make([]schemares.NotificationItem, len(notifications))
	for i, n := range notifications {
		var readAt *string
		if n.ReadAt != nil {
			formatted := n.ReadAt.UTC().Format(time.RFC3339)
			readAt = &formatted
		}
		items[i] = schemares.NotificationItem{
			ID:          n.ID,
			EncounterID: n.EncounterID,
			Status:      n.Status,
			ReadAt:      readAt,
			CreatedAt:   n.CreatedAt.UTC().Format(time.RFC3339),
		}
	}
	return items
}
