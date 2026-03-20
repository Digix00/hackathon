package usecase

import (
	"context"
	"errors"
	"math"

	"github.com/google/uuid"
	"go.uber.org/zap"

	"hackathon/internal/domain/entity"
	domainerrs "hackathon/internal/domain/errs"
	"hackathon/internal/domain/repository"
	"hackathon/internal/domain/vo"
	usecasedto "hackathon/internal/usecase/dto"
)

type LocationUsecase interface {
	PostLocation(ctx context.Context, authUID string, input usecasedto.PostLocationInput) (usecasedto.LocationResultDTO, error)
}

type locationUsecase struct {
	log           *zap.Logger
	userRepo      repository.UserRepository
	settingsRepo  repository.UserSettingsRepository
	locationRepo  repository.UserLocationRepository
	encounterRepo repository.EncounterRepository
	blockRepo     repository.BlockRepository
	clock         Clock
}

type LocationUsecaseOption func(*locationUsecase)

func WithLocationClock(clock Clock) LocationUsecaseOption {
	return func(u *locationUsecase) {
		if clock != nil {
			u.clock = clock
		}
	}
}

func NewLocationUsecase(
	log *zap.Logger,
	userRepo repository.UserRepository,
	settingsRepo repository.UserSettingsRepository,
	locationRepo repository.UserLocationRepository,
	encounterRepo repository.EncounterRepository,
	blockRepo repository.BlockRepository,
	opts ...LocationUsecaseOption,
) LocationUsecase {
	u := &locationUsecase{
		log:           log,
		userRepo:      userRepo,
		settingsRepo:  settingsRepo,
		locationRepo:  locationRepo,
		encounterRepo: encounterRepo,
		blockRepo:     blockRepo,
		clock:         realClock{},
	}
	for _, opt := range opts {
		opt(u)
	}
	return u
}

func (u *locationUsecase) PostLocation(ctx context.Context, authUID string, input usecasedto.PostLocationInput) (usecasedto.LocationResultDTO, error) {
	requester, err := u.userRepo.FindByAuthProviderAndProviderUserID(ctx, firebaseProvider, authUID)
	if err != nil {
		return usecasedto.LocationResultDTO{}, err
	}

	// リクエスタの設定を取得（未設定の場合はデフォルト値を使用）
	requesterDistance := 50
	locationEnabled := true
	settings, err := u.settingsRepo.FindByUserID(ctx, requester.ID)
	if err != nil && !errors.Is(err, domainerrs.ErrNotFound) {
		return usecasedto.LocationResultDTO{}, err
	}
	if err == nil {
		requesterDistance = settings.DetectionDistance
		locationEnabled = settings.LocationEnabled
	}

	// リクエスタが location_enabled = false の場合はエンカウント判定をスキップ
	if !locationEnabled {
		return usecasedto.LocationResultDTO{Encounters: []usecasedto.EncounterSummaryDTO{}}, nil
	}

	now := u.clock.Now().UTC()

	// リクエスタの位置情報を更新
	if err := u.locationRepo.Upsert(ctx, uuid.NewString(), requester.ID, input.Lat, input.Lng); err != nil {
		return usecasedto.LocationResultDTO{}, err
	}

	// 最近位置を更新した他ユーザーを取得
	since := now.Add(-encounterDedupeWindow)
	candidates, err := u.locationRepo.FindRecentlyActive(ctx, requester.ID, since)
	if err != nil {
		return usecasedto.LocationResultDTO{}, err
	}

	var encounters []usecasedto.EncounterSummaryDTO

	for _, candidate := range candidates {
		// 判定距離 = 双方の detection_distance の小さい方
		threshold := requesterDistance
		if candidate.DetectionDistance < threshold {
			threshold = candidate.DetectionDistance
		}

		// Haversine 距離がしきい値を超える場合はスキップ
		dist := haversineMeters(input.Lat, input.Lng, candidate.Latitude, candidate.Longitude)
		if dist > float64(threshold) {
			continue
		}

		// ブロック関係にある場合はスキップ
		blocked, err := u.blockRepo.ExistsBetween(ctx, requester.ID, candidate.UserID)
		if err != nil {
			return usecasedto.LocationResultDTO{}, err
		}
		if blocked {
			continue
		}

		userID1, userID2 := normalizeUserPair(requester.ID, candidate.UserID)

		// 5 分以内の重複エンカウントはスキップ
		_, found, err := u.encounterRepo.FindRecentByUsersAndType(ctx, userID1, userID2, vo.EncounterTypeLocation, input.RecordedAt, encounterDedupeWindow)
		if err != nil {
			return usecasedto.LocationResultDTO{}, err
		}
		if found {
			continue
		}

		// エンカウントを作成（レート制限を超えた場合はスキップ）
		created, err := u.encounterRepo.CreateWithRateLimit(ctx, entity.Encounter{
			ID:            uuid.NewString(),
			UserID1:       userID1,
			UserID2:       userID2,
			EncounterType: vo.EncounterTypeLocation,
			OccurredAt:    input.RecordedAt,
			Latitude:      &input.Lat,
			Longitude:     &input.Lng,
		}, []string{requester.ID, candidate.UserID}, requester.ID, now, dailyEncounterUserLimit, dailyEncounterPairLimit)
		if err != nil {
			var domainErr *domainerrs.DomainError
			if errors.As(err, &domainErr) {
				if domainErr.Code == domainerrs.CodeConflict || domainErr.Code == domainerrs.CodeTooMany {
					continue
				}
			}
			return usecasedto.LocationResultDTO{}, err
		}

		// 相手ユーザー情報を取得
		other, err := u.userRepo.FindByID(ctx, candidate.UserID)
		if err != nil {
			return usecasedto.LocationResultDTO{}, err
		}

		encounters = append(encounters, usecasedto.EncounterSummaryDTO{
			ID:         created.ID,
			Type:       string(created.EncounterType),
			User:       buildEncounterUserDTO(other),
			OccurredAt: created.OccurredAt,
		})
	}

	if encounters == nil {
		encounters = []usecasedto.EncounterSummaryDTO{}
	}

	return usecasedto.LocationResultDTO{
		EncounterCount: len(encounters),
		Encounters:     encounters,
	}, nil
}

// haversineMeters は 2 点間の距離をメートル単位で返す（Haversine 公式）。
func haversineMeters(lat1, lng1, lat2, lng2 float64) float64 {
	const earthRadiusM = 6371000.0
	dLat := (lat2 - lat1) * math.Pi / 180.0
	dLng := (lng2 - lng1) * math.Pi / 180.0
	a := math.Sin(dLat/2)*math.Sin(dLat/2) +
		math.Cos(lat1*math.Pi/180.0)*math.Cos(lat2*math.Pi/180.0)*
			math.Sin(dLng/2)*math.Sin(dLng/2)
	c := 2 * math.Atan2(math.Sqrt(a), math.Sqrt(1-a))
	return earthRadiusM * c
}
