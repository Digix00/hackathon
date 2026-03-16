package handler

import (
	"context"
	"errors"
	"net/http"
	"strconv"
	"time"

	firebaseauth "firebase.google.com/go/v4/auth"
	"github.com/google/uuid"
	"github.com/labstack/echo/v4"
	"gorm.io/gorm"
	"gorm.io/gorm/clause"

	schemareq "hackathon/internal/handler/schema/request"
	schemares "hackathon/internal/handler/schema/response"
	"hackathon/internal/infra/rdb/model"
)

const (
	firebaseProvider          = "firebase"
	deletedUserAuthProvider   = "system"
	deletedUserProviderUserID = "deleted-user"
	deletedUserDisplayName    = "削除済みユーザー"
)

type userHandler struct {
	db              *gorm.DB
	authUserManager FirebaseUserManager
}

type FirebaseUserManager interface {
	DeleteUser(ctx context.Context, uid string) error
}

func newUserHandler(db *gorm.DB, authUserManager FirebaseUserManager) *userHandler {
	return &userHandler{db: db, authUserManager: authUserManager}
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

	var created model.User
	err = h.db.WithContext(c.Request().Context()).Transaction(func(tx *gorm.DB) error {
		var existing model.User
		findErr := tx.Where("auth_provider = ? AND provider_user_id = ?", firebaseProvider, uid).First(&existing).Error
		if findErr == nil {
			return echo.NewHTTPError(http.StatusConflict, map[string]any{
				"code":    "CONFLICT",
				"message": "User already exists",
				"details": nil,
			})
		}
		if !errors.Is(findErr, gorm.ErrRecordNotFound) {
			return findErr
		}

		ageVisibility := "hidden"
		if req.AgeVisibility != nil && *req.AgeVisibility != "" {
			ageVisibility = *req.AgeVisibility
		}

		sex := "no-answer"
		if req.Sex != nil && *req.Sex != "" {
			sex = *req.Sex
		}

		created = model.User{
			ID:             uuid.NewString(),
			AuthProvider:   firebaseProvider,
			ProviderUserID: uid,
			Name:           &req.DisplayName,
			Bio:            req.Bio,
			Birthdate:      birthdate,
			AgeVisibility:  ageVisibility,
			PrefectureID:   req.PrefectureID,
			Sex:            sex,
			AvatarFileID:   nil,
		}
		if createErr := tx.Create(&created).Error; createErr != nil {
			return createErr
		}

		if req.AvatarURL != nil && *req.AvatarURL != "" {
			file := model.File{
				ID:               uuid.NewString(),
				FilePath:         *req.AvatarURL,
				FileType:         "avatar",
				MimeType:         "application/octet-stream",
				FileSize:         0,
				UploadedByUserID: created.ID,
			}
			if createErr := tx.Create(&file).Error; createErr != nil {
				return createErr
			}
			created.AvatarFileID = &file.ID
			if updateErr := tx.Model(&model.User{}).
				Where("id = ?", created.ID).
				Update("avatar_file_id", file.ID).Error; updateErr != nil {
				return updateErr
			}
		}

		settings := model.UserSettings{
			ID:     uuid.NewString(),
			UserID: created.ID,
		}
		if createErr := tx.Create(&settings).Error; createErr != nil {
			return createErr
		}

		if loadErr := tx.Preload("AvatarFile").First(&created, "id = ?", created.ID).Error; loadErr != nil {
			return loadErr
		}

		return nil
	})
	if err != nil {
		return err
	}

	return c.JSON(http.StatusCreated, schemares.UserResponse{User: toUserResponse(created)})
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

	var user model.User
	err := h.db.WithContext(c.Request().Context()).Preload("AvatarFile").
		Where("auth_provider = ? AND provider_user_id = ?", firebaseProvider, uid).
		First(&user).Error
	if errors.Is(err, gorm.ErrRecordNotFound) {
		return echo.NewHTTPError(http.StatusNotFound, map[string]any{
			"code":    "NOT_FOUND",
			"message": "User was not found",
			"details": nil,
		})
	}
	if err != nil {
		return err
	}

	return c.JSON(http.StatusOK, schemares.UserResponse{User: toUserResponse(user)})
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

	var requester model.User
	if err := h.db.WithContext(c.Request().Context()).
		Where("auth_provider = ? AND provider_user_id = ?", firebaseProvider, requesterUID).
		First(&requester).Error; err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			return echo.NewHTTPError(http.StatusNotFound, map[string]any{
				"code":    "NOT_FOUND",
				"message": "User was not found",
				"details": nil,
			})
		}
		return err
	}

	blocked, err := h.isBlocked(c.Request().Context(), requester.ID, targetUserID)
	if err != nil {
		return err
	}
	if blocked {
		return echo.NewHTTPError(http.StatusNotFound, map[string]any{
			"code":    "NOT_FOUND",
			"message": "User was not found",
			"details": nil,
		})
	}

	var target model.User
	err = h.db.WithContext(c.Request().Context()).
		Preload("AvatarFile").
		Preload("Prefecture").
		First(&target, "id = ?", targetUserID).Error
	if errors.Is(err, gorm.ErrRecordNotFound) {
		return echo.NewHTTPError(http.StatusNotFound, map[string]any{
			"code":    "NOT_FOUND",
			"message": "User was not found",
			"details": nil,
		})
	}
	if err != nil {
		return err
	}

	profileVisible := true
	trackVisible := true
	var settings model.UserSettings
	if err := h.db.WithContext(c.Request().Context()).Where("user_id = ?", target.ID).First(&settings).Error; err == nil {
		profileVisible = settings.ProfileVisible
		trackVisible = settings.TrackVisible
	} else if !errors.Is(err, gorm.ErrRecordNotFound) {
		return err
	}

	encounterCount, err := h.countEncounters(c.Request().Context(), target.ID)
	if err != nil {
		return err
	}

	publicUser := toPublicUserResponse(target, encounterCount)
	if !profileVisible {
		publicUser.Bio = nil
		publicUser.Birthplace = nil
		publicUser.AgeRange = nil
	}

	if trackVisible {
		sharedTrack, trackErr := h.loadSharedTrack(c.Request().Context(), target.ID)
		if trackErr != nil {
			return trackErr
		}
		publicUser.SharedTrack = sharedTrack
	}

	return c.JSON(http.StatusOK, schemares.PublicUserResponse{User: publicUser})
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

	var updated model.User
	err := h.db.WithContext(c.Request().Context()).Transaction(func(tx *gorm.DB) error {
		if err := tx.Preload("AvatarFile").
			Where("auth_provider = ? AND provider_user_id = ?", firebaseProvider, uid).
			First(&updated).Error; err != nil {
			if errors.Is(err, gorm.ErrRecordNotFound) {
				return echo.NewHTTPError(http.StatusNotFound, map[string]any{
					"code":    "NOT_FOUND",
					"message": "User was not found",
					"details": nil,
				})
			}
			return err
		}

		if req.DisplayName != nil {
			if *req.DisplayName == "" {
				return echo.NewHTTPError(http.StatusBadRequest, map[string]any{
					"code":    "BAD_REQUEST",
					"message": "display_name must not be empty",
					"details": nil,
				})
			}
			updated.Name = req.DisplayName
		}

		if req.Bio != nil {
			updated.Bio = req.Bio
		}

		if req.Birthdate != nil {
			birthdate, parseErr := parseBirthdate(req.Birthdate)
			if parseErr != nil {
				return echo.NewHTTPError(http.StatusBadRequest, map[string]any{
					"code":    "BAD_REQUEST",
					"message": "birthdate must be YYYY-MM-DD",
					"details": nil,
				})
			}
			updated.Birthdate = birthdate
		}

		if req.AgeVisibility != nil {
			if *req.AgeVisibility != "" {
				updated.AgeVisibility = *req.AgeVisibility
			}
		}

		if req.PrefectureID != nil {
			updated.PrefectureID = req.PrefectureID
		}

		if req.Sex != nil {
			if *req.Sex != "" {
				updated.Sex = *req.Sex
			}
		}

		if req.AvatarURL != nil {
			if *req.AvatarURL == "" {
				updated.AvatarFileID = nil
				updated.AvatarFile = nil
			} else {
				file := model.File{
					ID:               uuid.NewString(),
					FilePath:         *req.AvatarURL,
					FileType:         "avatar",
					MimeType:         "application/octet-stream",
					FileSize:         0,
					UploadedByUserID: updated.ID,
				}
				if createErr := tx.Create(&file).Error; createErr != nil {
					return createErr
				}
				updated.AvatarFileID = &file.ID
			}
		}

		if err := tx.Save(&updated).Error; err != nil {
			return err
		}

		if err := tx.Preload("AvatarFile").First(&updated, "id = ?", updated.ID).Error; err != nil {
			return err
		}

		return nil
	})
	if err != nil {
		return err
	}

	return c.JSON(http.StatusOK, schemares.UserResponse{User: toUserResponse(updated)})
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

	err := h.db.WithContext(c.Request().Context()).Transaction(func(tx *gorm.DB) error {
		var user model.User
		if err := tx.Where("auth_provider = ? AND provider_user_id = ?", firebaseProvider, uid).First(&user).Error; err != nil {
			if errors.Is(err, gorm.ErrRecordNotFound) {
				return echo.NewHTTPError(http.StatusNotFound, map[string]any{
					"code":    "NOT_FOUND",
					"message": "User was not found",
					"details": nil,
				})
			}
			return err
		}

		if err := cleanupUserRelatedData(tx, user.ID); err != nil {
			return err
		}

		if err := tx.Where("user_id = ?", user.ID).Delete(&model.UserSettings{}).Error; err != nil {
			return err
		}

		if err := tx.Where("user_id = ?", user.ID).Delete(&model.UserDevice{}).Error; err != nil {
			return err
		}

		if err := deleteIfTableExists(tx, &model.MusicConnection{}, "user_id = ?", user.ID); err != nil {
			return err
		}

		if err := deleteIfTableExists(tx, &model.BleToken{}, "user_id = ?", user.ID); err != nil {
			return err
		}

		if err := deleteIfTableExists(tx, &model.File{}, "uploaded_by_user_id = ?", user.ID); err != nil {
			return err
		}

		if err := tx.Delete(&user).Error; err != nil {
			return err
		}

		return nil
	})
	if err != nil {
		return err
	}

	if h.authUserManager != nil {
		if err := h.authUserManager.DeleteUser(c.Request().Context(), uid); err != nil && !firebaseauth.IsUserNotFound(err) {
			return err
		}
	}

	return c.NoContent(http.StatusNoContent)
}

