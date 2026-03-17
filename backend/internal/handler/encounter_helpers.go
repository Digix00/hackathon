package handler

import (
	"time"

	schemares "hackathon/internal/handler/schema/response"
	usecasedto "hackathon/internal/usecase/dto"
)

func encounterSummaryDTOToResponse(dto usecasedto.EncounterSummaryDTO) schemares.EncounterSummary {
	return schemares.EncounterSummary{
		ID:         dto.ID,
		Type:       dto.Type,
		User:       encounterUserDTOToResponse(dto.User),
		OccurredAt: dto.OccurredAt.UTC().Format(time.RFC3339),
	}
}

func encounterListItemDTOToResponse(dto usecasedto.EncounterListItemDTO) schemares.EncounterListItem {
	return schemares.EncounterListItem{
		ID:         dto.ID,
		Type:       dto.Type,
		User:       encounterUserDTOToResponse(dto.User),
		IsRead:     dto.IsRead,
		Tracks:     encounterTrackDTOsToResponse(dto.Tracks),
		OccurredAt: dto.OccurredAt.UTC().Format(time.RFC3339),
	}
}

func encounterDetailDTOToResponse(dto usecasedto.EncounterDetailDTO) schemares.EncounterDetail {
	return schemares.EncounterDetail{
		ID:         dto.ID,
		Type:       dto.Type,
		User:       encounterUserDTOToResponse(dto.User),
		OccurredAt: dto.OccurredAt.UTC().Format(time.RFC3339),
		Tracks:     encounterTrackDTOsToResponse(dto.Tracks),
	}
}

func encounterUserDTOToResponse(dto usecasedto.EncounterUserDTO) schemares.EncounterUser {
	return schemares.EncounterUser{
		ID:          dto.ID,
		DisplayName: dto.DisplayName,
		AvatarURL:   dto.AvatarURL,
	}
}

func encounterTrackDTOsToResponse(tracks []usecasedto.EncounterTrackDTO) []schemares.EncounterTrack {
	if len(tracks) == 0 {
		return []schemares.EncounterTrack{}
	}
	result := make([]schemares.EncounterTrack, 0, len(tracks))
	for _, track := range tracks {
		result = append(result, schemares.EncounterTrack{
			ID:         track.ID,
			Title:      track.Title,
			ArtistName: track.ArtistName,
			ArtworkURL: track.ArtworkURL,
			PreviewURL: track.PreviewURL,
		})
	}
	return result
}
