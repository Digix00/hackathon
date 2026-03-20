package usecase

import (
	"context"
	"errors"
	"strconv"
	"time"

	"github.com/google/uuid"
	"go.uber.org/zap"

	"hackathon/internal/domain/entity"
	domainerrs "hackathon/internal/domain/errs"
	"hackathon/internal/domain/repository"
	"hackathon/internal/domain/vo"
	usecasedto "hackathon/internal/usecase/dto"
)

// UserUsecase はユーザーの CRUD ビジネスロジックを担うインターフェース。
type UserUsecase interface {
	CreateUser(ctx context.Context, authUID string, input usecasedto.CreateUserInput) (usecasedto.UserDTO, error)
	GetMe(ctx context.Context, authUID string) (usecasedto.UserDTO, error)
	GetUserByID(ctx context.Context, requesterAuthUID string, targetUserID string) (usecasedto.PublicUserDTO, error)
	PatchMe(ctx context.Context, authUID string, input usecasedto.UpdateUserInput) (usecasedto.UserDTO, error)
	DeleteMe(ctx context.Context, authUID string) error
}

type userUsecase struct {
	log              *zap.Logger
	userRepo         repository.UserRepository
	userSettingsRepo repository.UserSettingsRepository
	blockRepo        repository.BlockRepository
	encounterRepo    repository.EncounterRepository
	trackRepo        repository.UserCurrentTrackRepository
}

// NewUserUsecase は UserUsecase を生成する。
// Firebase ユーザー削除は Firebase 固有のエラー型が必要なため handler 層で行い、ここでは注入しない。
func NewUserUsecase(
	log *zap.Logger,
	userRepo repository.UserRepository,
	userSettingsRepo repository.UserSettingsRepository,
	blockRepo repository.BlockRepository,
	encounterRepo repository.EncounterRepository,
	trackRepo repository.UserCurrentTrackRepository,
) UserUsecase {
	return &userUsecase{
		log:              log,
		userRepo:         userRepo,
		userSettingsRepo: userSettingsRepo,
		blockRepo:        blockRepo,
		encounterRepo:    encounterRepo,
		trackRepo:        trackRepo,
	}
}

func (u *userUsecase) CreateUser(ctx context.Context, authUID string, input usecasedto.CreateUserInput) (usecasedto.UserDTO, error) {
	// 重複登録を防止する
	_, err := u.userRepo.FindByAuthProviderAndProviderUserID(ctx, firebaseProvider, authUID)
	if err == nil {
		return usecasedto.UserDTO{}, domainerrs.Conflict("User already exists")
	}
	if !errors.Is(err, domainerrs.ErrNotFound) {
		return usecasedto.UserDTO{}, err
	}

	ageVisStr := string(vo.AgeVisibilityHidden)
	if input.AgeVisibility != nil {
		ageVisStr = *input.AgeVisibility
	}
	ageVis, err := vo.ParseAgeVisibility(ageVisStr)
	if err != nil {
		return usecasedto.UserDTO{}, err
	}

	sexStr := string(vo.SexNoAnswer)
	if input.Sex != nil {
		sexStr = *input.Sex
	}
	sex, err := vo.ParseSex(sexStr)
	if err != nil {
		return usecasedto.UserDTO{}, err
	}

	user, err := u.userRepo.Create(ctx, repository.CreateUserParams{
		ID:             uuid.NewString(),
		AuthProvider:   firebaseProvider,
		ProviderUserID: authUID,
		DisplayName:    input.DisplayName,
		Bio:            input.Bio,
		Birthdate:      input.Birthdate,
		AgeVisibility:  ageVis,
		PrefectureID:   input.PrefectureID,
		Sex:            sex,
		AvatarURL:      input.AvatarURL,
		CreateSettings: true,
	})
	if err != nil {
		return usecasedto.UserDTO{}, err
	}

	return entityToUserDTO(user), nil
}

func (u *userUsecase) GetMe(ctx context.Context, authUID string) (usecasedto.UserDTO, error) {
	user, err := u.userRepo.FindByAuthProviderAndProviderUserID(ctx, firebaseProvider, authUID)
	if err != nil {
		return usecasedto.UserDTO{}, err
	}
	return entityToUserDTO(user), nil
}

func (u *userUsecase) GetUserByID(ctx context.Context, requesterAuthUID string, targetUserID string) (usecasedto.PublicUserDTO, error) {
	requester, err := u.userRepo.FindByAuthProviderAndProviderUserID(ctx, firebaseProvider, requesterAuthUID)
	if err != nil {
		return usecasedto.PublicUserDTO{}, err
	}

	blocked, err := u.blockRepo.ExistsBetween(ctx, requester.ID, targetUserID)
	if err != nil {
		return usecasedto.PublicUserDTO{}, err
	}
	if blocked {
		return usecasedto.PublicUserDTO{}, domainerrs.NotFound("User was not found")
	}

	target, err := u.userRepo.FindByID(ctx, targetUserID)
	if err != nil {
		return usecasedto.PublicUserDTO{}, err
	}

	return buildPublicUserDTO(ctx, target, u.userSettingsRepo, u.encounterRepo, u.trackRepo)
}

