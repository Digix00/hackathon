package rdb

import (
	"context"
	"errors"
	"time"

	"github.com/google/uuid"
	"gorm.io/gorm"
	"gorm.io/gorm/clause"

	"hackathon/internal/domain/entity"
	domainerrs "hackathon/internal/domain/errs"
	"hackathon/internal/domain/repository"
	"hackathon/internal/domain/vo"
	"hackathon/internal/infra/rdb/model"
)

type encounterRepository struct {
	db *gorm.DB
}

func NewEncounterRepository(db *gorm.DB) repository.EncounterRepository {
	return &encounterRepository{db: db}
}

func (r *encounterRepository) CountByUserID(ctx context.Context, userID string) (int64, error) {
	var count int64
	err := r.db.WithContext(ctx).
		Model(&model.Encounter{}).
		Where("user_id1 = ? OR user_id2 = ?", userID, userID).
		Count(&count).Error
	if err != nil {
		return 0, err
	}
	return count, nil
}

func (r *encounterRepository) FindRecentByUsersAndType(
	ctx context.Context,
	userID1 string,
	userID2 string,
	encounterType vo.EncounterType,
	occurredAt time.Time,
	window time.Duration,
) (entity.Encounter, bool, error) {
	var found model.Encounter
	start := occurredAt.Add(-window)
	end := occurredAt.Add(window)
	err := r.db.WithContext(ctx).
		Where("user_id1 = ? AND user_id2 = ? AND encounter_type = ? AND encountered_at BETWEEN ? AND ?",
			userID1, userID2, string(encounterType), start, end).
		Order("encountered_at desc").
		First(&found).Error
	if errors.Is(err, gorm.ErrRecordNotFound) {
		return entity.Encounter{}, false, nil
	}
	if err != nil {
		return entity.Encounter{}, false, err
	}
	return modelToEntityEncounter(found), true, nil
}

func (r *encounterRepository) Create(ctx context.Context, encounter entity.Encounter) (entity.Encounter, error) {
	created := model.Encounter{
		ID:            encounter.ID,
		UserID1:       encounter.UserID1,
		UserID2:       encounter.UserID2,
		EncounteredAt: encounter.OccurredAt,
		EncounterType: string(encounter.EncounterType),
		Latitude:      encounter.Latitude,
		Longitude:     encounter.Longitude,
	}
	if err := r.db.WithContext(ctx).Create(&created).Error; err != nil {
		return entity.Encounter{}, err
	}
	return modelToEntityEncounter(created), nil
}

func (r *encounterRepository) CreateTracksFromCurrent(ctx context.Context, encounterID string, userIDs []string) error {
	if len(userIDs) == 0 {
		return nil
	}

	var currents []model.UserCurrentTrack
	if err := r.db.WithContext(ctx).
		Preload("Track").
		Where("user_id IN ?", userIDs).
		Find(&currents).Error; err != nil {
		return err
	}

	tracks := make([]model.EncounterTrack, 0, len(currents))
	for _, current := range currents {
		if current.Track == nil || current.Track.ID == "" {
			continue
		}
		tracks = append(tracks, model.EncounterTrack{
			ID:           uuid.NewString(),
			EncounterID:  encounterID,
			TrackID:      current.Track.ID,
			SourceUserID: current.UserID,
		})
	}
	if len(tracks) == 0 {
		return nil
	}

	return r.db.WithContext(ctx).
		Clauses(clause.OnConflict{DoNothing: true}).
		Create(&tracks).Error
}

