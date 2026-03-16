package handler

import (
	"context"
	"net/http"
	"time"

	firebaseauth "firebase.google.com/go/v4/auth"
	"github.com/labstack/echo/v4"

	schemareq "hackathon/internal/handler/schema/request"
	schemares "hackathon/internal/handler/schema/response"
	usecasedto "hackathon/internal/usecase/dto"
)

const firebaseProvider = "firebase"

type userHandler struct {
	authUserManager  FirebaseUserManager
	userUsecase      UserUsecase
	settingsUsecase  SettingsUsecase
	pushTokenUsecase PushTokenUsecase
}

type FirebaseUserManager interface {
	DeleteUser(ctx context.Context, uid string) error
}

type UserUsecase interface {
	CreateUser(ctx context.Context, authUID string, input usecasedto.CreateUserInput) (usecasedto.UserDTO, error)
	GetMe(ctx context.Context, authUID string) (usecasedto.UserDTO, error)
	GetUserByID(ctx context.Context, requesterAuthUID string, targetUserID string) (usecasedto.PublicUserDTO, error)
	PatchMe(ctx context.Context, authUID string, input usecasedto.UpdateUserInput) (usecasedto.UserDTO, error)
	DeleteMe(ctx context.Context, authUID string) error
}

type SettingsUsecase interface {
	GetMySettings(ctx context.Context, authUID string) (usecasedto.Settings, error)
	PatchMySettings(ctx context.Context, authUID string, input usecasedto.UpdateSettingsInput) (usecasedto.Settings, error)
}

type PushTokenUsecase interface {
	CreatePushToken(ctx context.Context, authUID string, input usecasedto.CreatePushTokenInput) (usecasedto.Device, bool, error)
	PatchPushToken(ctx context.Context, authUID string, id string, input usecasedto.UpdatePushTokenInput) (usecasedto.Device, error)
	DeletePushToken(ctx context.Context, authUID string, id string) error
}

func newUserHandler(authUserManager FirebaseUserManager, userUsecase UserUsecase, settingsUsecase SettingsUsecase, pushTokenUsecase PushTokenUsecase) *userHandler {
	return &userHandler{
		authUserManager:  authUserManager,
		userUsecase:      userUsecase,
		settingsUsecase:  settingsUsecase,
		pushTokenUsecase: pushTokenUsecase,
	}
}

func (h *userHandler) createUser(c echo.Context) error {
	uid, ok := userIDFromAuthContext(c)
	if !ok {
		return echo.NewHTTPError(http.StatusUnauthorized, map[string]any{
			"code":    "UNAUTHORIZED",
			"message": "User context is missing",
			"details": nil,
		})
	}

	var req schemareq.CreateUserRequest
	if err := c.Bind(&req); err != nil {
		return echo.NewHTTPError(http.StatusBadRequest, map[string]any{
			"code":    "BAD_REQUEST",
			"message": "Invalid request body",
			"details": err.Error(),
		})
	}
	if req.DisplayName == "" {
		return echo.NewHTTPError(http.StatusBadRequest, map[string]any{
			"code":    "BAD_REQUEST",
			"message": "display_name is required",
			"details": nil,
		})
	}

	birthdate, err := parseBirthdate(req.Birthdate)
	if err != nil {
		return echo.NewHTTPError(http.StatusBadRequest, map[string]any{
			"code":    "BAD_REQUEST",
			"message": "birthdate must be YYYY-MM-DD",
			"details": nil,
		})
	}

	ageVisibility := "hidden"
	if req.AgeVisibility != nil && *req.AgeVisibility != "" {
		ageVisibility = *req.AgeVisibility
	}
	sex := "no-answer"
	if req.Sex != nil && *req.Sex != "" {
		sex = *req.Sex
	}

	created, err := h.userUsecase.CreateUser(c.Request().Context(), uid, usecasedto.CreateUserInput{
		DisplayName:   req.DisplayName,
		Bio:           req.Bio,
		Birthdate:     birthdate,
		AgeVisibility: ageVisibility,
		PrefectureID:  req.PrefectureID,
		Sex:           sex,
		AvatarURL:     req.AvatarURL,
	})
	if err != nil {
		return err
	}

	return c.JSON(http.StatusCreated, schemares.UserResponse{User: userDTOToResponse(created)})
}

func (h *userHandler) getMe(c echo.Context) error {
	uid, ok := userIDFromAuthContext(c)
	if !ok {
		return echo.NewHTTPError(http.StatusUnauthorized, map[string]any{
			"code":    "UNAUTHORIZED",
			"message": "User context is missing",
			"details": nil,
		})
	}

	user, err := h.userUsecase.GetMe(c.Request().Context(), uid)
	if err != nil {
		return err
	}
	return c.JSON(http.StatusOK, schemares.UserResponse{User: userDTOToResponse(user)})
}

