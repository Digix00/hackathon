package rdb

import (
	"fmt"

	"gorm.io/gorm"

	"hackathon/internal/infra/rdb/model"
)

// Migrate はサーバー起動時に呼び出す。
// GORM AutoMigrate でテーブル・カラム・インデックス・CHECK 制約・部分 UNIQUE インデックスを作成・更新したあと、
// AutoMigrate では解決できない循環 FK（users ↔ files）のみ手動で追加する。
func Migrate(db *gorm.DB) error {
	if err := autoMigrate(db); err != nil {
		return fmt.Errorf("rdb.Migrate autoMigrate: %w", err)
	}
	if err := applyManualConstraints(db); err != nil {
		return fmt.Errorf("rdb.Migrate applyManualConstraints: %w", err)
	}
	return nil
}

// autoMigrate は全モデルのテーブル・カラム・インデックスを作成・更新する。
// FK 制約は client.go で DisableForeignKeyConstraintWhenMigrating: true にしているため作成しない。
func autoMigrate(db *gorm.DB) error {
	return db.AutoMigrate(
		// 依存なし
		&model.Prefecture{},
		&model.Track{},
		&model.LyricChain{},

		// users ↔ files 循環依存のため両方先に作成し、FK は後付け
		&model.File{},
		&model.User{},

		// users に依存
		&model.UserSettings{},
		&model.UserDevice{},
		&model.MusicConnection{},
		&model.BleToken{},
		&model.UserTrack{},
		&model.UserCurrentTrack{},
		&model.Playlist{},
		&model.PlaylistTrack{},
		&model.TrackFavorite{},
		&model.PlaylistFavorite{},

		// encounters に依存
		&model.Encounter{},
		&model.EncounterRead{},
		&model.EncounterTrack{},
		&model.DailyEncounterCount{},
		&model.Comment{},
		&model.Report{},
		&model.Block{},
		&model.Mute{},
		&model.OutboxNotification{},

		// lyric_chains に依存
		&model.LyricEntry{},
		&model.GeneratedSong{},
		&model.SongLike{},
		&model.OutboxLyriaJob{},
	)
}

// applyManualConstraints は循環 FK（users ↔ files）を冪等に追加する。
// ADD CONSTRAINT IF NOT EXISTS は PostgreSQL 17+ でのみ有効なため、
// PG16 対応として DO $$ BEGIN ... END $$ ブロックで pg_constraint を参照し冪等性を確保する。
// CHECK 制約・部分 UNIQUE インデックスは各 model の struct タグ（check / uniqueIndex）で定義し、
// AutoMigrate が管理する。
func applyManualConstraints(db *gorm.DB) error {
	statements := []string{
		// ---- FK（循環依存: users ↔ files） ----
		`DO $$ BEGIN
			IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'fk_files_uploaded_by') THEN
				ALTER TABLE files ADD CONSTRAINT fk_files_uploaded_by
					FOREIGN KEY (uploaded_by_user_id) REFERENCES users(id);
			END IF;
		END $$`,
		`DO $$ BEGIN
			IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'fk_users_avatar_file') THEN
				ALTER TABLE users ADD CONSTRAINT fk_users_avatar_file
					FOREIGN KEY (avatar_file_id) REFERENCES files(id);
			END IF;
		END $$`,
	}

	for _, stmt := range statements {
		if err := db.Exec(stmt).Error; err != nil {
			return fmt.Errorf("applyManualConstraints exec: %w\nstmt: %s", err, stmt)
		}
	}
	return nil
}
