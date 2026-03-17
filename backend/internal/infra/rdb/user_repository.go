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
	"hackathon/internal/infra/rdb/converter"
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
	return converter.ModelToEntityUser(user), nil
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
	return converter.ModelToEntityUser(user), nil
}

func (r *userRepository) FindByIDs(ctx context.Context, ids []string) (map[string]entity.User, error) {
	if len(ids) == 0 {
		return map[string]entity.User{}, nil
	}

	var users []model.User
	if err := r.db.WithContext(ctx).
		Preload("AvatarFile").
		Preload("Prefecture").
		Where("id IN ?", ids).
		Find(&users).Error; err != nil {
		return nil, err
	}

	result := make(map[string]entity.User, len(users))
	for _, u := range users {
		result[u.ID] = converter.ModelToEntityUser(u)
	}
	return result, nil
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
			AgeVisibility:  string(params.AgeVisibility),
			PrefectureID:   params.PrefectureID,
			Sex:            string(params.Sex),
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
	return converter.ModelToEntityUser(created), nil
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
		if params.AgeVisibility != nil {
			updated.AgeVisibility = string(*params.AgeVisibility)
		}
		if params.PrefectureID != nil {
			updated.PrefectureID = params.PrefectureID
		}
		if params.Sex != nil {
			updated.Sex = string(*params.Sex)
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
	return converter.ModelToEntityUser(updated), nil
}

func (r *userRepository) DeleteWithCleanup(ctx context.Context, userID string) error {
	return r.db.WithContext(ctx).Transaction(func(tx *gorm.DB) error {
		if err := userCleanupRelatedData(tx, userID); err != nil {
			return err
		}

		tables := []struct {
			model any
			query string
		}{
			{&model.UserSettings{}, "user_id = ?"},
			{&model.UserDevice{}, "user_id = ?"},
			{&model.MusicConnection{}, "user_id = ?"},
			{&model.BleToken{}, "user_id = ?"},
			{&model.File{}, "uploaded_by_user_id = ?"},
		}
		for _, t := range tables {
			if err := tx.Where(t.query, userID).Delete(t.model).Error; err != nil {
				return err
			}
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

func userCleanupRelatedData(tx *gorm.DB, userID string) error {
	// encounter に連鎖する子レコードを先に削除
	var encounterIDs []string
	if err := tx.Model(&model.Encounter{}).
		Where("user_id1 = ? OR user_id2 = ?", userID, userID).
		Pluck("id", &encounterIDs).Error; err != nil {
		return err
	}
	if len(encounterIDs) > 0 {
		if err := tx.Where("encounter_id IN ?", encounterIDs).Delete(&model.EncounterRead{}).Error; err != nil {
			return err
		}
		if err := tx.Where("encounter_id IN ?", encounterIDs).Delete(&model.Comment{}).Error; err != nil {
			return err
		}
		if err := tx.Where("encounter_id IN ?", encounterIDs).Delete(&model.OutboxNotification{}).Error; err != nil {
			return err
		}
	}

	simpleDeletes := []struct {
		model any
		query string
		args  []any
	}{
		{&model.EncounterRead{}, "user_id = ?", []any{userID}},
		{&model.Comment{}, "commenter_user_id = ?", []any{userID}},
		{&model.DailyEncounterCount{}, "user_id = ?", []any{userID}},
		{&model.OutboxNotification{}, "user_id = ?", []any{userID}},
		{&model.Encounter{}, "user_id1 = ? OR user_id2 = ?", []any{userID, userID}},
		{&model.Report{}, "reporter_user_id = ? OR reported_user_id = ?", []any{userID, userID}},
		{&model.Block{}, "blocker_user_id = ? OR blocked_user_id = ?", []any{userID, userID}},
		{&model.Mute{}, "user_id = ? OR target_user_id = ?", []any{userID, userID}},
		{&model.UserTrack{}, "user_id = ?", []any{userID}},
		{&model.UserCurrentTrack{}, "user_id = ?", []any{userID}},
		{&model.TrackFavorite{}, "user_id = ?", []any{userID}},
	}
	for _, d := range simpleDeletes {
		if err := tx.Where(d.query, d.args...).Delete(d.model).Error; err != nil {
			return err
		}
	}

	// playlist に連鎖する子レコードを先に削除
	var playlistIDs []string
	if err := tx.Model(&model.Playlist{}).Where("user_id = ?", userID).Pluck("id", &playlistIDs).Error; err != nil {
		return err
	}
	if len(playlistIDs) > 0 {
		if err := tx.Where("playlist_id IN ?", playlistIDs).Delete(&model.PlaylistTrack{}).Error; err != nil {
			return err
		}
		if err := tx.Where("playlist_id IN ?", playlistIDs).Delete(&model.PlaylistFavorite{}).Error; err != nil {
			return err
		}
	}
	if err := tx.Where("user_id = ?", userID).Delete(&model.PlaylistFavorite{}).Error; err != nil {
		return err
	}
	if err := tx.Where("user_id = ?", userID).Delete(&model.Playlist{}).Error; err != nil {
		return err
	}
	if err := tx.Where("user_id = ?", userID).Delete(&model.SongLike{}).Error; err != nil {
		return err
	}

	// lyric chain: 他参加者がいるチェーンは削除済みユーザーに所有権を移譲
	var chainIDs []string
	if err := tx.Model(&model.LyricEntry{}).Where("user_id = ?", userID).Distinct().Pluck("chain_id", &chainIDs).Error; err != nil {
		return err
	}
	for _, chainID := range chainIDs {
		var otherCount int64
		if err := tx.Model(&model.LyricEntry{}).Where("chain_id = ? AND user_id <> ?", chainID, userID).Count(&otherCount).Error; err != nil {
			return err
		}
		if otherCount == 0 {
			for _, m := range []any{&model.GeneratedSong{}, &model.OutboxLyriaJob{}, &model.LyricEntry{}} {
				if err := tx.Where("chain_id = ?", chainID).Delete(m).Error; err != nil {
					return err
				}
			}
			if err := tx.Where("id = ?", chainID).Delete(&model.LyricChain{}).Error; err != nil {
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
