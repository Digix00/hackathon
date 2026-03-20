package usecase

import (
	"context"
	"errors"
	"time"

	"github.com/google/uuid"
	"go.uber.org/zap"

	"hackathon/internal/domain/entity"
	domainerrs "hackathon/internal/domain/errs"
	"hackathon/internal/domain/repository"
	"hackathon/internal/domain/vo"
	"hackathon/internal/usecase/dto"
	"hackathon/internal/util"
)

type SettingsUsecase interface {
	GetMySettings(ctx context.Context, authUID string) (dto.Settings, error)
	PatchMySettings(ctx context.Context, authUID string, input dto.UpdateSettingsInput) (dto.Settings, error)
}

type settingsUsecase struct {
	log          *zap.Logger
	userRepo     repository.UserRepository
	settingsRepo repository.UserSettingsRepository
}

func NewSettingsUsecase(log *zap.Logger, userRepo repository.UserRepository, settingsRepo repository.UserSettingsRepository) SettingsUsecase {
	return &settingsUsecase{
		log:          log,
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
		freq, err := vo.ParseNotificationFrequency(*input.NotificationFrequency)
		if err != nil {
			return dto.Settings{}, err
		}
		settings.NotificationFrequency = freq
	}
	if input.ThemeMode != nil {
		mode, err := vo.ParseThemeMode(*input.ThemeMode)
		if err != nil {
			return dto.Settings{}, err
		}
		settings.ThemeMode = mode
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

	util.ApplyIfSet(&settings.BleEnabled, input.BleEnabled)
	util.ApplyIfSet(&settings.LocationEnabled, input.LocationEnabled)
	util.ApplyIfSet(&settings.ScheduleEnabled, input.ScheduleEnabled)
	util.ApplyIfSet(&settings.ProfileVisible, input.ProfileVisible)
	util.ApplyIfSet(&settings.TrackVisible, input.TrackVisible)
	util.ApplyIfSet(&settings.NotificationEnabled, input.NotificationEnabled)
	util.ApplyIfSet(&settings.EncounterNotificationEnabled, input.EncounterNotificationEnabled)
	util.ApplyIfSet(&settings.BatchNotificationEnabled, input.BatchNotificationEnabled)
	util.ApplyIfSet(&settings.CommentNotificationEnabled, input.CommentNotificationEnabled)
	util.ApplyIfSet(&settings.LikeNotificationEnabled, input.LikeNotificationEnabled)
	util.ApplyIfSet(&settings.AnnouncementNotificationEnabled, input.AnnouncementNotificationEnabled)

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

	settings = entity.NewUserSettings(uuid.NewString(), userID)
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
		NotificationFrequency:           string(settings.NotificationFrequency),
		CommentNotificationEnabled:      settings.CommentNotificationEnabled,
		LikeNotificationEnabled:         settings.LikeNotificationEnabled,
		AnnouncementNotificationEnabled: settings.AnnouncementNotificationEnabled,
		ThemeMode:                       string(settings.ThemeMode),
		UpdatedAt:                       settings.UpdatedAt,
	}
}
