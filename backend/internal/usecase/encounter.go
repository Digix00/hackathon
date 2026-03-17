package usecase

import (
	"context"
	"encoding/base64"
	"encoding/json"
	"time"

	"github.com/google/uuid"

	"hackathon/internal/domain/entity"
	domainerrs "hackathon/internal/domain/errs"
	"hackathon/internal/domain/repository"
	"hackathon/internal/domain/vo"
	usecasedto "hackathon/internal/usecase/dto"
)

type EncounterUsecase interface {
	CreateEncounter(ctx context.Context, authUID string, input usecasedto.CreateEncounterInput) (usecasedto.EncounterSummaryDTO, bool, error)
	ListEncounters(ctx context.Context, authUID string, limit int, cursor string) ([]usecasedto.EncounterListItemDTO, *string, bool, error)
	GetEncounterByID(ctx context.Context, authUID string, encounterID string) (usecasedto.EncounterDetailDTO, error)
}

type encounterUsecase struct {
	userRepo      repository.UserRepository
	bleTokenRepo  repository.BleTokenRepository
	encounterRepo repository.EncounterRepository
	blockRepo     repository.BlockRepository
}

func NewEncounterUsecase(
	userRepo repository.UserRepository,
	bleTokenRepo repository.BleTokenRepository,
	encounterRepo repository.EncounterRepository,
	blockRepo repository.BlockRepository,
) EncounterUsecase {
	return &encounterUsecase{
		userRepo:      userRepo,
		bleTokenRepo:  bleTokenRepo,
		encounterRepo: encounterRepo,
		blockRepo:     blockRepo,
	}
}

func (u *encounterUsecase) CreateEncounter(ctx context.Context, authUID string, input usecasedto.CreateEncounterInput) (usecasedto.EncounterSummaryDTO, bool, error) {
	requester, err := u.userRepo.FindByAuthProviderAndProviderUserID(ctx, firebaseProvider, authUID)
	if err != nil {
		return usecasedto.EncounterSummaryDTO{}, false, err
	}

	encounterType, err := vo.ParseEncounterType(input.Type)
	if err != nil {
		return usecasedto.EncounterSummaryDTO{}, false, err
	}
	if encounterType != vo.EncounterTypeBLE {
		return usecasedto.EncounterSummaryDTO{}, false, domainerrs.BadRequest("type must be ble")
	}

	tokenEntity, err := u.bleTokenRepo.FindByToken(ctx, input.TargetBleToken)
	if err != nil {
		return usecasedto.EncounterSummaryDTO{}, false, err
	}
	now := time.Now().UTC()
	if !tokenEntity.IsValid(now) {
		return usecasedto.EncounterSummaryDTO{}, false, domainerrs.NotFound("BLE token has expired")
	}
	if tokenEntity.UserID == requester.ID {
		return usecasedto.EncounterSummaryDTO{}, false, domainerrs.BadRequest("target_ble_token must be another user")
	}

	blocked, err := u.blockRepo.ExistsBetween(ctx, requester.ID, tokenEntity.UserID)
	if err != nil {
		return usecasedto.EncounterSummaryDTO{}, false, err
	}
	if blocked {
		return usecasedto.EncounterSummaryDTO{}, false, domainerrs.NotFound("User was not found")
	}

	userID1 := requester.ID
	userID2 := tokenEntity.UserID
	if userID2 < userID1 {
		userID1, userID2 = userID2, userID1
	}

	const dedupeWindow = 5 * time.Minute
	const dedupeWindow = 5 * time.Minute
	if existing, found, err := u.encounterRepo.FindRecentByUsersAndType(ctx, userID1, userID2, encounterType, input.OccurredAt, dedupeWindow); err != nil {
		return usecasedto.EncounterSummaryDTO{}, false, err
	} else if found {
		otherUser, err := u.userRepo.FindByID(ctx, otherUserID(existing, requester.ID))
		if err != nil {
			return usecasedto.EncounterSummaryDTO{}, false, err
		}
		return usecasedto.EncounterSummaryDTO{
			ID:         existing.ID,
			Type:       string(existing.EncounterType),
			User:       buildEncounterUserDTO(otherUser),
			OccurredAt: existing.OccurredAt,
		}, false, nil
	}

	// 1日1回制限（同一ユーザーペア・同一タイプ）
	if dailyEncounterPairLimit > 0 {
		exists, err := u.encounterRepo.ExistsByUsersAndTypeOnDate(ctx, userID1, userID2, encounterType, serverNow)
		if err != nil {
			return usecasedto.EncounterSummaryDTO{}, false, err
		}
		if exists {
			return usecasedto.EncounterSummaryDTO{}, false, domainerrs.Conflict("daily encounter limit reached for this pair")
		}
	}

	created, err := u.encounterRepo.CreateWithRateLimit(ctx, entity.Encounter{
		ID:            uuid.NewString(),
		UserID1:       userID1,
		UserID2:       userID2,
		EncounterType: encounterType,
		OccurredAt:    input.OccurredAt,
	}, []string{requester.ID, tokenEntity.UserID}, requester.ID, serverNow, dailyEncounterUserLimit)
	if err != nil {
		return usecasedto.EncounterSummaryDTO{}, false, err
	}

	otherUser, err := u.userRepo.FindByID(ctx, otherUserID(created, requester.ID))
	if err != nil {
		return usecasedto.EncounterSummaryDTO{}, false, err
	}

	return usecasedto.EncounterSummaryDTO{
		ID:         created.ID,
		Type:       string(created.EncounterType),
		User:       buildEncounterUserDTO(otherUser),
		OccurredAt: created.OccurredAt,
	}, true, nil
}

