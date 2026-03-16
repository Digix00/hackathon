package rdb

import (
	"context"
	"errors"

	"github.com/google/uuid"
	"gorm.io/gorm"
	"gorm.io/gorm/clause"

	"hackathon/internal/domain/entity"
	domainerrs "hackathon/internal/domain/errs"
	"hackathon/internal/domain/repository"
	"hackathon/internal/infra/rdb/model"
)

type userRepository struct {
	db *gorm.DB
}

func NewUserRepository(db *gorm.DB) repository.UserRepository {
	return &userRepository{db: db}
}

func (r *userRepository) FindByAuthProviderAndProviderUserID(ctx context.Context, authProvider, providerUserID string) (entity.User, error) {
	var user model.User
	err := r.db.WithContext(ctx).
		Preload("AvatarFile").
		Preload("Prefecture").
		Where("auth_provider = ? AND provider_user_id = ?", authProvider, providerUserID).
		First(&user).Error
	if errors.Is(err, gorm.ErrRecordNotFound) {
		return entity.User{}, domainerrs.NotFound("User was not found")
	}
	if err != nil {
		return entity.User{}, err
	}
	return modelToEntityUser(user), nil
}

func (r *userRepository) FindByID(ctx context.Context, id string) (entity.User, error) {
	var user model.User
	err := r.db.WithContext(ctx).
		Preload("AvatarFile").
		Preload("Prefecture").
		First(&user, "id = ?", id).Error
	if errors.Is(err, gorm.ErrRecordNotFound) {
		return entity.User{}, domainerrs.NotFound("User was not found")
	}
	if err != nil {
		return entity.User{}, err
	}
	return modelToEntityUser(user), nil
}

func (r *userRepository) Create(ctx context.Context, params repository.CreateUserParams) (entity.User, error) {
	var created model.User
	err := r.db.WithContext(ctx).Transaction(func(tx *gorm.DB) error {
		created = model.User{
			ID:             params.ID,
			AuthProvider:   params.AuthProvider,
			ProviderUserID: params.ProviderUserID,
			Name:           &params.DisplayName,
			Bio:            params.Bio,
			Birthdate:      params.Birthdate,
			AgeVisibility:  params.AgeVisibility,
			PrefectureID:   params.PrefectureID,
			Sex:            params.Sex,
		}
		if err := tx.Create(&created).Error; err != nil {
			return err
		}

		if params.AvatarURL != nil && *params.AvatarURL != "" {
			file := model.File{
				ID:               uuid.NewString(),
				FilePath:         *params.AvatarURL,
				FileType:         "avatar",
				MimeType:         "application/octet-stream",
				FileSize:         0,
				UploadedByUserID: created.ID,
			}
			if err := tx.Create(&file).Error; err != nil {
				return err
			}
			fileID := file.ID
			created.AvatarFileID = &fileID
			if err := tx.Model(&model.User{}).Where("id = ?", created.ID).Update("avatar_file_id", fileID).Error; err != nil {
				return err
			}
		}

		if params.CreateSettings {
			settings := model.UserSettings{
				ID:     uuid.NewString(),
				UserID: created.ID,
			}
			if err := tx.Create(&settings).Error; err != nil {
				return err
			}
		}

		if err := tx.Preload("AvatarFile").Preload("Prefecture").First(&created, "id = ?", created.ID).Error; err != nil {
			return err
		}
		return nil
	})
	if err != nil {
		return entity.User{}, err
	}
	return modelToEntityUser(created), nil
}

func (r *userRepository) Update(ctx context.Context, userID string, params repository.UpdateUserParams) (entity.User, error) {
	var updated model.User
	err := r.db.WithContext(ctx).Transaction(func(tx *gorm.DB) error {
		if err := tx.Preload("AvatarFile").First(&updated, "id = ?", userID).Error; err != nil {
			if errors.Is(err, gorm.ErrRecordNotFound) {
				return domainerrs.NotFound("User was not found")
			}
			return err
		}

		if params.DisplayName != nil {
			updated.Name = params.DisplayName
		}
		if params.Bio != nil {
			updated.Bio = params.Bio
		}
		if params.BirthdateSet {
			updated.Birthdate = params.Birthdate
		}
		if params.AgeVisibility != nil && *params.AgeVisibility != "" {
			updated.AgeVisibility = *params.AgeVisibility
		}
		if params.PrefectureID != nil {
			updated.PrefectureID = params.PrefectureID
		}
		if params.Sex != nil && *params.Sex != "" {
			updated.Sex = *params.Sex
		}
		if params.AvatarURLSet {
			if params.AvatarURL == nil || *params.AvatarURL == "" {
				updated.AvatarFileID = nil
				updated.AvatarFile = nil
			} else {
				file := model.File{
					ID:               uuid.NewString(),
					FilePath:         *params.AvatarURL,
					FileType:         "avatar",
					MimeType:         "application/octet-stream",
					FileSize:         0,
					UploadedByUserID: updated.ID,
				}
				if err := tx.Create(&file).Error; err != nil {
					return err
				}
				updated.AvatarFileID = &file.ID
			}
		}

		if err := tx.Save(&updated).Error; err != nil {
			return err
		}
		if err := tx.Preload("AvatarFile").Preload("Prefecture").First(&updated, "id = ?", updated.ID).Error; err != nil {
			return err
		}
		return nil
	})
	if err != nil {
		return entity.User{}, err
	}
	return modelToEntityUser(updated), nil
}

