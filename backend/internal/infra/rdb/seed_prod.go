package rdb

import (
	"fmt"
	"time"

	"gorm.io/gorm"
	"gorm.io/gorm/clause"

	"hackathon/internal/infra/rdb/model"
)

// SeedProd は本番環境の特定ユーザー（targetUserID）に対してデモ用データを投入する。
// 既存の Seed() には手を加えず、本番専用として独立させている。
// 既存レコードがある場合は上書きしない（OnConflict DoNothing）。
// targetUserID は DB に存在するユーザーの ID を指定すること。
func SeedProd(db *gorm.DB, targetUserID string) error {
	var target model.User
	if err := db.Where("id = ?", targetUserID).First(&target).Error; err != nil {
		return fmt.Errorf("rdb.SeedProd: target user not found (id=%s): %w", targetUserID, err)
	}
	return seedProdData(db, target)
}

// ID プレフィックス。ローカル seed と衝突しないよう prod-seed- を使う。
const (
	prodSeedCounterpartIDA = "prod-seed-user-01"
	prodSeedCounterpartIDB = "prod-seed-user-02"
	prodSeedCounterpartIDC = "prod-seed-user-03"

	prodSeedSettingsA = "prod-seed-settings-01"
	prodSeedSettingsB = "prod-seed-settings-02"
	prodSeedSettingsC = "prod-seed-settings-03"

	prodSeedTrackIDA = "prod-seed-track-01"
	prodSeedTrackIDB = "prod-seed-track-02"
	prodSeedTrackIDC = "prod-seed-track-03"
	prodSeedTrackIDD = "prod-seed-track-04"
	prodSeedTrackIDE = "prod-seed-track-05"

	prodSeedEncounterIDA = "prod-seed-encounter-01"
	prodSeedEncounterIDB = "prod-seed-encounter-02"
	prodSeedEncounterIDC = "prod-seed-encounter-03"

	prodSeedEncounterTrackIDA = "prod-seed-enc-track-01"
	prodSeedEncounterTrackIDB = "prod-seed-enc-track-02"
	prodSeedEncounterTrackIDC = "prod-seed-enc-track-03"
	prodSeedEncounterTrackIDD = "prod-seed-enc-track-04"

	prodSeedUserTrackIDA = "prod-seed-user-track-01"
	prodSeedUserTrackIDB = "prod-seed-user-track-02"
	prodSeedUserTrackIDC = "prod-seed-user-track-03"
	prodSeedUserTrackIDD = "prod-seed-user-track-04"
	prodSeedUserTrackIDE = "prod-seed-user-track-05"

	prodSeedCurrentTrackID = "prod-seed-current-track-01"

	prodSeedPlaylistIDA = "prod-seed-playlist-01"
	prodSeedPlaylistIDB = "prod-seed-playlist-02"

	prodSeedPlaylistTrackIDA = "prod-seed-pl-track-01"
	prodSeedPlaylistTrackIDB = "prod-seed-pl-track-02"
	prodSeedPlaylistTrackIDC = "prod-seed-pl-track-03"
	prodSeedPlaylistTrackIDD = "prod-seed-pl-track-04"
	prodSeedPlaylistTrackIDE = "prod-seed-pl-track-05"

	prodSeedTrackFavIDA = "prod-seed-track-fav-01"
	prodSeedTrackFavIDB = "prod-seed-track-fav-02"

	prodSeedPlaylistFavIDA = "prod-seed-pl-fav-01"

	prodSeedCommentIDA = "prod-seed-comment-01"
	prodSeedCommentIDB = "prod-seed-comment-02"
	prodSeedCommentIDC = "prod-seed-comment-03"
	prodSeedCommentIDD = "prod-seed-comment-04"

	prodSeedNotificationIDA = "prod-seed-notif-01"
	prodSeedNotificationIDB = "prod-seed-notif-02"
	prodSeedNotificationIDC = "prod-seed-notif-03"

	prodSeedMusicConnID = "prod-seed-music-conn-01"

	prodSeedLyricChainIDA = "prod-seed-lyric-chain-01"
	prodSeedLyricChainIDB = "prod-seed-lyric-chain-02"

	prodSeedLyricEntryIDA = "prod-seed-lyric-entry-01"
	prodSeedLyricEntryIDB = "prod-seed-lyric-entry-02"
	prodSeedLyricEntryIDC = "prod-seed-lyric-entry-03"
	prodSeedLyricEntryIDD = "prod-seed-lyric-entry-04"

	prodSeedGeneratedSongIDA = "prod-seed-song-01"
	prodSeedGeneratedSongIDB = "prod-seed-song-02"

	prodSeedSongLikeIDA = "prod-seed-song-like-01"

	// クロスエンカウンター（2人の実ユーザー間）用 ID
	prodSeedCrossEncounterID   = "prod-seed-cross-enc-01"
	prodSeedCrossEncTrackIDA   = "prod-seed-cross-enc-track-01"
	prodSeedCrossEncTrackIDB   = "prod-seed-cross-enc-track-02"
	prodSeedCrossNotifForUser1 = "prod-seed-cross-notif-01"
	prodSeedCrossNotifForUser2 = "prod-seed-cross-notif-02"
)

