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
			userIDC = "seed-user-03"

			providerUserIDA = "demo-user-1"
			providerUserIDB = "demo-user-2"
			providerUserIDC = "demo-user-3"

			settingsIDA = "seed-user-settings-01"
			settingsIDB = "seed-user-settings-02"
			settingsIDC = "seed-user-settings-03"

			trackIDA = "seed-track-01"
			trackIDB = "seed-track-02"
			trackIDC = "seed-track-03"

			encounterID      = "seed-encounter-01"
			encounterTrackID = "seed-encounter-track-01"
			encounterIDB     = "seed-encounter-02"

			userTrackIDA = "seed-user-track-01"
			userTrackIDB = "seed-user-track-02"
			userTrackIDC = "seed-user-track-03"

			currentTrackIDA = "seed-user-current-track-01"
			currentTrackIDB = "seed-user-current-track-02"

			playlistIDA = "seed-playlist-01"
			playlistIDB = "seed-playlist-02"

			playlistTrackIDA = "seed-playlist-track-01"
			playlistTrackIDB = "seed-playlist-track-02"
			playlistTrackIDC = "seed-playlist-track-03"

			trackFavoriteIDA = "seed-track-favorite-01"
			playlistFavIDA   = "seed-playlist-favorite-01"

			commentIDA = "seed-comment-01"
			commentIDB = "seed-comment-02"

			notificationIDA = "seed-notification-01"
			notificationIDB = "seed-notification-02"
		)

		nameA := "Aoi"
		nameB := "Ren"
		nameC := "Mio"

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
				if err := tx.Unscoped().
					Where("auth_provider = ? AND provider_user_id = ?", authProvider, providerUserID).
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
		userC, err := ensureDemoUser(userIDC, providerUserIDC, nameC)
		if err != nil {
			return err
		}

		settings := []model.UserSettings{
			{ID: settingsIDA, UserID: userA.ID},
			{ID: settingsIDB, UserID: userB.ID},
			{ID: settingsIDC, UserID: userC.ID},
		}
		if err := tx.Clauses(clause.OnConflict{
			Columns:   []clause.Column{{Name: "user_id"}},
			DoNothing: true,
		}).Create(&settings).Error; err != nil {
			return err
		}

		tracks := []model.Track{
			{
				ID:         trackIDA,
				ExternalID: "demo-track-1",
				Provider:   "spotify",
				Title:      "City Lights",
				ArtistName: "Night Echoes",
			},
			{
				ID:         trackIDB,
				ExternalID: "demo-track-2",
				Provider:   "spotify",
				Title:      "Sunrise Avenue",
				ArtistName: "Harborline",
			},
			{
				ID:         trackIDC,
				ExternalID: "demo-track-3",
				Provider:   "spotify",
				Title:      "Midnight Metro",
				ArtistName: "Loop Sisters",
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
			TargetWhere: clause.Where{
				Exprs: []clause.Expression{
					clause.Expr{SQL: "deleted_at IS NULL"},
				},
			},
			DoNothing: true,
		}).Create(&model.EncounterTrack{
			ID:           encounterTrackID,
			EncounterID:  encounterID,
			TrackID:      trackIDA,
			SourceUserID: userB.ID,
		}).Error; err != nil {
			return err
		}

		locationEncounteredAt := time.Now().UTC().Add(-26 * time.Hour)
		lat := 35.681236
		lng := 139.767125
		if err := tx.Clauses(clause.OnConflict{DoNothing: true}).Create(&model.Encounter{
			ID:            encounterIDB,
			UserID1:       userA.ID,
			UserID2:       userC.ID,
			EncounteredAt: locationEncounteredAt,
			EncounterType: "location",
			Latitude:      &lat,
			Longitude:     &lng,
		}).Error; err != nil {
			return err
		}

		userTracks := []model.UserTrack{
			{ID: userTrackIDA, UserID: userA.ID, TrackID: trackIDA},
			{ID: userTrackIDB, UserID: userA.ID, TrackID: trackIDB},
			{ID: userTrackIDC, UserID: userB.ID, TrackID: trackIDC},
		}
		if err := tx.Clauses(clause.OnConflict{
			Columns: []clause.Column{
				{Name: "user_id"},
				{Name: "track_id"},
			},
			TargetWhere: clause.Where{
				Exprs: []clause.Expression{
					clause.Expr{SQL: "deleted_at IS NULL"},
				},
			},
			DoNothing: true,
		}).Create(&userTracks).Error; err != nil {
			return err
		}

		currentTracks := []model.UserCurrentTrack{
			{ID: currentTrackIDA, UserID: userA.ID, TrackID: trackIDB},
			{ID: currentTrackIDB, UserID: userB.ID, TrackID: trackIDC},
		}
		if err := tx.Clauses(clause.OnConflict{
			Columns:   []clause.Column{{Name: "user_id"}},
			DoNothing: true,
		}).Create(&currentTracks).Error; err != nil {
			return err
		}

		playlistDescA := "朝の通勤向けプレイリスト"
		playlistDescB := "夜に聴きたい曲まとめ"
		playlists := []model.Playlist{
			{ID: playlistIDA, UserID: userA.ID, Name: "Morning Walk", Description: &playlistDescA, IsPublic: true},
			{ID: playlistIDB, UserID: userB.ID, Name: "Night Drive", Description: &playlistDescB, IsPublic: true},
		}
		if err := tx.Clauses(clause.OnConflict{DoNothing: true}).Create(&playlists).Error; err != nil {
			return err
		}

		playlistTracks := []model.PlaylistTrack{
			{ID: playlistTrackIDA, PlaylistID: playlistIDA, TrackID: trackIDA, SortOrder: 1},
			{ID: playlistTrackIDB, PlaylistID: playlistIDA, TrackID: trackIDB, SortOrder: 2},
			{ID: playlistTrackIDC, PlaylistID: playlistIDB, TrackID: trackIDC, SortOrder: 1},
		}
		if err := tx.Clauses(clause.OnConflict{
			Columns: []clause.Column{
				{Name: "playlist_id"},
				{Name: "track_id"},
			},
			TargetWhere: clause.Where{
				Exprs: []clause.Expression{
					clause.Expr{SQL: "deleted_at IS NULL"},
				},
			},
			DoNothing: true,
		}).Create(&playlistTracks).Error; err != nil {
			return err
		}

		trackFavorites := []model.TrackFavorite{
			{ID: trackFavoriteIDA, UserID: userA.ID, TrackID: trackIDC},
		}
		if err := tx.Clauses(clause.OnConflict{
			Columns: []clause.Column{
				{Name: "user_id"},
				{Name: "track_id"},
			},
			TargetWhere: clause.Where{
				Exprs: []clause.Expression{
					clause.Expr{SQL: "deleted_at IS NULL"},
				},
			},
			DoNothing: true,
		}).Create(&trackFavorites).Error; err != nil {
			return err
		}

		playlistFavorites := []model.PlaylistFavorite{
			{ID: playlistFavIDA, UserID: userA.ID, PlaylistID: playlistIDB},
		}
		if err := tx.Clauses(clause.OnConflict{
			Columns: []clause.Column{
				{Name: "user_id"},
				{Name: "playlist_id"},
			},
			TargetWhere: clause.Where{
				Exprs: []clause.Expression{
					clause.Expr{SQL: "deleted_at IS NULL"},
				},
			},
			DoNothing: true,
		}).Create(&playlistFavorites).Error; err != nil {
			return err
		}

		comments := []model.Comment{
			{ID: commentIDA, EncounterID: encounterID, CommenterUserID: userA.ID, Content: "今日はいい音楽だったね！"},
			{ID: commentIDB, EncounterID: encounterID, CommenterUserID: userB.ID, Content: "おすすめありがとう！"},
		}
		if err := tx.Clauses(clause.OnConflict{DoNothing: true}).Create(&comments).Error; err != nil {
			return err
		}

		notifications := []model.OutboxNotification{
			{ID: notificationIDA, UserID: userA.ID, EncounterID: encounterID, Status: "sent"},
			{ID: notificationIDB, UserID: userA.ID, EncounterID: encounterIDB, Status: "sent"},
		}
		if err := tx.Clauses(clause.OnConflict{DoNothing: true}).Create(&notifications).Error; err != nil {
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
