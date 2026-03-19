package usecase

import (
	"context"
	"errors"
	"testing"
	"time"

	"hackathon/internal/domain/entity"
	domainerrs "hackathon/internal/domain/errs"
	"hackathon/internal/domain/repository"
	"hackathon/internal/domain/vo"
	usecasedto "hackathon/internal/usecase/dto"
)

// ─── インメモリ stub ───────────────────────────────────────────────────────────

type stubUserRepo struct {
	byAuthUID map[string]entity.User
	byID      map[string]entity.User
}

func (r *stubUserRepo) FindByAuthProviderAndProviderUserID(_ context.Context, _, uid string) (entity.User, error) {
	u, ok := r.byAuthUID[uid]
	if !ok {
		return entity.User{}, domainerrs.NotFound("not found")
	}
	return u, nil
}
func (r *stubUserRepo) FindByID(_ context.Context, id string) (entity.User, error) {
	u, ok := r.byID[id]
	if !ok {
		return entity.User{}, domainerrs.NotFound("not found")
	}
	return u, nil
}
func (r *stubUserRepo) FindByIDs(_ context.Context, ids []string) (map[string]entity.User, error) {
	result := make(map[string]entity.User, len(ids))
	for _, id := range ids {
		if u, ok := r.byID[id]; ok {
			result[id] = u
		}
	}
	return result, nil
}
func (r *stubUserRepo) Create(_ context.Context, _ repository.CreateUserParams) (entity.User, error) {
	return entity.User{}, nil
}
func (r *stubUserRepo) Update(_ context.Context, _ string, _ repository.UpdateUserParams) (entity.User, error) {
	return entity.User{}, nil
}
func (r *stubUserRepo) DeleteWithCleanup(_ context.Context, _ string) error { return nil }

type stubUserSettingsRepo struct {
	data map[string]entity.UserSettings
}

func (r *stubUserSettingsRepo) FindByUserID(_ context.Context, userID string) (entity.UserSettings, error) {
	s, ok := r.data[userID]
	if !ok {
		return entity.UserSettings{}, domainerrs.NotFound("not found")
	}
	return s, nil
}
func (r *stubUserSettingsRepo) Create(_ context.Context, _ *entity.UserSettings) error { return nil }
func (r *stubUserSettingsRepo) Update(_ context.Context, _ *entity.UserSettings) error { return nil }

type stubBlockRepo struct {
	blocked bool
}

func (r *stubBlockRepo) Create(_ context.Context, _ entity.Block) error { return nil }
func (r *stubBlockRepo) Delete(_ context.Context, _, _ string) error    { return nil }
func (r *stubBlockRepo) ExistsByBlockerAndBlocked(_ context.Context, _, _ string) (bool, error) {
	return r.blocked, nil
}
func (r *stubBlockRepo) ExistsBetween(_ context.Context, _, _ string) (bool, error) {
	return r.blocked, nil
}
func (r *stubBlockRepo) ListBlockedUserIDs(_ context.Context, _ string, _ []string) (map[string]bool, error) {
	if r.blocked {
		return map[string]bool{"blocked": true}, nil
	}
	return map[string]bool{}, nil
}

type stubEncounterRepo struct {
	count int64
}

func (r *stubEncounterRepo) CountByUserID(_ context.Context, _ string) (int64, error) {
	return r.count, nil
}

func (r *stubEncounterRepo) FindRecentByUsersAndType(_ context.Context, _, _ string, _ vo.EncounterType, _ time.Time, _ time.Duration) (entity.Encounter, bool, error) {
	return entity.Encounter{}, false, nil
}

func (r *stubEncounterRepo) Create(_ context.Context, encounter entity.Encounter) (entity.Encounter, error) {
	return encounter, nil
}

func (r *stubEncounterRepo) CreateTracksFromCurrent(_ context.Context, _ string, _ []string) error {
	return nil
}

func (r *stubEncounterRepo) ListByUserID(_ context.Context, _ string, _ int, _ *repository.EncounterCursor) ([]entity.Encounter, *repository.EncounterCursor, bool, error) {
	return []entity.Encounter{}, nil, false, nil
}

