package handler

import (
	"net/http"
	"time"

	firebaseauth "firebase.google.com/go/v4/auth"
	"github.com/labstack/echo/v4"

	"hackathon/internal/handler/middleware"
	schemareq "hackathon/internal/handler/schema/request"
	schemares "hackathon/internal/handler/schema/response"
	"hackathon/internal/usecase"
	usecasedto "hackathon/internal/usecase/dto"
)

type userHandler struct {
	authUserManager FirebaseUserManager
	userUsecase     usecase.UserUsecase
}

func newUserHandler(authUserManager FirebaseUserManager, userUsecase usecase.UserUsecase) *userHandler {
	return &userHandler{
		authUserManager: authUserManager,
		userUsecase:     userUsecase,
	}
}

func (h *userHandler) createUser(c echo.Context) error {
	uid, ok := middleware.UserIDFromContext(c)
	if !ok {
		return errUnauthorized()
	}

	var req schemareq.CreateUserRequest
	if err := c.Bind(&req); err != nil {
		return errBadRequest("Invalid request body")
	}
	if req.DisplayName == "" {
		return errBadRequest("display_name is required")
	}

	birthdate, err := parseBirthdate(req.Birthdate)
	if err != nil {
		return errBadRequest("birthdate must be YYYY-MM-DD")
	}

	created, err := h.userUsecase.CreateUser(c.Request().Context(), uid, usecasedto.CreateUserInput{
		DisplayName:   req.DisplayName,
		Bio:           req.Bio,
		Birthdate:     birthdate,
		AgeVisibility: req.AgeVisibility,
		PrefectureID:  req.PrefectureID,
		Sex:           req.Sex,
		AvatarURL:     req.AvatarURL,
	})
	if err != nil {
		return err
	}

	return c.JSON(http.StatusCreated, schemares.UserResponse{User: userDTOToResponse(created)})
}

func (h *userHandler) getMe(c echo.Context) error {
	uid, ok := middleware.UserIDFromContext(c)
	if !ok {
		return errUnauthorized()
	}

	user, err := h.userUsecase.GetMe(c.Request().Context(), uid)
	if err != nil {
		return err
	}
	return c.JSON(http.StatusOK, schemares.UserResponse{User: userDTOToResponse(user)})
}

func (h *userHandler) getUserByID(c echo.Context) error {
	requesterUID, ok := middleware.UserIDFromContext(c)
	if !ok {
		return errUnauthorized()
	}

	targetUserID := c.Param("id")
	if targetUserID == "" {
		return errBadRequest("id path param is required")
	}

	user, err := h.userUsecase.GetUserByID(c.Request().Context(), requesterUID, targetUserID)
	if err != nil {
		return err
	}

	return c.JSON(http.StatusOK, schemares.PublicUserResponse{User: publicUserDTOToResponse(user)})
}

func (h *userHandler) patchMe(c echo.Context) error {
	uid, ok := middleware.UserIDFromContext(c)
	if !ok {
		return errUnauthorized()
	}

	var req schemareq.UpdateUserRequest
	if err := c.Bind(&req); err != nil {
		return errBadRequest("Invalid request body")
	}

	if req.DisplayName != nil && *req.DisplayName == "" {
		return errBadRequest("display_name must not be empty")
	}

	var birthdate *time.Time
	birthdateSet := false
	if req.Birthdate != nil {
		parsed, err := parseBirthdate(req.Birthdate)
		if err != nil {
			return errBadRequest("birthdate must be YYYY-MM-DD")
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
	uid, ok := middleware.UserIDFromContext(c)
	if !ok {
		return errUnauthorized()
	}

	if err := h.userUsecase.DeleteMe(c.Request().Context(), uid); err != nil {
		return err
	}

	// Firebase 削除はベストエフォートで実行する。
	// DB 削除が完了した時点でユーザーは API 上で無効化されているため、
	// Firebase 削除に失敗してもクライアントには成功を返しエラーをログに残す。
	// 孤立した Firebase アカウントは DB レコードを持たないため再ログインしても即 404 になる。
	if err := h.authUserManager.DeleteUser(c.Request().Context(), uid); err != nil && !firebaseauth.IsUserNotFound(err) {
		c.Logger().Errorf("deleteMe: firebase user deletion failed (uid=%s): %v", uid, err)
	}

	return c.NoContent(http.StatusNoContent)
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

// errUnauthorized はUser contextが取得できない場合のHTTPエラーを返す。
// ミドルウェアで認証済みのため通常は発生しないが、コンテキスト設定ミスに対する防御。
func errUnauthorized() error {
	return echo.NewHTTPError(http.StatusUnauthorized, map[string]any{
		"code":    "UNAUTHORIZED",
		"message": "User context is missing",
		"details": nil,
	})
}

func errBadRequest(msg string) error {
	return echo.NewHTTPError(http.StatusBadRequest, map[string]any{
		"code":    "BAD_REQUEST",
		"message": msg,
		"details": nil,
	})
}