func (r *encounterRepository) ListByUserID(ctx context.Context, userID string, limit int, cursor *repository.EncounterCursor) ([]entity.Encounter, *repository.EncounterCursor, bool, error) {
	if limit <= 0 {
		return []entity.Encounter{}, nil, false, nil
	}

	query := r.db.WithContext(ctx).Model(&model.Encounter{}).
		Where("user_id1 = ? OR user_id2 = ?", userID, userID)

	if cursor != nil {
		query = query.Where(
			"(encountered_at < ?) OR (encountered_at = ? AND id < ?)",
			cursor.OccurredAt, cursor.OccurredAt, cursor.ID,
		)
	}

	var records []model.Encounter
	if err := query.
		Order("encountered_at desc").
		Order("id desc").
		Limit(limit + 1).
		Find(&records).Error; err != nil {
		return nil, nil, false, err
	}

	hasMore := false
	var nextCursor *repository.EncounterCursor
	if len(records) > limit {
		hasMore = true
		last := records[limit-1]
		nextCursor = &repository.EncounterCursor{
			OccurredAt: last.EncounteredAt,
			ID:         last.ID,
		}
		records = records[:limit]
	}

	encounters := make([]entity.Encounter, 0, len(records))
	for _, rec := range records {
		encounters = append(encounters, modelToEntityEncounter(rec))
	}
	return encounters, nextCursor, hasMore, nil
}

func (r *encounterRepository) FindByID(ctx context.Context, encounterID string) (entity.Encounter, error) {
	var encounter model.Encounter
	err := r.db.WithContext(ctx).
		First(&encounter, "id = ?", encounterID).Error
	if errors.Is(err, gorm.ErrRecordNotFound) {
		return entity.Encounter{}, domainerrs.NotFound("Encounter was not found")
	}
	if err != nil {
		return entity.Encounter{}, err
	}
	return modelToEntityEncounter(encounter), nil
}

func (r *encounterRepository) ListTracksByEncounterIDs(ctx context.Context, encounterIDs []string) (map[string][]entity.TrackInfo, error) {
	if len(encounterIDs) == 0 {
		return map[string][]entity.TrackInfo{}, nil
	}

	var records []model.EncounterTrack
	if err := r.db.WithContext(ctx).
		Preload("Track").
		Where("encounter_id IN ?", encounterIDs).
		Order("created_at asc").
		Find(&records).Error; err != nil {
		return nil, err
	}

	result := make(map[string][]entity.TrackInfo, len(encounterIDs))
	for _, rec := range records {
		if rec.Track == nil {
			continue
		}
		info := trackModelToInfo(rec.Track)
		result[rec.EncounterID] = append(result[rec.EncounterID], info)
	}
	return result, nil
}

func (r *encounterRepository) GetReadStatusByEncounterIDs(ctx context.Context, userID string, encounterIDs []string) (map[string]bool, error) {
	if len(encounterIDs) == 0 {
		return map[string]bool{}, nil
	}

	var reads []model.EncounterRead
	if err := r.db.WithContext(ctx).
		Where("user_id = ? AND encounter_id IN ?", userID, encounterIDs).
		Find(&reads).Error; err != nil {
		return nil, err
	}

	result := make(map[string]bool, len(reads))
	for _, read := range reads {
		result[read.EncounterID] = true
	}
	return result, nil
}

func (r *encounterRepository) ExistsByUsersAndTypeOnDate(ctx context.Context, userID1, userID2 string, encounterType vo.EncounterType, date time.Time) (bool, error) {
	start := time.Date(date.Year(), date.Month(), date.Day(), 0, 0, 0, 0, time.UTC)
	end := start.Add(24 * time.Hour)

	var count int64
	err := r.db.WithContext(ctx).
		Model(&model.Encounter{}).
		Where("user_id1 = ? AND user_id2 = ? AND encounter_type = ? AND created_at >= ? AND created_at < ?",
			userID1, userID2, string(encounterType), start, end).
		Count(&count).Error
	if err != nil {
		return false, err
	}
	return count > 0, nil
}