func (r *stubEncounterRepo) ListByUserIDExcludingBlocked(_ context.Context, _ string, _ int, _ *repository.EncounterCursor) ([]entity.Encounter, *repository.EncounterCursor, bool, error) {
	return []entity.Encounter{}, nil, false, nil
}

func (r *stubEncounterRepo) FindByID(_ context.Context, _ string) (entity.Encounter, error) {
	return entity.Encounter{}, domainerrs.NotFound("not found")
}

func (r *stubEncounterRepo) ListTracksByEncounterIDs(_ context.Context, _ []string) (map[string][]entity.TrackInfo, error) {
	return map[string][]entity.TrackInfo{}, nil
}

func (r *stubEncounterRepo) GetReadStatusByEncounterIDs(_ context.Context, _ string, _ []string) (map[string]bool, error) {
	return map[string]bool{}, nil
}

func (r *stubEncounterRepo) ExistsByUsersAndTypeOnDate(_ context.Context, _, _ string, _ vo.EncounterType, _ time.Time) (bool, error) {
	return false, nil
}

func (r *stubEncounterRepo) IncrementDailyCountWithLimit(_ context.Context, _ string, _ time.Time, _ int) (int, error) {
	return 1, nil
}

func (r *stubEncounterRepo) CreateWithRateLimit(_ context.Context, encounter entity.Encounter, _ []string, _ string, _ time.Time, _ int, _ int) (entity.Encounter, error) {
	return encounter, nil
}

func (r *stubEncounterRepo) ExistsByIDAndParticipant(_ context.Context, _, _ string) (bool, error) {
	return false, nil
}

type stubTrackRepo struct {
	track entity.TrackInfo
	found bool
}

func (r *stubTrackRepo) FindCurrentByUserID(_ context.Context, _ string) (entity.TrackInfo, bool, error) {
	return r.track, r.found, nil
}

func (r *stubTrackRepo) FindCurrentWithTimestampByUserID(_ context.Context, _ string) (entity.UserCurrentTrack, bool, error) {
	return entity.UserCurrentTrack{}, false, nil
}

func (r *stubTrackRepo) Upsert(_ context.Context, _, _ string) (entity.UserCurrentTrack, bool, error) {
	return entity.UserCurrentTrack{}, false, nil
}

func (r *stubTrackRepo) DeleteByUserID(_ context.Context, _ string) error {
	return nil
}

// ─── userCalcAgeRange ────────────────────────────────────────────────────────

func TestUserCalcAgeRange(t *testing.T) {
	now := time.Now().UTC()

	age25 := now.AddDate(-25, 0, 0)
	age30 := now.AddDate(-30, 0, 0)
	// 誕生日がまだ来ていないケース（今年はまだ誕生日が来ていない）
	notYet := time.Date(now.Year()-20, now.Month(), now.Day()+1, 0, 0, 0, 0, time.UTC)
	if notYet.After(now) {
		// +1日が翌月になる場合の補正
		notYet = time.Date(now.Year()-20, now.Month()+1, 1, 0, 0, 0, 0, time.UTC)
	}

	tests := []struct {
		name       string
		birthdate  *time.Time
		visibility vo.AgeVisibility
		want       *string
	}{
		{
			name:       "birthdate nil → nil",
			birthdate:  nil,
			visibility: vo.AgeVisibilityExact,
			want:       nil,
		},
		{
			name:       "hidden → nil",
			birthdate:  &age25,
			visibility: vo.AgeVisibilityHidden,
			want:       nil,
		},
		{
			name:       "exact: 25歳",
			birthdate:  &age25,
			visibility: vo.AgeVisibilityExact,
			want:       ptr("25"),
		},
		{
			name:       "exact: 30歳",
			birthdate:  &age30,
			visibility: vo.AgeVisibilityExact,
			want:       ptr("30"),
		},
		{
			name:       "by-10: 25歳 → 20s",
			birthdate:  &age25,
			visibility: vo.AgeVisibilityByTen,
			want:       ptr("20s"),
		},
		{
			name:       "by-10: 30歳 → 30s",
			birthdate:  &age30,
			visibility: vo.AgeVisibilityByTen,
			want:       ptr("30s"),
		},
		{
			name:       "誕生日未到来で年齢が1少ない",
			birthdate:  &notYet,
			visibility: vo.AgeVisibilityExact,
			want:       ptr("19"),
		},
	}

	for _, tc := range tests {
		t.Run(tc.name, func(t *testing.T) {
			got := userCalcAgeRange(tc.birthdate, tc.visibility)
			if tc.want == nil {
				if got != nil {
					t.Errorf("want nil, got %q", *got)
				}
				return
			}
			if got == nil {
				t.Errorf("want %q, got nil", *tc.want)
				return
			}
			if *got != *tc.want {
				t.Errorf("want %q, got %q", *tc.want, *got)
			}
		})
	}
}