func cleanupUserRelatedData(tx *gorm.DB, userID string) error {
	encounterIDs := make([]string, 0)
	if hasTable(tx, &model.Encounter{}) {
		if err := tx.Model(&model.Encounter{}).
			Where("user_id1 = ? OR user_id2 = ?", userID, userID).
			Pluck("id", &encounterIDs).Error; err != nil {
			return err
		}
	}

	if len(encounterIDs) > 0 {
		if err := deleteIfTableExists(tx, &model.EncounterRead{}, "encounter_id IN ?", encounterIDs); err != nil {
			return err
		}
		if err := deleteIfTableExists(tx, &model.Comment{}, "encounter_id IN ?", encounterIDs); err != nil {
			return err
		}
		if err := deleteIfTableExists(tx, &model.OutboxNotification{}, "encounter_id IN ?", encounterIDs); err != nil {
			return err
		}
	}

	if err := deleteIfTableExists(tx, &model.EncounterRead{}, "user_id = ?", userID); err != nil {
		return err
	}
	if err := deleteIfTableExists(tx, &model.Comment{}, "commenter_user_id = ?", userID); err != nil {
		return err
	}
	if err := deleteIfTableExists(tx, &model.DailyEncounterCount{}, "user_id = ?", userID); err != nil {
		return err
	}
	if err := deleteIfTableExists(tx, &model.OutboxNotification{}, "user_id = ?", userID); err != nil {
		return err
	}
	if err := deleteIfTableExists(tx, &model.Encounter{}, "user_id1 = ? OR user_id2 = ?", userID, userID); err != nil {
		return err
	}

	if err := deleteIfTableExists(tx, &model.Report{}, "reporter_user_id = ? OR reported_user_id = ?", userID, userID); err != nil {
		return err
	}

	if err := deleteIfTableExists(tx, &model.Block{}, "blocker_user_id = ? OR blocked_user_id = ?", userID, userID); err != nil {
		return err
	}
	if err := deleteIfTableExists(tx, &model.Mute{}, "user_id = ? OR target_user_id = ?", userID, userID); err != nil {
		return err
	}

	if err := deleteIfTableExists(tx, &model.UserTrack{}, "user_id = ?", userID); err != nil {
		return err
	}
	if err := deleteIfTableExists(tx, &model.UserCurrentTrack{}, "user_id = ?", userID); err != nil {
		return err
	}
	if err := deleteIfTableExists(tx, &model.TrackFavorite{}, "user_id = ?", userID); err != nil {
		return err
	}

	playlistIDs := make([]string, 0)
	if hasTable(tx, &model.Playlist{}) {
		if err := tx.Model(&model.Playlist{}).Where("user_id = ?", userID).Pluck("id", &playlistIDs).Error; err != nil {
			return err
		}
	}
	if len(playlistIDs) > 0 {
		if err := deleteIfTableExists(tx, &model.PlaylistTrack{}, "playlist_id IN ?", playlistIDs); err != nil {
			return err
		}
		if err := deleteIfTableExists(tx, &model.PlaylistFavorite{}, "playlist_id IN ?", playlistIDs); err != nil {
			return err
		}
	}
	if err := deleteIfTableExists(tx, &model.PlaylistFavorite{}, "user_id = ?", userID); err != nil {
		return err
	}
	if err := deleteIfTableExists(tx, &model.Playlist{}, "user_id = ?", userID); err != nil {
		return err
	}

	if err := deleteIfTableExists(tx, &model.SongLike{}, "user_id = ?", userID); err != nil {
		return err
	}

	chainIDs := make([]string, 0)
	if hasTable(tx, &model.LyricEntry{}) {
		if err := tx.Model(&model.LyricEntry{}).Where("user_id = ?", userID).Distinct().Pluck("chain_id", &chainIDs).Error; err != nil {
			return err
		}
	}
	for _, chainID := range chainIDs {
		var otherEntryCount int64
		if err := tx.Model(&model.LyricEntry{}).
			Where("chain_id = ? AND user_id <> ?", chainID, userID).
			Count(&otherEntryCount).Error; err != nil {
			return err
		}

		if otherEntryCount == 0 {
			if err := deleteIfTableExists(tx, &model.GeneratedSong{}, "chain_id = ?", chainID); err != nil {
				return err
			}
			if err := deleteIfTableExists(tx, &model.OutboxLyriaJob{}, "chain_id = ?", chainID); err != nil {
				return err
			}
			if err := deleteIfTableExists(tx, &model.LyricEntry{}, "chain_id = ?", chainID); err != nil {
				return err
			}
			if err := deleteIfTableExists(tx, &model.LyricChain{}, "id = ?", chainID); err != nil {
				return err
			}
			continue
		}

		deletedUserID, err := getOrCreateDeletedUserID(tx)
		if err != nil {
			return err
		}

		if err := tx.Model(&model.LyricEntry{}).
			Where("chain_id = ? AND user_id = ?", chainID, userID).
			Update("user_id", deletedUserID).Error; err != nil {
			return err
		}
	}

	return nil
}

