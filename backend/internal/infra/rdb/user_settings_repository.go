package rdb

import (
	"context"
	"errors"

	"go.uber.org/zap"
	"gorm.io/gorm"

	"hackathon/internal/domain/entity"
	domainerrs "hackathon/internal/domain/errs"
	"hackathon/internal/domain/repository"
	"hackathon/internal/domain/vo"
	"hackathon/internal/infra/rdb/model"
)

type userSettingsRepository struct {
	log *zap.Logger
	db  *gorm.DB
}

func NewUserSettingsRepository(log *zap.Logger, db *gorm.DB) repository.UserSettingsRepository {
	return &userSettingsRepository{log: log, db: db}
}

func (r *userSettingsRepository) FindByUserID(ctx context.Context, userID string) (entity.UserSettings, error) {
	var settings model.UserSettings
	err := r.db.WithContext(ctx).Where("user_id = ?", userID).First(&settings).Error
	if errors.Is(err, gorm.ErrRecordNotFound) {
		return entity.UserSettings{}, domainerrs.NotFound("Settings was not found")
	}
	if err != nil {
		return entity.UserSettings{}, err
	}
	return toUserSettingsEntity(settings), nil
}

func (r *userSettingsRepository) Create(ctx context.Context, settings *entity.UserSettings) error {
	record := model.UserSettings{
		ID:                              settings.ID,
		UserID:                          settings.UserID,
		BleEnabled:                      settings.BleEnabled,
		LocationEnabled:                 settings.LocationEnabled,
		DetectionDistance:               settings.DetectionDistance,
		ScheduleEnabled:                 settings.ScheduleEnabled,
		ScheduleStartTime:               settings.ScheduleStartTime,
		ScheduleEndTime:                 settings.ScheduleEndTime,
		ProfileVisible:                  settings.ProfileVisible,
		TrackVisible:                    settings.TrackVisible,
		NotificationEnabled:             settings.NotificationEnabled,
		EncounterNotificationEnabled:    settings.EncounterNotificationEnabled,
		BatchNotificationEnabled:        settings.BatchNotificationEnabled,
		NotificationFrequency:           string(settings.NotificationFrequency),
		CommentNotificationEnabled:      settings.CommentNotificationEnabled,
		LikeNotificationEnabled:         settings.LikeNotificationEnabled,
		AnnouncementNotificationEnabled: settings.AnnouncementNotificationEnabled,
		ThemeMode:                       string(settings.ThemeMode),
	}
	if err := r.db.WithContext(ctx).Create(&record).Error; err != nil {
		return err
	}
	*settings = toUserSettingsEntity(record)
	return nil
}

func (r *userSettingsRepository) Update(ctx context.Context, settings *entity.UserSettings) error {
	err := r.db.WithContext(ctx).
		Model(&model.UserSettings{}).
		Where("id = ?", settings.ID).
		Updates(map[string]any{
			"ble_enabled":                       settings.BleEnabled,
			"location_enabled":                  settings.LocationEnabled,
			"detection_distance":                settings.DetectionDistance,
			"schedule_enabled":                  settings.ScheduleEnabled,
			"schedule_start_time":               settings.ScheduleStartTime,
			"schedule_end_time":                 settings.ScheduleEndTime,
			"profile_visible":                   settings.ProfileVisible,
			"track_visible":                     settings.TrackVisible,
			"notification_enabled":              settings.NotificationEnabled,
			"encounter_notification_enabled":    settings.EncounterNotificationEnabled,
			"batch_notification_enabled":        settings.BatchNotificationEnabled,
			"notification_frequency":            string(settings.NotificationFrequency),
			"comment_notification_enabled":      settings.CommentNotificationEnabled,
			"like_notification_enabled":         settings.LikeNotificationEnabled,
			"announcement_notification_enabled": settings.AnnouncementNotificationEnabled,
			"theme_mode":                        string(settings.ThemeMode),
		}).Error
	if err != nil {
		return err
	}

	updated, err := r.FindByUserID(ctx, settings.UserID)
	if err != nil {
		return err
	}
	*settings = updated
	return nil
}

func toUserSettingsEntity(settings model.UserSettings) entity.UserSettings {
	return entity.UserSettings{
		ID:                              settings.ID,
		UserID:                          settings.UserID,
		BleEnabled:                      settings.BleEnabled,
		LocationEnabled:                 settings.LocationEnabled,
		DetectionDistance:               settings.DetectionDistance,
		ScheduleEnabled:                 settings.ScheduleEnabled,
		ScheduleStartTime:               settings.ScheduleStartTime,
		ScheduleEndTime:                 settings.ScheduleEndTime,
		ProfileVisible:                  settings.ProfileVisible,
		TrackVisible:                    settings.TrackVisible,
		NotificationEnabled:             settings.NotificationEnabled,
		EncounterNotificationEnabled:    settings.EncounterNotificationEnabled,
		BatchNotificationEnabled:        settings.BatchNotificationEnabled,
		NotificationFrequency:           vo.NotificationFrequency(settings.NotificationFrequency),
		CommentNotificationEnabled:      settings.CommentNotificationEnabled,
		LikeNotificationEnabled:         settings.LikeNotificationEnabled,
		AnnouncementNotificationEnabled: settings.AnnouncementNotificationEnabled,
		ThemeMode:                       vo.ThemeMode(settings.ThemeMode),
		CreatedAt:                       settings.CreatedAt,
		UpdatedAt:                       settings.UpdatedAt,
	}
}