// ─── GetUserByID ─────────────────────────────────────────────────────────────

func newUserUsecase(
	userRepo repository.UserRepository,
	settingsRepo repository.UserSettingsRepository,
	blockRepo repository.BlockRepository,
	encounterRepo repository.EncounterRepository,
	trackRepo repository.UserCurrentTrackRepository,
) UserUsecase {
	return NewUserUsecase(userRepo, settingsRepo, blockRepo, encounterRepo, trackRepo)
}

func TestGetUserByID_Blocked(t *testing.T) {
	requester := entity.User{ID: "r1"}
	target := entity.User{ID: "t1"}

	uc := newUserUsecase(
		&stubUserRepo{
			byAuthUID: map[string]entity.User{"requester-uid": requester},
			byID:      map[string]entity.User{"t1": target},
		},
		&stubUserSettingsRepo{data: map[string]entity.UserSettings{}},
		&stubBlockRepo{blocked: true},
		&stubEncounterRepo{},
		&stubTrackRepo{},
	)

	_, err := uc.GetUserByID(context.Background(), "requester-uid", "t1")
	if !errors.Is(err, domainerrs.ErrNotFound) {
		t.Errorf("blocked user should return NotFound, got %v", err)
	}
}

func TestGetUserByID_ProfileHidden(t *testing.T) {
	requester := entity.User{ID: "r1"}
	bio := "my bio"
	prefName := "Tokyo"
	age25 := time.Now().UTC().AddDate(-25, 0, 0)
	target := entity.User{
		ID:             "t1",
		Bio:            &bio,
		PrefectureName: &prefName,
		Birthdate:      &age25,
		AgeVisibility:  vo.AgeVisibilityExact,
	}

	uc := newUserUsecase(
		&stubUserRepo{
			byAuthUID: map[string]entity.User{"req-uid": requester},
			byID:      map[string]entity.User{"t1": target},
		},
		&stubUserSettingsRepo{data: map[string]entity.UserSettings{
			"t1": {ProfileVisible: false, TrackVisible: false},
		}},
		&stubBlockRepo{blocked: false},
		&stubEncounterRepo{count: 3},
		&stubTrackRepo{},
	)

	got, err := uc.GetUserByID(context.Background(), "req-uid", "t1")
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	if got.Bio != nil {
		t.Errorf("bio should be hidden, got %q", *got.Bio)
	}
	if got.Birthplace != nil {
		t.Errorf("birthplace should be hidden")
	}
	if got.AgeRange != nil {
		t.Errorf("age_range should be hidden")
	}
	if got.EncounterCount != 3 {
		t.Errorf("encounter_count should be 3, got %d", got.EncounterCount)
	}
}