func (u *userUsecase) PatchMe(ctx context.Context, authUID string, input usecasedto.UpdateUserInput) (usecasedto.UserDTO, error) {
	user, err := u.userRepo.FindByAuthProviderAndProviderUserID(ctx, firebaseProvider, authUID)
	if err != nil {
		return usecasedto.UserDTO{}, err
	}

	var ageVis *vo.AgeVisibility
	if input.AgeVisibility != nil {
		parsed, err := vo.ParseAgeVisibility(*input.AgeVisibility)
		if err != nil {
			return usecasedto.UserDTO{}, err
		}
		ageVis = &parsed
	}
	var sex *vo.Sex
	if input.Sex != nil {
		parsed, err := vo.ParseSex(*input.Sex)
		if err != nil {
			return usecasedto.UserDTO{}, err
		}
		sex = &parsed
	}

	updated, err := u.userRepo.Update(ctx, user.ID, repository.UpdateUserParams{
		DisplayName:   input.DisplayName,
		Bio:           input.Bio,
		BirthdateSet:  input.BirthdateSet,
		Birthdate:     input.Birthdate,
		AgeVisibility: ageVis,
		PrefectureID:  input.PrefectureID,
		Sex:           sex,
		AvatarURLSet:  input.AvatarURLSet,
		AvatarURL:     input.AvatarURL,
	})
	if err != nil {
		return usecasedto.UserDTO{}, err
	}

	return entityToUserDTO(updated), nil
}

func (u *userUsecase) DeleteMe(ctx context.Context, authUID string) error {
	user, err := u.userRepo.FindByAuthProviderAndProviderUserID(ctx, firebaseProvider, authUID)
	if err != nil {
		return err
	}
	return u.userRepo.DeleteWithCleanup(ctx, user.ID)
}

// ─── helpers ──────────────────────────────────────────────────────────────────

func entityToUserDTO(user entity.User) usecasedto.UserDTO {
	var birthdateStr *string
	if user.Birthdate != nil {
		s := user.Birthdate.UTC().Format("2006-01-02")
		birthdateStr = &s
	}

	displayName := ""
	if user.Name != nil {
		displayName = *user.Name
	}

	return usecasedto.UserDTO{
		ID:            user.ID,
		DisplayName:   displayName,
		AvatarURL:     user.AvatarURL,
		Bio:           user.Bio,
		Birthdate:     birthdateStr,
		AgeVisibility: string(user.AgeVisibility),
		PrefectureID:  user.PrefectureID,
		Sex:           string(user.Sex),
		CreatedAt:     user.CreatedAt,
		UpdatedAt:     user.UpdatedAt,
	}
}

// buildPublicUserDTO assembles a PublicUserDTO from a target user entity,
// applying privacy settings and fetching encounter count and shared track.
// This logic is used by GetUserByID.
func buildPublicUserDTO(
	ctx context.Context,
	target entity.User,
	userSettingsRepo repository.UserSettingsRepository,
	encounterRepo repository.EncounterRepository,
	trackRepo repository.UserCurrentTrackRepository,
) (usecasedto.PublicUserDTO, error) {
	profileVisible := true
	trackVisible := true
	settings, settingsErr := userSettingsRepo.FindByUserID(ctx, target.ID)
	if settingsErr == nil {
		profileVisible = settings.ProfileVisible
		trackVisible = settings.TrackVisible
	} else if !errors.Is(settingsErr, domainerrs.ErrNotFound) {
		return usecasedto.PublicUserDTO{}, settingsErr
	}

	encounterCount, err := encounterRepo.CountByUserID(ctx, target.ID)
	if err != nil {
		return usecasedto.PublicUserDTO{}, err
	}

	displayName := ""
	if target.Name != nil {
		displayName = *target.Name
	}

	ageRange := userCalcAgeRange(target.Birthdate, target.AgeVisibility)

	pub := usecasedto.PublicUserDTO{
		ID:             target.ID,
		DisplayName:    displayName,
		AvatarURL:      target.AvatarURL,
		Bio:            target.Bio,
		Birthplace:     target.PrefectureName,
		AgeRange:       ageRange,
		EncounterCount: encounterCount,
		UpdatedAt:      target.UpdatedAt,
	}

	if !profileVisible {
		pub.Bio = nil
		pub.Birthplace = nil
		pub.AgeRange = nil
	}

	if trackVisible {
		track, found, trackErr := trackRepo.FindCurrentByUserID(ctx, target.ID)
		if trackErr != nil {
			return usecasedto.PublicUserDTO{}, trackErr
		}
		if found {
			pub.SharedTrack = &usecasedto.TrackInfoDTO{
				ID:         track.ID,
				Title:      track.Title,
				ArtistName: track.ArtistName,
				ArtworkURL: track.ArtworkURL,
				PreviewURL: track.PreviewURL,
			}
		}
	}

	return pub, nil
}

func userCalcAgeRange(birthdate *time.Time, visibility vo.AgeVisibility) *string {
	if birthdate == nil || visibility == vo.AgeVisibilityHidden {
		return nil
	}

	now := time.Now().UTC()
	age := now.Year() - birthdate.Year()
	if now.Month() < birthdate.Month() || (now.Month() == birthdate.Month() && now.Day() < birthdate.Day()) {
		age--
	}
	if age < 0 {
		return nil
	}

	switch visibility {
	case vo.AgeVisibilityExact:
		v := strconv.Itoa(age)
		return &v
	default:
		decade := (age / 10) * 10
		v := strconv.Itoa(decade) + "s"
		return &v
	}
}
