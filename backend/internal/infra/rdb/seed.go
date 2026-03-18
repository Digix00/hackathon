package rdb

import (
	"fmt"
	"time"

	"gorm.io/gorm"
	"gorm.io/gorm/clause"

	"hackathon/internal/infra/rdb/model"
)

// Seed は開発・テスト環境向けに、必須マスタデータおよびデモユーザー/encounter などのデモデータを冪等に投入する。
// 既存レコードがある場合は上書きしない（OnConflict DoNothing）。
func Seed(db *gorm.DB) error {
	if err := seedPrefectures(db); err != nil {
		return fmt.Errorf("rdb.Seed prefectures: %w", err)
	}
	if err := seedDemoData(db); err != nil {
		return fmt.Errorf("rdb.Seed demo data: %w", err)
	}
	return nil
}

func seedPrefectures(db *gorm.DB) error {
	prefectures := []model.Prefecture{
		{ID: "01", Name: "北海道"},
		{ID: "02", Name: "青森県"},
		{ID: "03", Name: "岩手県"},
		{ID: "04", Name: "宮城県"},
		{ID: "05", Name: "秋田県"},
		{ID: "06", Name: "山形県"},
		{ID: "07", Name: "福島県"},
		{ID: "08", Name: "茨城県"},
		{ID: "09", Name: "栃木県"},
		{ID: "10", Name: "群馬県"},
		{ID: "11", Name: "埼玉県"},
		{ID: "12", Name: "千葉県"},
		{ID: "13", Name: "東京都"},
		{ID: "14", Name: "神奈川県"},
		{ID: "15", Name: "新潟県"},
		{ID: "16", Name: "富山県"},
		{ID: "17", Name: "石川県"},
		{ID: "18", Name: "福井県"},
		{ID: "19", Name: "山梨県"},
		{ID: "20", Name: "長野県"},
		{ID: "21", Name: "岐阜県"},
		{ID: "22", Name: "静岡県"},
		{ID: "23", Name: "愛知県"},
		{ID: "24", Name: "三重県"},
		{ID: "25", Name: "滋賀県"},
		{ID: "26", Name: "京都府"},
		{ID: "27", Name: "大阪府"},
		{ID: "28", Name: "兵庫県"},
		{ID: "29", Name: "奈良県"},
		{ID: "30", Name: "和歌山県"},
		{ID: "31", Name: "鳥取県"},
		{ID: "32", Name: "島根県"},
		{ID: "33", Name: "岡山県"},
		{ID: "34", Name: "広島県"},
		{ID: "35", Name: "山口県"},
		{ID: "36", Name: "徳島県"},
		{ID: "37", Name: "香川県"},
		{ID: "38", Name: "愛媛県"},
		{ID: "39", Name: "高知県"},
		{ID: "40", Name: "福岡県"},
		{ID: "41", Name: "佐賀県"},
		{ID: "42", Name: "長崎県"},
		{ID: "43", Name: "熊本県"},
		{ID: "44", Name: "大分県"},
		{ID: "45", Name: "宮崎県"},
		{ID: "46", Name: "鹿児島県"},
		{ID: "47", Name: "沖縄県"},
	}

	return db.Clauses(clause.OnConflict{DoNothing: true}).
		Create(&prefectures).Error
}

func seedDemoData(db *gorm.DB) error {
	return db.Transaction(func(tx *gorm.DB) error {
		const (
			authProvider = "firebase"

			userIDA = "seed-user-01"
			userIDB = "seed-user-02"

			providerUserIDA = "demo-user-1"
			providerUserIDB = "demo-user-2"

			settingsIDA = "seed-user-settings-01"
			settingsIDB = "seed-user-settings-02"

			trackID = "seed-track-01"

			encounterID      = "seed-encounter-01"
			encounterTrackID = "seed-encounter-track-01"
		)

		nameA := "Aoi"
		nameB := "Ren"

		ensureDemoUser := func(userID, providerUserID, name string) (model.User, error) {
			user := model.User{
				ID:             userID,
				AuthProvider:   authProvider,
				ProviderUserID: providerUserID,
				Name:           &name,
			}
			result := tx.Clauses(clause.OnConflict{
				Columns:   []clause.Column{{Name: "auth_provider"}, {Name: "provider_user_id"}},
				DoNothing: true,
			}).Create(&user)
			if result.Error != nil {
				return model.User{}, result.Error
			}
			if result.RowsAffected == 0 {
				if err := tx.Where("auth_provider = ? AND provider_user_id = ?", authProvider, providerUserID).
					First(&user).Error; err != nil {
					return model.User{}, err
				}
			}
			return user, nil
		}

		userA, err := ensureDemoUser(userIDA, providerUserIDA, nameA)
		if err != nil {
			return err
		}
		userB, err := ensureDemoUser(userIDB, providerUserIDB, nameB)
		if err != nil {
			return err
		}

		settings := []model.UserSettings{
			{ID: settingsIDA, UserID: userA.ID},
			{ID: settingsIDB, UserID: userB.ID},
		}
		if err := tx.Clauses(clause.OnConflict{
			Columns:   []clause.Column{{Name: "user_id"}},
			DoNothing: true,
		}).Create(&settings).Error; err != nil {
			return err
		}

		tracks := []model.Track{
			{
				ID:         trackID,
				ExternalID: "demo-track-1",
				Provider:   "spotify",
				Title:      "City Lights",
				ArtistName: "Night Echoes",
			},
		}
		if err := tx.Clauses(clause.OnConflict{
			Columns:   []clause.Column{{Name: "external_id"}, {Name: "provider"}},
			DoNothing: true,
		}).Create(&tracks).Error; err != nil {
			return err
		}

		encounteredAt := time.Now().UTC().Add(-2 * time.Hour)
		if err := tx.Clauses(clause.OnConflict{DoNothing: true}).Create(&model.Encounter{
			ID:            encounterID,
			UserID1:       userA.ID,
			UserID2:       userB.ID,
			EncounteredAt: encounteredAt,
			EncounterType: "ble",
		}).Error; err != nil {
			return err
		}

		if err := tx.Clauses(clause.OnConflict{
			Columns: []clause.Column{
				{Name: "encounter_id"},
				{Name: "track_id"},
				{Name: "source_user_id"},
			},
			DoNothing: true,
		}).Create(&model.EncounterTrack{
			ID:           encounterTrackID,
			EncounterID:  encounterID,
			TrackID:      trackID,
			SourceUserID: userB.ID,
		}).Error; err != nil {
			return err
		}

		// Keep demo data resilient to resets by ensuring a BLE token exists for the demo user.
		validFrom := time.Now().UTC().Add(-10 * time.Minute)
		validTo := time.Now().UTC().Add(24 * time.Hour)
		if err := tx.Clauses(clause.OnConflict{
			Columns:   []clause.Column{{Name: "token"}},
			DoNothing: true,
		}).Create(&model.BleToken{
			ID:        "seed-ble-token-01",
			UserID:    userB.ID,
			Token:     "0123456789abcdef",
			ValidFrom: validFrom,
			ValidTo:   validTo,
		}).Error; err != nil {
			return err
		}

		return nil
	})
}