func TestGetUserByID_TrackVisible(t *testing.T) {
	requester := entity.User{ID: "r1"}
	artworkURL := "https://example.com/art.jpg"
	target := entity.User{ID: "t1"}

	uc := newUserUsecase(
		&stubUserRepo{
			byAuthUID: map[string]entity.User{"req-uid": requester},
			byID:      map[string]entity.User{"t1": target},
		},
		&stubUserSettingsRepo{data: map[string]entity.UserSettings{
			"t1": {ProfileVisible: true, TrackVisible: true},
		}},
		&stubBlockRepo{blocked: false},
		&stubEncounterRepo{},
		&stubTrackRepo{
			found: true,
			track: entity.TrackInfo{ID: "track1", Title: "Song", ArtistName: "Artist", ArtworkURL: &artworkURL},
		},
	)

	got, err := uc.GetUserByID(context.Background(), "req-uid", "t1")
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	if got.SharedTrack == nil {
		t.Fatal("shared_track should be populated")
	}
	if got.SharedTrack.ID != "track1" {
		t.Errorf("want track1, got %s", got.SharedTrack.ID)
	}
}

func TestGetUserByID_TrackHidden(t *testing.T) {
	requester := entity.User{ID: "r1"}
	target := entity.User{ID: "t1"}

	uc := newUserUsecase(
		&stubUserRepo{
			byAuthUID: map[string]entity.User{"req-uid": requester},
			byID:      map[string]entity.User{"t1": target},
		},
		&stubUserSettingsRepo{data: map[string]entity.UserSettings{
			"t1": {ProfileVisible: true, TrackVisible: false},
		}},
		&stubBlockRepo{blocked: false},
		&stubEncounterRepo{},
		&stubTrackRepo{found: true, track: entity.TrackInfo{ID: "track1"}},
	)

	got, err := uc.GetUserByID(context.Background(), "req-uid", "t1")
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	if got.SharedTrack != nil {
		t.Errorf("track should be hidden when TrackVisible=false")
	}
}

func TestGetUserByID_RequesterNotFound(t *testing.T) {
	uc := newUserUsecase(
		&stubUserRepo{byAuthUID: map[string]entity.User{}, byID: map[string]entity.User{}},
		&stubUserSettingsRepo{data: map[string]entity.UserSettings{}},
		&stubBlockRepo{},
		&stubEncounterRepo{},
		&stubTrackRepo{},
	)

	_, err := uc.GetUserByID(context.Background(), "unknown-uid", "t1")
	if !errors.Is(err, domainerrs.ErrNotFound) {
		t.Errorf("unknown requester should return NotFound, got %v", err)
	}
}

func TestCreateUser_DefaultAgeVisibilityAndSex(t *testing.T) {
	repo := &stubUserRepo{
		byAuthUID: map[string]entity.User{},
		byID:      map[string]entity.User{},
	}
	// Create を上書きして渡ったパラメータを記録
	var capturedParams repository.CreateUserParams
	captureRepo := &captureCreateUserRepo{
		stubUserRepo:   repo,
		capturedParams: &capturedParams,
	}

	uc := newUserUsecase(
		captureRepo,
		&stubUserSettingsRepo{data: map[string]entity.UserSettings{}},
		&stubBlockRepo{},
		&stubEncounterRepo{},
		&stubTrackRepo{},
	)

	_, _ = uc.CreateUser(context.Background(), "uid1", usecasedto.CreateUserInput{
		DisplayName:   "Taro",
		AgeVisibility: nil, // 未指定 → hidden がデフォルト
		Sex:           nil, // 未指定 → no-answer がデフォルト
	})

	if capturedParams.AgeVisibility != vo.AgeVisibilityHidden {
		t.Errorf("want AgeVisibilityHidden, got %q", capturedParams.AgeVisibility)
	}
	if capturedParams.Sex != vo.SexNoAnswer {
		t.Errorf("want SexNoAnswer, got %q", capturedParams.Sex)
	}
}

// captureCreateUserRepo は Create 時のパラメータを記録するテスト用 stub
type captureCreateUserRepo struct {
	*stubUserRepo
	capturedParams *repository.CreateUserParams
}

func (r *captureCreateUserRepo) Create(_ context.Context, params repository.CreateUserParams) (entity.User, error) {
	*r.capturedParams = params
	u := entity.User{ID: params.ID, AgeVisibility: params.AgeVisibility, Sex: params.Sex}
	return u, nil
}

// ─── helpers ─────────────────────────────────────────────────────────────────

func ptr(s string) *string { return &s }