func (u *encounterUsecase) ListEncounters(ctx context.Context, authUID string, limit int, cursor string) ([]usecasedto.EncounterListItemDTO, *string, bool, error) {
	requester, err := u.userRepo.FindByAuthProviderAndProviderUserID(ctx, firebaseProvider, authUID)
	if err != nil {
		return nil, nil, false, err
	}

	parsedCursor, err := parseEncounterCursor(cursor)
	if err != nil {
		return nil, nil, false, err
	}

	encounters, nextCursor, hasMore, err := u.encounterRepo.ListByUserID(ctx, requester.ID, limit, parsedCursor)
	if err != nil {
		return nil, nil, false, err
	}

	encounterIDs := make([]string, 0, len(encounters))
	for _, enc := range encounters {
		encounterIDs = append(encounterIDs, enc.ID)
	}

	tracksByEncounter, err := u.encounterRepo.ListTracksByEncounterIDs(ctx, encounterIDs)
	if err != nil {
		return nil, nil, false, err
	}

	readStatus, err := u.encounterRepo.GetReadStatusByEncounterIDs(ctx, requester.ID, encounterIDs)
	if err != nil {
		return nil, nil, false, err
	}

	items := make([]usecasedto.EncounterListItemDTO, 0, len(encounters))
	otherIDs := make([]string, 0, len(encounters))
	for _, enc := range encounters {
		otherIDs = append(otherIDs, otherUserID(enc, requester.ID))
	}

	blockedIDs, err := u.blockRepo.ListBlockedUserIDs(ctx, requester.ID, otherIDs)
	if err != nil {
		return nil, nil, false, err
	}

	userMap, err := u.userRepo.FindByIDs(ctx, otherIDs)
	if err != nil {
		return nil, nil, false, err
	}

	for _, enc := range encounters {
		otherID := otherUserID(enc, requester.ID)
		if blockedIDs[otherID] {
			continue
		}
		other, ok := userMap[otherID]
		if !ok {
			continue
		}
		tracks := buildEncounterTrackDTOs(tracksByEncounter[enc.ID])
		items = append(items, usecasedto.EncounterListItemDTO{
			ID:         enc.ID,
			Type:       string(enc.EncounterType),
			User:       buildEncounterUserDTO(other),
			IsRead:     readStatus[enc.ID],
			Tracks:     tracks,
			OccurredAt: enc.OccurredAt,
		})
	}

	nextCursorStr, err := encodeEncounterCursor(nextCursor)
	if err != nil {
		return nil, nil, false, err
	}

	if nextCursorStr == "" {
		return items, nil, hasMore, nil
	}
	return items, &nextCursorStr, hasMore, nil
}