func (r *userRepository) DeleteWithCleanup(ctx context.Context, userID string) error {
	return r.db.WithContext(ctx).Transaction(func(tx *gorm.DB) error {
		if err := userCleanupRelatedData(tx, userID); err != nil {
			return err
		}

		if err := tx.Where("user_id = ?", userID).Delete(&model.UserSettings{}).Error; err != nil {
			return err
		}
		if err := tx.Where("user_id = ?", userID).Delete(&model.UserDevice{}).Error; err != nil {
			return err
		}
		if err := userDeleteIfTableExists(tx, &model.MusicConnection{}, "user_id = ?", userID); err != nil {
			return err
		}
		if err := userDeleteIfTableExists(tx, &model.BleToken{}, "user_id = ?", userID); err != nil {
			return err
		}
		if err := userDeleteIfTableExists(tx, &model.File{}, "uploaded_by_user_id = ?", userID); err != nil {
			return err
		}

		return tx.Where("id = ?", userID).Delete(&model.User{}).Error
	})
}

// ─── package-level helpers ────────────────────────────────────────────────────

const (
	rdbDeletedUserAuthProvider   = "system"
	rdbDeletedUserProviderUserID = "deleted-user"
	rdbDeletedUserDisplayName    = "削除済みユーザー"
)

func userHasTable(tx *gorm.DB, tableModel any) bool {
	return tx.Migrator().HasTable(tableModel)
}

func userDeleteIfTableExists(tx *gorm.DB, tableModel any, query any, args ...any) error {
	if !userHasTable(tx, tableModel) {
		return nil
	}
	return tx.Where(query, args...).Delete(tableModel).Error
}

