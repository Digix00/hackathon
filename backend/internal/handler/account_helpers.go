package handler

import (
	"time"

	schemares "hackathon/internal/handler/schema/response"
	usecasedto "hackathon/internal/usecase/dto"
)

func settingsDTOToResponse(settings usecasedto.Settings) schemares.Settings {
	return schemares.Settings{
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
		UpdatedAt:                       settings.UpdatedAt.UTC().Format(time.RFC3339),
	}
}

func deviceDTOToResponse(device usecasedto.Device) schemares.Device {
	return schemares.Device{
		ID:        device.ID,
		Platform:  device.Platform,
		DeviceID:  device.DeviceID,
		Enabled:   device.Enabled,
		UpdatedAt: device.UpdatedAt.UTC().Format(time.RFC3339),
	}
}

func userDTOToResponse(user usecasedto.UserDTO) schemares.User {
	return schemares.User{
		ID:            user.ID,
		DisplayName:   user.DisplayName,
		AvatarURL:     user.AvatarURL,
		Bio:           user.Bio,
		Birthdate:     user.Birthdate,
		AgeVisibility: user.AgeVisibility,
		PrefectureID:  user.PrefectureID,
		Sex:           user.Sex,
		CreatedAt:     user.CreatedAt.UTC().Format(time.RFC3339),
		UpdatedAt:     user.UpdatedAt.UTC().Format(time.RFC3339),
	}
}

func publicUserDTOToResponse(user usecasedto.PublicUserDTO) schemares.PublicUser {
	var sharedTrack *schemares.PublicTrack
	if user.SharedTrack != nil {
		sharedTrack = &schemares.PublicTrack{
			ID:         user.SharedTrack.ID,
			Title:      user.SharedTrack.Title,
			ArtistName: user.SharedTrack.ArtistName,
			ArtworkURL: user.SharedTrack.ArtworkURL,
			PreviewURL: nil,
		}
	}

	return schemares.PublicUser{
		ID:             user.ID,
		DisplayName:    user.DisplayName,
		AvatarURL:      user.AvatarURL,
		Bio:            user.Bio,
		Birthplace:     user.Birthplace,
		AgeRange:       user.AgeRange,
		EncounterCount: user.EncounterCount,
		SharedTrack:    sharedTrack,
		UpdatedAt:      user.UpdatedAt.UTC().Format(time.RFC3339),
	}
}