func seedProdData(db *gorm.DB, target model.User) error {
	return db.Transaction(func(tx *gorm.DB) error {
		// --- カウンターパートユーザーの作成 ---
		// encounters の user_id1 < user_id2 制約に合わせ、
		// target ID（"88ca94e3-..."）が user_id1、"prod-seed-user-0x"（'p' > '8'）が user_id2 になる。
		nameA := "Haru"
		nameB := "Sora"
		nameC := "Kai"
		counterparts := []model.User{
			{ID: prodSeedCounterpartIDA, AuthProvider: "firebase", ProviderUserID: "prod-demo-user-1", Name: &nameA},
			{ID: prodSeedCounterpartIDB, AuthProvider: "firebase", ProviderUserID: "prod-demo-user-2", Name: &nameB},
			{ID: prodSeedCounterpartIDC, AuthProvider: "firebase", ProviderUserID: "prod-demo-user-3", Name: &nameC},
		}
		if err := tx.Clauses(clause.OnConflict{DoNothing: true}).Create(&counterparts).Error; err != nil {
			return err
		}

		// --- UserSettings ---
		settings := []model.UserSettings{
			{ID: prodSeedSettingsA, UserID: prodSeedCounterpartIDA},
			{ID: prodSeedSettingsB, UserID: prodSeedCounterpartIDB},
			{ID: prodSeedSettingsC, UserID: prodSeedCounterpartIDC},
		}
		if err := tx.Clauses(clause.OnConflict{DoNothing: true}).Create(&settings).Error; err != nil {
			return err
		}

		// --- トラック ---
		tracks := []model.Track{
			{ID: prodSeedTrackIDA, ExternalID: "prod-demo-track-1", Provider: "spotify", Title: "City Lights", ArtistName: "Night Echoes"},
			{ID: prodSeedTrackIDB, ExternalID: "prod-demo-track-2", Provider: "spotify", Title: "Sunrise Avenue", ArtistName: "Harborline"},
			{ID: prodSeedTrackIDC, ExternalID: "prod-demo-track-3", Provider: "spotify", Title: "Midnight Metro", ArtistName: "Loop Sisters"},
			{ID: prodSeedTrackIDD, ExternalID: "prod-demo-track-4", Provider: "spotify", Title: "Ocean Drive", ArtistName: "Coastal Wave"},
			{ID: prodSeedTrackIDE, ExternalID: "prod-demo-track-5", Provider: "spotify", Title: "Neon Rain", ArtistName: "Electric Pulse"},
		}
		if err := tx.Clauses(clause.OnConflict{DoNothing: true}).Create(&tracks).Error; err != nil {
			return err
		}

		// --- Encounters ---
		now := time.Now().UTC()
		lat1, lng1 := 35.681236, 139.767125
		lat2, lng2 := 35.689487, 139.691706

		encounters := []model.Encounter{
			{
				ID:            prodSeedEncounterIDA,
				UserID1:       target.ID,
				UserID2:       prodSeedCounterpartIDA,
				EncounteredAt: now.Add(-1 * time.Hour),
				EncounterType: "ble",
			},
			{
				ID:            prodSeedEncounterIDB,
				UserID1:       target.ID,
				UserID2:       prodSeedCounterpartIDB,
				EncounteredAt: now.Add(-26 * time.Hour),
				EncounterType: "location",
				Latitude:      &lat1,
				Longitude:     &lng1,
			},
			{
				ID:            prodSeedEncounterIDC,
				UserID1:       target.ID,
				UserID2:       prodSeedCounterpartIDC,
				EncounteredAt: now.Add(-72 * time.Hour),
				EncounterType: "location",
				Latitude:      &lat2,
				Longitude:     &lng2,
			},
		}
		if err := tx.Clauses(clause.OnConflict{DoNothing: true}).Create(&encounters).Error; err != nil {
			return err
		}

		// --- EncounterTracks ---
		encounterTracks := []model.EncounterTrack{
			{ID: prodSeedEncounterTrackIDA, EncounterID: prodSeedEncounterIDA, TrackID: prodSeedTrackIDA, SourceUserID: prodSeedCounterpartIDA},
			{ID: prodSeedEncounterTrackIDB, EncounterID: prodSeedEncounterIDA, TrackID: prodSeedTrackIDB, SourceUserID: target.ID},
			{ID: prodSeedEncounterTrackIDC, EncounterID: prodSeedEncounterIDB, TrackID: prodSeedTrackIDC, SourceUserID: prodSeedCounterpartIDB},
			{ID: prodSeedEncounterTrackIDD, EncounterID: prodSeedEncounterIDC, TrackID: prodSeedTrackIDD, SourceUserID: prodSeedCounterpartIDC},
		}
		if err := tx.Clauses(clause.OnConflict{DoNothing: true}).Create(&encounterTracks).Error; err != nil {
			return err
		}

		// --- UserTracks ---
		userTracks := []model.UserTrack{
			{ID: prodSeedUserTrackIDA, UserID: target.ID, TrackID: prodSeedTrackIDA},
			{ID: prodSeedUserTrackIDB, UserID: target.ID, TrackID: prodSeedTrackIDB},
			{ID: prodSeedUserTrackIDC, UserID: target.ID, TrackID: prodSeedTrackIDC},
			{ID: prodSeedUserTrackIDD, UserID: prodSeedCounterpartIDA, TrackID: prodSeedTrackIDD},
			{ID: prodSeedUserTrackIDE, UserID: prodSeedCounterpartIDB, TrackID: prodSeedTrackIDE},
		}
		if err := tx.Clauses(clause.OnConflict{DoNothing: true}).Create(&userTracks).Error; err != nil {
			return err
		}

		// --- UserCurrentTrack ---
		if err := tx.Clauses(clause.OnConflict{DoNothing: true}).Create(&model.UserCurrentTrack{
			ID:      prodSeedCurrentTrackID,
			UserID:  target.ID,
			TrackID: prodSeedTrackIDB,
		}).Error; err != nil {
			return err
		}

		// --- Playlists ---
		descA := "朝の通勤向けプレイリスト"
		descB := "夜に聴きたい曲まとめ"
		playlists := []model.Playlist{
			{ID: prodSeedPlaylistIDA, UserID: target.ID, Name: "Morning Walk", Description: &descA, IsPublic: true},
			{ID: prodSeedPlaylistIDB, UserID: prodSeedCounterpartIDA, Name: "Night Drive", Description: &descB, IsPublic: true},
		}
		if err := tx.Clauses(clause.OnConflict{DoNothing: true}).Create(&playlists).Error; err != nil {
			return err
		}

		playlistTracks := []model.PlaylistTrack{
			{ID: prodSeedPlaylistTrackIDA, PlaylistID: prodSeedPlaylistIDA, TrackID: prodSeedTrackIDA, SortOrder: 1},
			{ID: prodSeedPlaylistTrackIDB, PlaylistID: prodSeedPlaylistIDA, TrackID: prodSeedTrackIDB, SortOrder: 2},
			{ID: prodSeedPlaylistTrackIDC, PlaylistID: prodSeedPlaylistIDA, TrackID: prodSeedTrackIDC, SortOrder: 3},
			{ID: prodSeedPlaylistTrackIDD, PlaylistID: prodSeedPlaylistIDB, TrackID: prodSeedTrackIDD, SortOrder: 1},
			{ID: prodSeedPlaylistTrackIDE, PlaylistID: prodSeedPlaylistIDB, TrackID: prodSeedTrackIDE, SortOrder: 2},
		}
		if err := tx.Clauses(clause.OnConflict{DoNothing: true}).Create(&playlistTracks).Error; err != nil {
			return err
		}

		// --- お気に入り ---
		trackFavorites := []model.TrackFavorite{
			{ID: prodSeedTrackFavIDA, UserID: target.ID, TrackID: prodSeedTrackIDC},
			{ID: prodSeedTrackFavIDB, UserID: target.ID, TrackID: prodSeedTrackIDE},
		}
		if err := tx.Clauses(clause.OnConflict{DoNothing: true}).Create(&trackFavorites).Error; err != nil {
			return err
		}

		if err := tx.Clauses(clause.OnConflict{DoNothing: true}).Create(&model.PlaylistFavorite{
			ID:         prodSeedPlaylistFavIDA,
			UserID:     target.ID,
			PlaylistID: prodSeedPlaylistIDB,
		}).Error; err != nil {
			return err
		}

		// --- コメント ---
		comments := []model.Comment{
			{ID: prodSeedCommentIDA, EncounterID: prodSeedEncounterIDA, CommenterUserID: target.ID, Content: "今日はいい音楽だったね！"},
			{ID: prodSeedCommentIDB, EncounterID: prodSeedEncounterIDA, CommenterUserID: prodSeedCounterpartIDA, Content: "おすすめありがとう！"},
			{ID: prodSeedCommentIDC, EncounterID: prodSeedEncounterIDB, CommenterUserID: target.ID, Content: "また会えたら嬉しいな"},
			{ID: prodSeedCommentIDD, EncounterID: prodSeedEncounterIDB, CommenterUserID: prodSeedCounterpartIDB, Content: "この曲最高ですね"},
		}
		if err := tx.Clauses(clause.OnConflict{DoNothing: true}).Create(&comments).Error; err != nil {
			return err
		}

		// --- 通知 ---
		notifications := []model.OutboxNotification{
			{ID: prodSeedNotificationIDA, UserID: target.ID, EncounterID: prodSeedEncounterIDA, Status: "sent"},
			{ID: prodSeedNotificationIDB, UserID: target.ID, EncounterID: prodSeedEncounterIDB, Status: "sent", ReadAt: ptrTime(now.Add(-25 * time.Hour))},
			{ID: prodSeedNotificationIDC, UserID: target.ID, EncounterID: prodSeedEncounterIDC, Status: "sent", ReadAt: ptrTime(now.Add(-71 * time.Hour))},
		}
		if err := tx.Clauses(clause.OnConflict{DoNothing: true}).Create(&notifications).Error; err != nil {
			return err
		}

		// --- MusicConnection ---
		if err := seedMusicConnections(tx, prodSeedMusicConnID, target.ID); err != nil {
			return err
		}

		// --- LyricChain + エントリ + 生成曲 ---
		if err := seedProdLyricData(tx, target.ID); err != nil {
			return err
		}

		return nil
	})
}