func userCleanupRelatedData(tx *gorm.DB, userID string) error {
	encounterIDs := make([]string, 0)
	if userHasTable(tx, &model.Encounter{}) {
		if err := tx.Model(&model.Encounter{}).
			Where("user_id1 = ? OR user_id2 = ?", userID, userID).
			Pluck("id", &encounterIDs).Error; err != nil {
			return err
		}
	}

	if len(encounterIDs) > 0 {
		if err := userDeleteIfTableExists(tx, &model.EncounterRead{}, "encounter_id IN ?", encounterIDs); err != nil {
			return err
		}
		if err := userDeleteIfTableExists(tx, &model.Comment{}, "encounter_id IN ?", encounterIDs); err != nil {
			return err
		}
		if err := userDeleteIfTableExists(tx, &model.OutboxNotification{}, "encounter_id IN ?", encounterIDs); err != nil {
			return err
		}
	}

	if err := userDeleteIfTableExists(tx, &model.EncounterRead{}, "user_id = ?", userID); err != nil {
		return err
	}
	if err := userDeleteIfTableExists(tx, &model.Comment{}, "commenter_user_id = ?", userID); err != nil {
		return err
	}
	if err := userDeleteIfTableExists(tx, &model.DailyEncounterCount{}, "user_id = ?", userID); err != nil {
		return err
	}
	if err := userDeleteIfTableExists(tx, &model.OutboxNotification{}, "user_id = ?", userID); err != nil {
		return err
	}
	if err := userDeleteIfTableExists(tx, &model.Encounter{}, "user_id1 = ? OR user_id2 = ?", userID, userID); err != nil {
		return err
	}
	if err := userDeleteIfTableExists(tx, &model.Report{}, "reporter_user_id = ? OR reported_user_id = ?", userID, userID); err != nil {
		return err
	}
	if err := userDeleteIfTableExists(tx, &model.Block{}, "blocker_user_id = ? OR blocked_user_id = ?", userID, userID); err != nil {
		return err
	}
	if err := userDeleteIfTableExists(tx, &model.Mute{}, "user_id = ? OR target_user_id = ?", userID, userID); err != nil {
		return err
	}
	if err := userDeleteIfTableExists(tx, &model.UserTrack{}, "user_id = ?", userID); err != nil {
		return err
	}
	if err := userDeleteIfTableExists(tx, &model.UserCurrentTrack{}, "user_id = ?", userID); err != nil {
		return err
	}
	if err := userDeleteIfTableExists(tx, &model.TrackFavorite{}, "user_id = ?", userID); err != nil {
		return err
	}

	playlistIDs := make([]string, 0)
	if userHasTable(tx, &model.Playlist{}) {
		if err := tx.Model(&model.Playlist{}).Where("user_id = ?", userID).Pluck("id", &playlistIDs).Error; err != nil {
			return err
		}
	}
	if len(playlistIDs) > 0 {
		if err := userDeleteIfTableExists(tx, &model.PlaylistTrack{}, "playlist_id IN ?", playlistIDs); err != nil {
			return err
		}
		if err := userDeleteIfTableExists(tx, &model.PlaylistFavorite{}, "playlist_id IN ?", playlistIDs); err != nil {
			return err
		}
	}
	if err := userDeleteIfTableExists(tx, &model.PlaylistFavorite{}, "user_id = ?", userID); err != nil {
		return err
	}
	if err := userDeleteIfTableExists(tx, &model.Playlist{}, "user_id = ?", userID); err != nil {
		return err
	}
	if err := userDeleteIfTableExists(tx, &model.SongLike{}, "user_id = ?", userID); err != nil {
		return err
	}

	chainIDs := make([]string, 0)
	if userHasTable(tx, &model.LyricEntry{}) {
		if err := tx.Model(&model.LyricEntry{}).Where("user_id = ?", userID).Distinct().Pluck("chain_id", &chainIDs).Error; err != nil {
			return err
		}
	}
	for _, chainID := range chainIDs {
		var otherCount int64
		if err := tx.Model(&model.LyricEntry{}).Where("chain_id = ? AND user_id <> ?", chainID, userID).Count(&otherCount).Error; err != nil {
			return err
		}
		if otherCount == 0 {
			if err := userDeleteIfTableExists(tx, &model.GeneratedSong{}, "chain_id = ?", chainID); err != nil {
				return err
			}
			if err := userDeleteIfTableExists(tx, &model.OutboxLyriaJob{}, "chain_id = ?", chainID); err != nil {
				return err
			}
			if err := userDeleteIfTableExists(tx, &model.LyricEntry{}, "chain_id = ?", chainID); err != nil {
				return err
			}
			if err := userDeleteIfTableExists(tx, &model.LyricChain{}, "id = ?", chainID); err != nil {
				return err
			}
			continue
		}
		deletedUserID, err := rdbGetOrCreateDeletedUserID(tx)
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

func rdbGetOrCreateDeletedUserID(tx *gorm.DB) (string, error) {
	var deletedUser model.User
	err := tx.Where("auth_provider = ? AND provider_user_id = ?", rdbDeletedUserAuthProvider, rdbDeletedUserProviderUserID).First(&deletedUser).Error
	if err == nil {
		if deletedUser.Name == nil || *deletedUser.Name != rdbDeletedUserDisplayName {
			name := rdbDeletedUserDisplayName
			if updateErr := tx.Model(&model.User{}).Where("id = ?", deletedUser.ID).Update("name", name).Error; updateErr != nil {
				return "", updateErr
			}
		}
		return deletedUser.ID, nil
	}
	if !errors.Is(err, gorm.ErrRecordNotFound) {
		return "", err
	}

	name := rdbDeletedUserDisplayName
	candidate := model.User{
		ID:             uuid.NewString(),
		AuthProvider:   rdbDeletedUserAuthProvider,
		ProviderUserID: rdbDeletedUserProviderUserID,
		Name:           &name,
		AgeVisibility:  "hidden",
		Sex:            "no-answer",
	}
	if err := tx.Clauses(clause.OnConflict{DoNothing: true}).Create(&candidate).Error; err != nil {
		return "", err
	}
	if err := tx.Where("auth_provider = ? AND provider_user_id = ?", rdbDeletedUserAuthProvider, rdbDeletedUserProviderUserID).First(&deletedUser).Error; err != nil {
		return "", err
	}
	return deletedUser.ID, nil
}

func modelToEntityUser(user model.User) entity.User {
	var avatarURL *string
	if user.AvatarFile != nil {
		u := user.AvatarFile.FilePath
		avatarURL = &u
	}

	var prefectureName *string
	if user.Prefecture != nil {
		p := user.Prefecture.Name
		prefectureName = &p
	}

	return entity.User{
		ID:             user.ID,
		AuthProvider:   user.AuthProvider,
		ProviderUserID: user.ProviderUserID,
		Name:           user.Name,
		Bio:            user.Bio,
		Birthdate:      user.Birthdate,
		AgeVisibility:  user.AgeVisibility,
		PrefectureID:   user.PrefectureID,
		PrefectureName: prefectureName,
		Sex:            user.Sex,
		AvatarFileID:   user.AvatarFileID,
		AvatarURL:      avatarURL,
		CreatedAt:      user.CreatedAt,
		UpdatedAt:      user.UpdatedAt,
	}
}