func hasTable(tx *gorm.DB, tableModel any) bool {
	return tx.Migrator().HasTable(tableModel)
}

func deleteIfTableExists(tx *gorm.DB, tableModel any, query any, args ...any) error {
	if !hasTable(tx, tableModel) {
		return nil
	}
	return tx.Where(query, args...).Delete(tableModel).Error
}

func getOrCreateDeletedUserID(tx *gorm.DB) (string, error) {
	var deletedUser model.User
	err := tx.Where("auth_provider = ? AND provider_user_id = ?", deletedUserAuthProvider, deletedUserProviderUserID).First(&deletedUser).Error
	if err == nil {
		if deletedUser.Name == nil || *deletedUser.Name != deletedUserDisplayName {
			name := deletedUserDisplayName
			if updateErr := tx.Model(&model.User{}).Where("id = ?", deletedUser.ID).Update("name", name).Error; updateErr != nil {
				return "", updateErr
			}
		}
		return deletedUser.ID, nil
	}
	if !errors.Is(err, gorm.ErrRecordNotFound) {
		return "", err
	}

	name := deletedUserDisplayName
	candidate := model.User{
		ID:             uuid.NewString(),
		AuthProvider:   deletedUserAuthProvider,
		ProviderUserID: deletedUserProviderUserID,
		Name:           &name,
		AgeVisibility:  "hidden",
		Sex:            "no-answer",
	}
	if err := tx.Clauses(clause.OnConflict{DoNothing: true}).Create(&candidate).Error; err != nil {
		return "", err
	}

	if err := tx.Where("auth_provider = ? AND provider_user_id = ?", deletedUserAuthProvider, deletedUserProviderUserID).First(&deletedUser).Error; err != nil {
		return "", err
	}
	return deletedUser.ID, nil
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

func (h *userHandler) isBlocked(ctx context.Context, requesterUserID string, targetUserID string) (bool, error) {
	var count int64
	err := h.db.WithContext(ctx).
		Model(&model.Block{}).
		Where("(blocker_user_id = ? AND blocked_user_id = ?) OR (blocker_user_id = ? AND blocked_user_id = ?)", requesterUserID, targetUserID, targetUserID, requesterUserID).
		Count(&count).Error
	if err != nil {
		return false, err
	}
	return count > 0, nil
}

func (h *userHandler) countEncounters(ctx context.Context, targetUserID string) (int64, error) {
	var count int64
	err := h.db.WithContext(ctx).
		Model(&model.Encounter{}).
		Where("user_id1 = ? OR user_id2 = ?", targetUserID, targetUserID).
		Count(&count).Error
	if err != nil {
		return 0, err
	}
	return count, nil
}

func (h *userHandler) loadSharedTrack(ctx context.Context, targetUserID string) (*schemares.PublicTrack, error) {
	var userCurrent model.UserCurrentTrack
	err := h.db.WithContext(ctx).
		Preload("Track").
		Where("user_id = ?", targetUserID).
		First(&userCurrent).Error
	if errors.Is(err, gorm.ErrRecordNotFound) {
		return nil, nil
	}
	if err != nil {
		return nil, err
	}
	if userCurrent.Track == nil {
		return nil, nil
	}

	trackID := userCurrent.Track.ID
	if userCurrent.Track.Provider != "" && userCurrent.Track.ExternalID != "" {
		trackID = userCurrent.Track.Provider + ":track:" + userCurrent.Track.ExternalID
	}

	return &schemares.PublicTrack{
		ID:         trackID,
		Title:      userCurrent.Track.Title,
		ArtistName: userCurrent.Track.ArtistName,
		ArtworkURL: userCurrent.Track.AlbumArtURL,
		PreviewURL: nil,
	}, nil
}

func toUserResponse(user model.User) schemares.User {
	var avatarURL *string
	if user.AvatarFile != nil {
		avatar := user.AvatarFile.FilePath
		avatarURL = &avatar
	}

	var birthdate *string
	if user.Birthdate != nil {
		formatted := user.Birthdate.UTC().Format("2006-01-02")
		birthdate = &formatted
	}

	displayName := ""
	if user.Name != nil {
		displayName = *user.Name
	}

	return schemares.User{
		ID:            user.ID,
		DisplayName:   displayName,
		AvatarURL:     avatarURL,
		Bio:           user.Bio,
		Birthdate:     birthdate,
		AgeVisibility: user.AgeVisibility,
		PrefectureID:  user.PrefectureID,
		Sex:           user.Sex,
		CreatedAt:     user.CreatedAt.UTC().Format(time.RFC3339),
		UpdatedAt:     user.UpdatedAt.UTC().Format(time.RFC3339),
	}
}

func toPublicUserResponse(user model.User, encounterCount int64) schemares.PublicUser {
	var avatarURL *string
	if user.AvatarFile != nil {
		avatar := user.AvatarFile.FilePath
		avatarURL = &avatar
	}

	displayName := ""
	if user.Name != nil {
		displayName = *user.Name
	}

	var birthplace *string
	if user.Prefecture != nil {
		prefName := user.Prefecture.Name
		birthplace = &prefName
	}

	ageRange := calculateAgeRange(user.Birthdate, user.AgeVisibility)

	return schemares.PublicUser{
		ID:             user.ID,
		DisplayName:    displayName,
		AvatarURL:      avatarURL,
		Bio:            user.Bio,
		Birthplace:     birthplace,
		AgeRange:       ageRange,
		EncounterCount: encounterCount,
		SharedTrack:    nil,
		UpdatedAt:      user.UpdatedAt.UTC().Format(time.RFC3339),
	}
}

func calculateAgeRange(birthdate *time.Time, visibility string) *string {
	if birthdate == nil || visibility == "hidden" {
		return nil
	}

	now := time.Now().UTC()
	age := now.Year() - birthdate.Year()
	if now.Month() < birthdate.Month() || (now.Month() == birthdate.Month() && now.Day() < birthdate.Day()) {
		age--
	}

	if age < 0 {
		return nil
	}

	switch visibility {
	case "exact":
		value := strconv.Itoa(age)
		return &value
	case "by-10":
		decade := (age / 10) * 10
		value := strconv.Itoa(decade) + "s"
		return &value
	default:
		decade := (age / 10) * 10
		value := strconv.Itoa(decade) + "s"
		return &value
	}
}