// SeedProdCrossEncounter は既存の 2 人の実ユーザー間にすれ違いレコードを投入する。
// user_id1 < user_id2 制約を満たすよう引数の順序に関わらず自動的に並び替える。
// 両ユーザーが DB に存在していることが前提。
func SeedProdCrossEncounter(db *gorm.DB, userIDA, userIDB string) error {
	// 両ユーザーの存在確認
	for _, id := range []string{userIDA, userIDB} {
		var u model.User
		if err := db.Where("id = ?", id).First(&u).Error; err != nil {
			return fmt.Errorf("rdb.SeedProdCrossEncounter: user not found (id=%s): %w", id, err)
		}
	}

	// user_id1 < user_id2 制約を満たす順序に正規化
	uid1, uid2 := userIDA, userIDB
	if uid1 > uid2 {
		uid1, uid2 = uid2, uid1
	}

	return db.Transaction(func(tx *gorm.DB) error {
		now := time.Now().UTC()

		encounter := model.Encounter{
			ID:            prodSeedCrossEncounterID,
			UserID1:       uid1,
			UserID2:       uid2,
			EncounteredAt: now.Add(-3 * time.Hour),
			EncounterType: "ble",
		}
		if err := tx.Clauses(clause.OnConflict{DoNothing: true}).Create(&encounter).Error; err != nil {
			return err
		}

		// 既存の prod-seed トラックを流用してすれ違い楽曲を紐付ける
		encounterTracks := []model.EncounterTrack{
			{ID: prodSeedCrossEncTrackIDA, EncounterID: prodSeedCrossEncounterID, TrackID: prodSeedTrackIDA, SourceUserID: uid1},
			{ID: prodSeedCrossEncTrackIDB, EncounterID: prodSeedCrossEncounterID, TrackID: prodSeedTrackIDC, SourceUserID: uid2},
		}
		if err := tx.Clauses(clause.OnConflict{DoNothing: true}).Create(&encounterTracks).Error; err != nil {
			return err
		}

		notifications := []model.OutboxNotification{
			{ID: prodSeedCrossNotifForUser1, UserID: uid1, EncounterID: prodSeedCrossEncounterID, Status: "sent"},
			{ID: prodSeedCrossNotifForUser2, UserID: uid2, EncounterID: prodSeedCrossEncounterID, Status: "sent"},
		}
		if err := tx.Clauses(clause.OnConflict{DoNothing: true}).Create(&notifications).Error; err != nil {
			return err
		}

		return nil
	})
}

