package usecase

import (
	"context"
	"errors"
	"time"

	"github.com/google/uuid"

	"hackathon/internal/domain/entity"
	domainerrs "hackathon/internal/domain/errs"
	"hackathon/internal/domain/repository"
	"hackathon/internal/usecase/dto"
)

const firebaseProvider = "firebase"

var validNotificationFrequencies = map[string]struct{}{
	"immediate": {},
	"hourly":    {},
	"daily":     {},
}

var validThemeModes = map[string]struct{}{
	"light":  {},
	"dark":   {},
	"system": {},
}

type SettingsUsecase interface {
	GetMySettings(ctx context.Context, authUID string) (dto.Settings, error)
	PatchMySettings(ctx context.Context, authUID string, input dto.UpdateSettingsInput) (dto.Settings, error)
}

type settingsUsecase struct {
	userRepo     repository.UserRepository
	settingsRepo repository.UserSettingsRepository
}

func NewSettingsUsecase(userRepo repository.UserRepository, settingsRepo repository.UserSettingsRepository) SettingsUsecase {
	return &settingsUsecase{
		userRepo:     userRepo,
		settingsRepo: settingsRepo,
	}
}

func (u *settingsUsecase) GetMySettings(ctx context.Context, authUID string) (dto.Settings, error) {
	user, err := u.userRepo.FindByAuthProviderAndProviderUserID(ctx, firebaseProvider, authUID)
	if err != nil {
		return dto.Settings{}, err
	}

	settings, err := u.getOrCreateSettings(ctx, user.ID)
	if err != nil {
		return dto.Settings{}, err
	}
	return toSettingsDTO(settings), nil
}

func (u *settingsUsecase) PatchMySettings(ctx context.Context, authUID string, input dto.UpdateSettingsInput) (dto.Settings, error) {
	user, err := u.userRepo.FindByAuthProviderAndProviderUserID(ctx, firebaseProvider, authUID)
	if err != nil {
		return dto.Settings{}, err
	}

	settings, err := u.getOrCreateSettings(ctx, user.ID)
	if err != nil {
		return dto.Settings{}, err
	}

	if input.DetectionDistance != nil {
		if *input.DetectionDistance < 10 || *input.DetectionDistance > 100 {
			return dto.Settings{}, domainerrs.BadRequest("detection_distance must be between 10 and 100")
		}
		settings.DetectionDistance = *input.DetectionDistance
	}
	if input.NotificationFrequency != nil {
		if _, exists := validNotificationFrequencies[*input.NotificationFrequency]; !exists {
			return dto.Settings{}, domainerrs.BadRequest("notification_frequency is invalid")
		}
		settings.NotificationFrequency = *input.NotificationFrequency
	}
	if input.ThemeMode != nil {
		if _, exists := validThemeModes[*input.ThemeMode]; !exists {
			return dto.Settings{}, domainerrs.BadRequest("theme_mode is invalid")
		}
		settings.ThemeMode = *input.ThemeMode
	}
	if input.ScheduleStartTime != nil {
		if err := validateClockTime(*input.ScheduleStartTime); err != nil {
			return dto.Settings{}, domainerrs.BadRequest("schedule_start_time must be HH:MM")
		}
		settings.ScheduleStartTime = input.ScheduleStartTime
	}
	if input.ScheduleEndTime != nil {
		if err := validateClockTime(*input.ScheduleEndTime); err != nil {
			return dto.Settings{}, domainerrs.BadRequest("schedule_end_time must be HH:MM")
		}
		settings.ScheduleEndTime = input.ScheduleEndTime
	}
	if input.BleEnabled != nil {
		settings.BleEnabled = *input.BleEnabled
	}
	if input.LocationEnabled != nil {
		settings.LocationEnabled = *input.LocationEnabled
	}
	if input.ScheduleEnabled != nil {
		settings.ScheduleEnabled = *input.ScheduleEnabled
	}
	if input.ProfileVisible != nil {
		settings.ProfileVisible = *input.ProfileVisible
	}
	if input.TrackVisible != nil {
		settings.TrackVisible = *input.TrackVisible
	}
	if input.NotificationEnabled != nil {
		settings.NotificationEnabled = *input.NotificationEnabled
	}
	if input.EncounterNotificationEnabled != nil {
		settings.EncounterNotificationEnabled = *input.EncounterNotificationEnabled
	}
	if input.BatchNotificationEnabled != nil {
		settings.BatchNotificationEnabled = *input.BatchNotificationEnabled
	}
	if input.CommentNotificationEnabled != nil {
		settings.CommentNotificationEnabled = *input.CommentNotificationEnabled
	}
	if input.LikeNotificationEnabled != nil {
		settings.LikeNotificationEnabled = *input.LikeNotificationEnabled
	}
	if input.AnnouncementNotificationEnabled != nil {
		settings.AnnouncementNotificationEnabled = *input.AnnouncementNotificationEnabled
	}

	if err := u.settingsRepo.Update(ctx, &settings); err != nil {
		return dto.Settings{}, err
	}

	return toSettingsDTO(settings), nil
}

func (u *settingsUsecase) getOrCreateSettings(ctx context.Context, userID string) (entity.UserSettings, error) {
	settings, err := u.settingsRepo.FindByUserID(ctx, userID)
	if err == nil {
		return settings, nil
	}
	if !errors.Is(err, domainerrs.ErrNotFound) {
		return entity.UserSettings{}, err
	}

	settings = entity.UserSettings{
		ID:                              uuid.NewString(),
		UserID:                          userID,
		BleEnabled:                      true,
		LocationEnabled:                 true,
		DetectionDistance:               50,
		ScheduleEnabled:                 false,
		ProfileVisible:                  true,
		TrackVisible:                    true,
		NotificationEnabled:             true,
		EncounterNotificationEnabled:    true,
		BatchNotificationEnabled:        true,
		NotificationFrequency:           "hourly",
		CommentNotificationEnabled:      true,
		LikeNotificationEnabled:         true,
		AnnouncementNotificationEnabled: true,
		ThemeMode:                       "system",
	}
	if err := u.settingsRepo.Create(ctx, &settings); err != nil {
		return entity.UserSettings{}, err
	}
	return settings, nil
}

func validateClockTime(value string) error {
	if value == "" {
		return nil
	}
	_, err := time.Parse("15:04", value)
	return err
}

func toSettingsDTO(settings entity.UserSettings) dto.Settings {
	return dto.Settings{
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
		NotificationFrequency:           settings.NotificationFrequency,
		CommentNotificationEnabled:      settings.CommentNotificationEnabled,
		LikeNotificationEnabled:         settings.LikeNotificationEnabled,
		AnnouncementNotificationEnabled: settings.AnnouncementNotificationEnabled,
		ThemeMode:                       settings.ThemeMode,
		UpdatedAt:                       settings.UpdatedAt,
	}
}
