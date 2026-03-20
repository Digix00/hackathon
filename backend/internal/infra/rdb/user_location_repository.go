package rdb

import (
	"context"
	"time"

	"go.uber.org/zap"
	"gorm.io/gorm"
	"gorm.io/gorm/clause"

	"hackathon/internal/domain/repository"
	"hackathon/internal/infra/rdb/model"
)

type userLocationRepository struct {
	log *zap.Logger
	db  *gorm.DB
}

func NewUserLocationRepository(log *zap.Logger, db *gorm.DB) repository.UserLocationRepository {
	return &userLocationRepository{log: log, db: db}
}

func (r *userLocationRepository) Upsert(ctx context.Context, id, userID string, lat, lng float64) error {
	now := time.Now().UTC()
	record := model.UserLocation{
		ID:        id,
		UserID:    userID,
		Latitude:  lat,
		Longitude: lng,
		UpdatedAt: now,
	}
	return r.db.WithContext(ctx).
		Clauses(clause.OnConflict{
			Columns: []clause.Column{{Name: "user_id"}},
			DoUpdates: clause.Assignments(map[string]any{
				"latitude":   lat,
				"longitude":  lng,
				"updated_at": now,
			}),
		}).
		Create(&record).Error
}

func (r *userLocationRepository) FindRecentlyActive(ctx context.Context, requesterID string, since time.Time) ([]repository.NearbyUserInfo, error) {
	type row struct {
		UserID            string
		Latitude          float64
		Longitude         float64
		DetectionDistance int
	}

	var rows []row
	err := r.db.WithContext(ctx).
		Table("user_locations").
		Select("user_locations.user_id, user_locations.latitude, user_locations.longitude, COALESCE(user_settings.detection_distance, 50) AS detection_distance").
		Joins("LEFT JOIN user_settings ON user_settings.user_id = user_locations.user_id").
		Where("user_locations.user_id != ? AND user_locations.updated_at >= ? AND COALESCE(user_settings.location_enabled, true) = true", requesterID, since).
		Scan(&rows).Error
	if err != nil {
		return nil, err
	}

	result := make([]repository.NearbyUserInfo, 0, len(rows))
	for _, r := range rows {
		result = append(result, repository.NearbyUserInfo{
			UserID:            r.UserID,
			Latitude:          r.Latitude,
			Longitude:         r.Longitude,
			DetectionDistance: r.DetectionDistance,
		})
	}
	return result, nil
}
