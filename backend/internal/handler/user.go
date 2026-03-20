package handler

import (
	"io"
	"net/http"
	"time"

	firebaseauth "firebase.google.com/go/v4/auth"
	"github.com/labstack/echo/v4"
	"go.uber.org/zap"

	"hackathon/internal/handler/middleware"
	schemareq "hackathon/internal/handler/schema/request"
	schemares "hackathon/internal/handler/schema/response"
	"hackathon/internal/usecase"
	usecasedto "hackathon/internal/usecase/dto"
)

type userHandler struct {
	log             *zap.Logger
	authUserManager FirebaseUserManager
	userUsecase     usecase.UserUsecase
	avatarUploader  AvatarUploader // nil の場合はアバターアップロード機能が無効
}

func newUserHandler(log *zap.Logger, authUserManager FirebaseUserManager, userUsecase usecase.UserUsecase, avatarUploader AvatarUploader) *userHandler {
	return &userHandler{
		log:             log,
		authUserManager: authUserManager,
		userUsecase:     userUsecase,
		avatarUploader:  avatarUploader,
	}
}

// createUser godoc
// @ID           createUser
// @Summary      ユーザー作成
// @Description  Firebase 認証済みの新規ユーザーを登録する（初回ログイン時に一度だけ呼ぶ）
// @Tags         users
// @Accept       json
// @Produce      json
// @Security     BearerAuth
// @Param        body  body      schemareq.CreateUserRequest  true  "ユーザー作成リクエスト"
// @Success      201   {object}  schemares.UserResponse
// @Failure      400   {object}  errorResponse
// @Failure      401   {object}  errorResponse
// @Failure      409   {object}  errorResponse
// @Failure      500   {object}  errorResponse
// @Router       /api/v1/users [post]
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

// getMe godoc
// @ID           getMe
// @Summary      自分のユーザー情報取得
// @Description  認証中のユーザー自身のプロフィールを返す
// @Tags         users
// @Produce      json
// @Security     BearerAuth
// @Success      200  {object}  schemares.UserResponse
// @Failure      401  {object}  errorResponse
// @Failure      404  {object}  errorResponse
// @Failure      500  {object}  errorResponse
// @Router       /api/v1/users/me [get]
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

// getUserByID godoc
// @ID           getUserByID
// @Summary      他ユーザーのプロフィール取得
// @Description  指定した ID の公開プロフィールを返す
// @Tags         users
// @Produce      json
// @Security     BearerAuth
// @Param        id   path      string  true  "対象ユーザー ID"
// @Success      200  {object}  schemares.PublicUserResponse
// @Failure      400  {object}  errorResponse
// @Failure      401  {object}  errorResponse
// @Failure      403  {object}  errorResponse
// @Failure      404  {object}  errorResponse
// @Failure      500  {object}  errorResponse
// @Router       /api/v1/users/{id} [get]
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

// patchMe godoc
// @ID           patchMe
// @Summary      自分のプロフィール更新
// @Description  指定したフィールドだけを部分更新する（null フィールドは変更しない）
// @Tags         users
// @Accept       json
// @Produce      json
// @Security     BearerAuth
// @Param        body  body      schemareq.UpdateUserRequest  true  "プロフィール更新リクエスト"
// @Success      200   {object}  schemares.UserResponse
// @Failure      400   {object}  errorResponse
// @Failure      401   {object}  errorResponse
// @Failure      404   {object}  errorResponse
// @Failure      500   {object}  errorResponse
// @Router       /api/v1/users/me [patch]
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

// uploadAvatar godoc
// @ID           uploadAvatar
// @Summary      アバター画像アップロード
// @Description  multipart/form-data でアバター画像を受け取り GCS にアップロードして公開 URL を返す。DB 更新は行わないため、呼び出し後に PATCH /users/me で avatar_url を保存すること。
// @Tags         users
// @Accept       multipart/form-data
// @Produce      json
// @Security     BearerAuth
// @Param        file formData file true "アバター画像（JPEG または PNG、最大 5MB）"
// @Success      200  {object}  map[string]string
// @Failure      400  {object}  errorResponse
// @Failure      401  {object}  errorResponse
// @Failure      500  {object}  errorResponse
// @Failure      503  {object}  errorResponse
// @Router       /api/v1/users/me/avatar [post]
func (h *userHandler) uploadAvatar(c echo.Context) error {
	uid, ok := middleware.UserIDFromContext(c)
	if !ok {
		return errUnauthorized()
	}

	if h.avatarUploader == nil {
		return echo.NewHTTPError(http.StatusServiceUnavailable, map[string]any{
			"code":    "SERVICE_UNAVAILABLE",
			"message": "Avatar upload is not configured",
			"details": nil,
		})
	}

	const maxSize = 5 << 20 // 5MB
	file, header, err := c.Request().FormFile("file")
	if err != nil {
		return errBadRequest("file is required")
	}
	defer file.Close()

	mimeType := header.Header.Get("Content-Type")
	if mimeType != "image/jpeg" && mimeType != "image/png" {
		return errBadRequest("file Content-Type must be image/jpeg or image/png")
	}

	data, err := io.ReadAll(io.LimitReader(file, maxSize+1))
	if err != nil {
		return errBadRequest("failed to read file")
	}
	if len(data) == 0 {
		return errBadRequest("file is empty")
	}
	if int64(len(data)) > maxSize {
		return errBadRequest("file size must not exceed 5MB")
	}

	avatarURL, err := h.avatarUploader.UploadAvatar(c.Request().Context(), uid, data, mimeType)
	if err != nil {
		h.log.Error("uploadAvatar: storage upload failed", zap.String("uid", uid), zap.Error(err))
		return echo.NewHTTPError(http.StatusInternalServerError, map[string]any{
			"code":    "INTERNAL_SERVER_ERROR",
			"message": "Failed to upload avatar",
			"details": nil,
		})
	}

	return c.JSON(http.StatusOK, map[string]string{"avatar_url": avatarURL})
}

// deleteMe godoc
// @ID           deleteMe
// @Summary      自分のアカウント削除
// @Description  DB レコードと Firebase アカウントを削除する（Firebase 削除はベストエフォート）
// @Tags         users
// @Security     BearerAuth
// @Success      204
// @Failure      401  {object}  errorResponse
// @Failure      404  {object}  errorResponse
// @Failure      500  {object}  errorResponse
// @Router       /api/v1/users/me [delete]
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
		h.log.Error("deleteMe: firebase user deletion failed",
			zap.String("uid", uid),
			zap.Error(err),
		)
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