func (h *userHandler) getUserByID(c echo.Context) error {
	requesterUID, ok := userIDFromAuthContext(c)
	if !ok {
		return echo.NewHTTPError(http.StatusUnauthorized, map[string]any{
			"code":    "UNAUTHORIZED",
			"message": "User context is missing",
			"details": nil,
		})
	}

	targetUserID := c.Param("id")
	if targetUserID == "" {
		return echo.NewHTTPError(http.StatusBadRequest, map[string]any{
			"code":    "BAD_REQUEST",
			"message": "id path param is required",
			"details": nil,
		})
	}

	user, err := h.userUsecase.GetUserByID(c.Request().Context(), requesterUID, targetUserID)
	if err != nil {
		return err
	}

	return c.JSON(http.StatusOK, schemares.PublicUserResponse{User: publicUserDTOToResponse(user)})
}

func (h *userHandler) patchMe(c echo.Context) error {
	uid, ok := userIDFromAuthContext(c)
	if !ok {
		return echo.NewHTTPError(http.StatusUnauthorized, map[string]any{
			"code":    "UNAUTHORIZED",
			"message": "User context is missing",
			"details": nil,
		})
	}

	var req schemareq.UpdateUserRequest
	if err := c.Bind(&req); err != nil {
		return echo.NewHTTPError(http.StatusBadRequest, map[string]any{
			"code":    "BAD_REQUEST",
			"message": "Invalid request body",
			"details": err.Error(),
		})
	}

	if req.DisplayName != nil && *req.DisplayName == "" {
		return echo.NewHTTPError(http.StatusBadRequest, map[string]any{
			"code":    "BAD_REQUEST",
			"message": "display_name must not be empty",
			"details": nil,
		})
	}

	var birthdate *time.Time
	birthdateSet := false
	if req.Birthdate != nil {
		parsed, err := parseBirthdate(req.Birthdate)
		if err != nil {
			return echo.NewHTTPError(http.StatusBadRequest, map[string]any{
				"code":    "BAD_REQUEST",
				"message": "birthdate must be YYYY-MM-DD",
				"details": nil,
			})
		}
		birthdate = parsed
		birthdateSet = true
	}

	var ageVisibility *string
	if req.AgeVisibility != nil && *req.AgeVisibility != "" {
		ageVisibility = req.AgeVisibility
	}
	var sex *string
	if req.Sex != nil && *req.Sex != "" {
		sex = req.Sex
	}

	avatarURLSet := false
	var avatarURL *string
	if req.AvatarURL != nil {
		avatarURLSet = true
		if *req.AvatarURL != "" {
			avatarURL = req.AvatarURL
		}
	}

	updated, err := h.userUsecase.PatchMe(c.Request().Context(), uid, usecasedto.UpdateUserInput{
		DisplayName:   req.DisplayName,
		Bio:           req.Bio,
		BirthdateSet:  birthdateSet,
		Birthdate:     birthdate,
		AgeVisibility: ageVisibility,
		PrefectureID:  req.PrefectureID,
		Sex:           sex,
		AvatarURLSet:  avatarURLSet,
		AvatarURL:     avatarURL,
	})
	if err != nil {
		return err
	}

	return c.JSON(http.StatusOK, schemares.UserResponse{User: userDTOToResponse(updated)})
}

func (h *userHandler) deleteMe(c echo.Context) error {
	uid, ok := userIDFromAuthContext(c)
	if !ok {
		return echo.NewHTTPError(http.StatusUnauthorized, map[string]any{
			"code":    "UNAUTHORIZED",
			"message": "User context is missing",
			"details": nil,
		})
	}

	if err := h.userUsecase.DeleteMe(c.Request().Context(), uid); err != nil {
		return err
	}

	if h.authUserManager != nil {
		if err := h.authUserManager.DeleteUser(c.Request().Context(), uid); err != nil && !firebaseauth.IsUserNotFound(err) {
			return err
		}
	}

	return c.NoContent(http.StatusNoContent)
}

func userIDFromAuthContext(c echo.Context) (string, bool) {
	value := c.Get("user_id")
	userID, ok := value.(string)
	if !ok || userID == "" {
		return "", false
	}
	return userID, true
}

func parseBirthdate(raw *string) (*time.Time, error) {
	if raw == nil || *raw == "" {
		return nil, nil
	}
	parsed, err := time.Parse("2006-01-02", *raw)
	if err != nil {
		return nil, err
	}
	dateOnly := parsed.UTC()
	return &dateOnly, nil
}