func seedProdLyricData(tx *gorm.DB, targetUserID string) error {
	now := time.Now().UTC()
	completedAt := now.Add(-90 * time.Minute)

	chains := []model.LyricChain{
		{
			ID:               prodSeedLyricChainIDA,
			Status:           "completed",
			ParticipantCount: 2,
			Threshold:        2,
			CreatedAt:        now.Add(-2 * time.Hour),
			CompletedAt:      &completedAt,
		},
		{
			ID:               prodSeedLyricChainIDB,
			Status:           "completed",
			ParticipantCount: 2,
			Threshold:        2,
			CreatedAt:        now.Add(-3 * time.Hour),
			CompletedAt:      &completedAt,
		},
	}
	if err := tx.Clauses(clause.OnConflict{DoNothing: true}).Create(&chains).Error; err != nil {
		return err
	}

	entries := []model.LyricEntry{
		{ID: prodSeedLyricEntryIDA, ChainID: prodSeedLyricChainIDA, UserID: targetUserID, EncounterID: prodSeedEncounterIDA, Content: "夜明けのメロディが流れる", SequenceNum: 1},
		{ID: prodSeedLyricEntryIDB, ChainID: prodSeedLyricChainIDA, UserID: prodSeedCounterpartIDA, EncounterID: prodSeedEncounterIDA, Content: "街角の光をつなげて", SequenceNum: 2},
		{ID: prodSeedLyricEntryIDC, ChainID: prodSeedLyricChainIDB, UserID: targetUserID, EncounterID: prodSeedEncounterIDB, Content: "静かな波のリズムで", SequenceNum: 1},
		{ID: prodSeedLyricEntryIDD, ChainID: prodSeedLyricChainIDB, UserID: prodSeedCounterpartIDB, EncounterID: prodSeedEncounterIDB, Content: "星空に声を重ねる", SequenceNum: 2},
	}
	if err := tx.Clauses(clause.OnConflict{DoNothing: true}).Create(&entries).Error; err != nil {
		return err
	}

	songs := []model.GeneratedSong{
		{
			ID:          prodSeedGeneratedSongIDA,
			ChainID:     prodSeedLyricChainIDA,
			Title:       ptrString("Dawn Echoes"),
			AudioURL:    ptrString("https://example.com/audio/dawn-echoes.mp3"),
			DurationSec: ptrInt(182),
			Mood:        ptrString("Calm"),
			Genre:       ptrString("Ambient"),
			Status:      "completed",
			GeneratedAt: ptrTime(now.Add(-80 * time.Minute)),
		},
		{
			ID:          prodSeedGeneratedSongIDB,
			ChainID:     prodSeedLyricChainIDB,
			Title:       ptrString("Starlit Waves"),
			AudioURL:    ptrString("https://example.com/audio/starlit-waves.mp3"),
			DurationSec: ptrInt(205),
			Mood:        ptrString("Dreamy"),
			Genre:       ptrString("Chill"),
			Status:      "completed",
			GeneratedAt: ptrTime(now.Add(-70 * time.Minute)),
		},
	}
	if err := tx.Clauses(clause.OnConflict{DoNothing: true}).Create(&songs).Error; err != nil {
		return err
	}

	if err := tx.Clauses(clause.OnConflict{DoNothing: true}).Create(&model.SongLike{
		ID:     prodSeedSongLikeIDA,
		SongID: prodSeedGeneratedSongIDA,
		UserID: targetUserID,
	}).Error; err != nil {
		return err
	}

	return nil
}