func (u *encounterUsecase) GetEncounterByID(ctx context.Context, authUID string, encounterID string) (usecasedto.EncounterDetailDTO, error) {
	requester, err := u.userRepo.FindByAuthProviderAndProviderUserID(ctx, firebaseProvider, authUID)
	if err != nil {
		return usecasedto.EncounterDetailDTO{}, err
	}

	encounter, err := u.encounterRepo.FindByID(ctx, encounterID)
	if err != nil {
		return usecasedto.EncounterDetailDTO{}, err
	}

	if encounter.UserID1 != requester.ID && encounter.UserID2 != requester.ID {
		return usecasedto.EncounterDetailDTO{}, domainerrs.NotFound("Encounter was not found")
	}

	otherID := otherUserID(encounter, requester.ID)
	blocked, err := u.blockRepo.ExistsBetween(ctx, requester.ID, otherID)
	if err != nil {
		return usecasedto.EncounterDetailDTO{}, err
	}
	if blocked {
		return usecasedto.EncounterDetailDTO{}, domainerrs.NotFound("Encounter was not found")
	}

	other, err := u.userRepo.FindByID(ctx, otherID)
	if err != nil {
		return usecasedto.EncounterDetailDTO{}, err
	}

	tracksByEncounter, err := u.encounterRepo.ListTracksByEncounterIDs(ctx, []string{encounter.ID})
	if err != nil {
		return usecasedto.EncounterDetailDTO{}, err
	}

	return usecasedto.EncounterDetailDTO{
		ID:         encounter.ID,
		Type:       string(encounter.EncounterType),
		User:       buildEncounterUserDTO(other),
		OccurredAt: encounter.OccurredAt,
		Tracks:     buildEncounterTrackDTOs(tracksByEncounter[encounter.ID]),
	}, nil
}

func otherUserID(encounter entity.Encounter, requesterID string) string {
	if encounter.UserID1 == requesterID {
		return encounter.UserID2
	}
	return encounter.UserID1
}

func buildEncounterUserDTO(user entity.User) usecasedto.EncounterUserDTO {
	displayName := ""
	if user.Name != nil {
		displayName = *user.Name
	}
	return usecasedto.EncounterUserDTO{
		ID:          user.ID,
		DisplayName: displayName,
		AvatarURL:   user.AvatarURL,
	}
}

func buildEncounterTrackDTOs(tracks []entity.TrackInfo) []usecasedto.EncounterTrackDTO {
	if len(tracks) == 0 {
		return []usecasedto.EncounterTrackDTO{}
	}
	result := make([]usecasedto.EncounterTrackDTO, 0, len(tracks))
	for _, track := range tracks {
		result = append(result, usecasedto.EncounterTrackDTO{
			ID:         track.ID,
			Title:      track.Title,
			ArtistName: track.ArtistName,
			ArtworkURL: track.ArtworkURL,
			PreviewURL: nil,
		})
	}
	return result
}

func parseEncounterCursor(raw string) (*repository.EncounterCursor, error) {
	if raw == "" {
		return nil, nil
	}

	decoded, err := base64.RawURLEncoding.DecodeString(raw)
	if err != nil {
		return nil, domainerrs.BadRequest("cursor is invalid")
	}

	var cursor repository.EncounterCursor
	if err := json.Unmarshal(decoded, &cursor); err != nil {
		return nil, domainerrs.BadRequest("cursor is invalid")
	}
	if cursor.ID == "" || cursor.OccurredAt.IsZero() {
		return nil, domainerrs.BadRequest("cursor is invalid")
	}

	return &cursor, nil
}

func encodeEncounterCursor(cursor *repository.EncounterCursor) (string, error) {
	if cursor == nil {
		return "", nil
	}
	payload, err := json.Marshal(cursor)
	if err != nil {
		return "", err
	}
	return base64.RawURLEncoding.EncodeToString(payload), nil
}
