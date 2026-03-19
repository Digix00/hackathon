package usecase

import (
	"context"
	"time"

	"github.com/google/uuid"

	"hackathon/internal/domain/entity"
	domainerrs "hackathon/internal/domain/errs"
	"hackathon/internal/domain/repository"
	"hackathon/internal/domain/vo"
	usecasedto "hackathon/internal/usecase/dto"
)

type EncounterUsecase interface {
	CreateEncounter(ctx context.Context, authUID string, input usecasedto.CreateEncounterInput) (usecasedto.EncounterSummaryDTO, bool, bool, error)
	ListEncounters(ctx context.Context, authUID string, limit int, cursor string) ([]usecasedto.EncounterListItemDTO, *string, bool, error)
	GetEncounterByID(ctx context.Context, authUID string, encounterID string) (usecasedto.EncounterDetailDTO, error)
	MarkEncounterAsRead(ctx context.Context, authUID string, encounterID string) (usecasedto.EncounterReadDTO, error)
}

type encounterUsecase struct {
	userRepo      repository.UserRepository
	bleTokenRepo  repository.BleTokenRepository
	encounterRepo repository.EncounterRepository
	blockRepo     repository.BlockRepository
	clock         Clock
}

type EncounterUsecaseOption func(*encounterUsecase)

func WithEncounterClock(clock Clock) EncounterUsecaseOption {
	return func(u *encounterUsecase) {
		if clock != nil {
			u.clock = clock
		}
	}
}

func NewEncounterUsecase(
	userRepo repository.UserRepository,
	bleTokenRepo repository.BleTokenRepository,
	encounterRepo repository.EncounterRepository,
	blockRepo repository.BlockRepository,
	opts ...EncounterUsecaseOption,
) EncounterUsecase {
	u := &encounterUsecase{
		userRepo:      userRepo,
		bleTokenRepo:  bleTokenRepo,
		encounterRepo: encounterRepo,
		blockRepo:     blockRepo,
		clock:         realClock{},
	}
	for _, opt := range opts {
		opt(u)
	}
	return u
}

func (u *encounterUsecase) CreateEncounter(ctx context.Context, authUID string, input usecasedto.CreateEncounterInput) (usecasedto.EncounterSummaryDTO, bool, bool, error) {
	if input.RSSI < rssiFilterMin {
		return usecasedto.EncounterSummaryDTO{}, false, true, nil
	}
	requester, err := u.userRepo.FindByAuthProviderAndProviderUserID(ctx, firebaseProvider, authUID)
	if err != nil {
		return usecasedto.EncounterSummaryDTO{}, false, false, err
	}

	encounterType, err := parseEncounterType(input.Type)
	if err != nil {
		return usecasedto.EncounterSummaryDTO{}, false, false, err
	}

	now := u.clock.Now().UTC()
	tokenEntity, err := u.resolveTargetBleToken(ctx, input.TargetBleToken, requester.ID, now)
	if err != nil {
		return usecasedto.EncounterSummaryDTO{}, false, false, err
	}

	if err := u.ensureNotBlocked(ctx, requester.ID, tokenEntity.UserID); err != nil {
		return usecasedto.EncounterSummaryDTO{}, false, false, err
	}

	userID1, userID2 := normalizeUserPair(requester.ID, tokenEntity.UserID)

	if existing, found, err := u.encounterRepo.FindRecentByUsersAndType(ctx, userID1, userID2, encounterType, input.OccurredAt, encounterDedupeWindow); err != nil {
		return usecasedto.EncounterSummaryDTO{}, false, false, err
	} else if found {
		summary, err := u.buildEncounterSummary(ctx, existing, requester.ID)
		if err != nil {
			return usecasedto.EncounterSummaryDTO{}, false, false, err
		}
		return summary, false, false, nil
	}

	created, err := u.encounterRepo.CreateWithRateLimit(ctx, entity.Encounter{
		ID:            uuid.NewString(),
		UserID1:       userID1,
		UserID2:       userID2,
		EncounterType: encounterType,
		OccurredAt:    input.OccurredAt,
	}, []string{requester.ID, tokenEntity.UserID}, requester.ID, now, dailyEncounterUserLimit, dailyEncounterPairLimit)
	if err != nil {
		return usecasedto.EncounterSummaryDTO{}, false, false, err
	}

	summary, err := u.buildEncounterSummary(ctx, created, requester.ID)
	if err != nil {
		return usecasedto.EncounterSummaryDTO{}, false, false, err
	}
	return summary, true, false, nil
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

	encounters, nextCursor, hasMore, err := u.encounterRepo.ListByUserIDExcludingBlocked(ctx, requester.ID, limit, parsedCursor)
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

	userMap, err := u.userRepo.FindByIDs(ctx, otherIDs)
	if err != nil {
		return nil, nil, false, err
	}

	for _, enc := range encounters {
		otherID := otherUserID(enc, requester.ID)
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

func (u *encounterUsecase) MarkEncounterAsRead(ctx context.Context, authUID string, encounterID string) (usecasedto.EncounterReadDTO, error) {
	requester, err := u.userRepo.FindByAuthProviderAndProviderUserID(ctx, firebaseProvider, authUID)
	if err != nil {
		return usecasedto.EncounterReadDTO{}, err
	}

	read, err := u.encounterRepo.MarkAsRead(ctx, encounterID, requester.ID)
	if err != nil {
		return usecasedto.EncounterReadDTO{}, err
	}

	return usecasedto.EncounterReadDTO{
		ID:          read.ID,
		EncounterID: read.EncounterID,
		IsRead:      true,
		ReadAt:      read.ReadAt,
	}, nil
}

func parseEncounterType(raw string) (vo.EncounterType, error) {
	encounterType, err := vo.ParseEncounterType(raw)
	if err != nil {
		return "", err
	}
	if encounterType != vo.EncounterTypeBLE {
		return "", domainerrs.BadRequest("type must be ble")
	}
	return encounterType, nil
}

func (u *encounterUsecase) resolveTargetBleToken(ctx context.Context, token string, requesterID string, now time.Time) (entity.BleToken, error) {
	tokenEntity, err := u.bleTokenRepo.FindByToken(ctx, token)
	if err != nil {
		return entity.BleToken{}, err
	}
	if !tokenEntity.IsValid(now) {
		return entity.BleToken{}, domainerrs.NotFound("BLE token has expired")
	}
	if tokenEntity.UserID == requesterID {
		return entity.BleToken{}, domainerrs.BadRequest("target_ble_token must be another user")
	}
	return tokenEntity, nil
}

func (u *encounterUsecase) ensureNotBlocked(ctx context.Context, requesterID string, otherID string) error {
	blocked, err := u.blockRepo.ExistsBetween(ctx, requesterID, otherID)
	if err != nil {
		return err
	}
	if blocked {
		return domainerrs.NotFound("User was not found")
	}
	return nil
}

func normalizeUserPair(userID1 string, userID2 string) (string, string) {
	if userID2 < userID1 {
		return userID2, userID1
	}
	return userID1, userID2
}

func (u *encounterUsecase) buildEncounterSummary(ctx context.Context, encounter entity.Encounter, requesterID string) (usecasedto.EncounterSummaryDTO, error) {
	otherUser, err := u.userRepo.FindByID(ctx, otherUserID(encounter, requesterID))
	if err != nil {
		return usecasedto.EncounterSummaryDTO{}, err
	}
	return usecasedto.EncounterSummaryDTO{
		ID:         encounter.ID,
		Type:       string(encounter.EncounterType),
		User:       buildEncounterUserDTO(otherUser),
		OccurredAt: encounter.OccurredAt,
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