func (r *encounterRepository) IncrementDailyCountWithLimit(ctx context.Context, userID string, date time.Time, limit int) (int, error) {
	start := time.Date(date.Year(), date.Month(), date.Day(), 0, 0, 0, 0, time.UTC)

	var count int
	err := r.db.WithContext(ctx).Transaction(func(tx *gorm.DB) error {
		stmt := `
			INSERT INTO daily_encounter_counts (id, user_id, date, count, created_at, updated_at)
			VALUES (?, ?, ?, 1, NOW(), NOW())
			ON CONFLICT (user_id, date)
			DO UPDATE SET count = daily_encounter_counts.count + 1, updated_at = NOW()
			RETURNING count
		`
		if err := tx.Raw(stmt, uuid.NewString(), userID, start).Scan(&count).Error; err != nil {
			return err
		}
		if limit > 0 && count > limit {
			return domainerrs.TooManyRequests("daily encounter limit exceeded")
		}
		return nil
	})
	if err != nil {
		return 0, err
	}
	return count, nil
}

func (r *encounterRepository) CreateWithRateLimit(ctx context.Context, encounter entity.Encounter, userIDsForTracks []string, dailyLimitUserID string, date time.Time, limit int) (entity.Encounter, error) {
	start := time.Date(date.Year(), date.Month(), date.Day(), 0, 0, 0, 0, time.UTC)

	var created model.Encounter
	err := r.db.WithContext(ctx).Transaction(func(tx *gorm.DB) error {
		if limit > 0 {
			var count int
			stmt := `
				INSERT INTO daily_encounter_counts (id, user_id, date, count, created_at, updated_at)
				VALUES (?, ?, ?, 1, NOW(), NOW())
				ON CONFLICT (user_id, date)
				DO UPDATE SET count = daily_encounter_counts.count + 1, updated_at = NOW()
				RETURNING count
			`
			if err := tx.Raw(stmt, uuid.NewString(), dailyLimitUserID, start).Scan(&count).Error; err != nil {
				return err
			}
			if count > limit {
				return domainerrs.TooManyRequests("daily encounter limit exceeded")
			}
		}

		created = model.Encounter{
			ID:            encounter.ID,
			UserID1:       encounter.UserID1,
			UserID2:       encounter.UserID2,
			EncounteredAt: encounter.OccurredAt,
			EncounterType: string(encounter.EncounterType),
			Latitude:      encounter.Latitude,
			Longitude:     encounter.Longitude,
		}
		if err := tx.Create(&created).Error; err != nil {
			return err
		}

		if len(userIDsForTracks) > 0 {
			var currents []model.UserCurrentTrack
			if err := tx.
				Preload("Track").
				Where("user_id IN ?", userIDsForTracks).
				Find(&currents).Error; err != nil {
				return err
			}

			tracks := make([]model.EncounterTrack, 0, len(currents))
			for _, current := range currents {
				if current.Track == nil || current.Track.ID == "" {
					continue
				}
				tracks = append(tracks, model.EncounterTrack{
					ID:           uuid.NewString(),
					EncounterID:  created.ID,
					TrackID:      current.Track.ID,
					SourceUserID: current.UserID,
				})
			}
			if len(tracks) > 0 {
				if err := tx.Clauses(clause.OnConflict{DoNothing: true}).Create(&tracks).Error; err != nil {
					return err
				}
			}
		}

		return nil
	})
	if err != nil {
		return entity.Encounter{}, err
	}

	return modelToEntityEncounter(created), nil
}

func modelToEntityEncounter(encounter model.Encounter) entity.Encounter {
	return entity.Encounter{
		ID:            encounter.ID,
		UserID1:       encounter.UserID1,
		UserID2:       encounter.UserID2,
		EncounterType: vo.EncounterType(encounter.EncounterType),
		OccurredAt:    encounter.EncounteredAt,
		Latitude:      encounter.Latitude,
		Longitude:     encounter.Longitude,
		CreatedAt:     encounter.CreatedAt,
	}
}

func trackModelToInfo(track *model.Track) entity.TrackInfo {
	if track == nil {
		return entity.TrackInfo{}
	}
	trackID := track.ID
	if track.Provider != "" && track.ExternalID != "" {
		trackID = track.Provider + ":track:" + track.ExternalID
	}
	return entity.TrackInfo{
		ID:         trackID,
		Title:      track.Title,
		ArtistName: track.ArtistName,
		ArtworkURL: track.AlbumArtURL,
	}
}
