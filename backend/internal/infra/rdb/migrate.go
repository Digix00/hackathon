package rdb

import (
	"fmt"

	"gorm.io/gorm"

	"hackathon/internal/infra/rdb/model"
)

// Migrate はサーバー起動時に呼び出す。
// GORM AutoMigrate でテーブル・カラム・インデックスを作成・更新したあと、
// AutoMigrate では表現できない制約（CHECK / 部分 UNIQUE / FK 循環）を手動で追加する。
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

// applyManualConstraints は AutoMigrate では表現できない制約を冪等に追加する。
// PostgreSQL 16（docker: postgres:16-alpine）の ADD CONSTRAINT IF NOT EXISTS を利用し、
// DROP → ADD パターンを避けることで制約が一瞬消えない安全な実装にしている。
func applyManualConstraints(db *gorm.DB) error {
	statements := []string{
		// ---- FK（循環依存: users ↔ files） ----
		`ALTER TABLE files ADD CONSTRAINT IF NOT EXISTS fk_files_uploaded_by
			FOREIGN KEY (uploaded_by_user_id) REFERENCES users(id)`,
		`ALTER TABLE users ADD CONSTRAINT IF NOT EXISTS fk_users_avatar_file
			FOREIGN KEY (avatar_file_id) REFERENCES files(id)`,

		// ---- CHECK 制約（PostgreSQL 14+ の ADD CONSTRAINT IF NOT EXISTS で冪等に追加） ----
		`ALTER TABLE encounters
			ADD CONSTRAINT IF NOT EXISTS chk_encounters_user_order
			CHECK (user_id_1 < user_id_2)`,

		`ALTER TABLE reports
			ADD CONSTRAINT IF NOT EXISTS chk_reports_type
			CHECK (
				(report_type = 'comment' AND target_comment_id IS NOT NULL) OR
				(report_type = 'user'    AND target_comment_id IS NULL)
			)`,

		`ALTER TABLE lyric_entries
			ADD CONSTRAINT IF NOT EXISTS chk_lyric_entries_len
			CHECK (char_length(content) <= 100)`,

		// ---- 部分 UNIQUE インデックス ----

		// reports: report_type ごとに独立した部分インデックスで重複通報を防ぐ
		`CREATE UNIQUE INDEX IF NOT EXISTS uq_reports_comment
			ON reports (reporter_user_id, reported_user_id, report_type, target_comment_id)
			WHERE report_type = 'comment'`,
		`CREATE UNIQUE INDEX IF NOT EXISTS uq_reports_user
			ON reports (reporter_user_id, reported_user_id, report_type)
			WHERE report_type = 'user'`,

		// lyric_entries: (chain_id, sequence_num) の UNIQUE を部分インデックスで定義。
		// WHERE deleted_at IS NULL を付けることで、ソフトデリート済みエントリが
		// 新規エントリの挿入をブロックしないようにする。
		`CREATE UNIQUE INDEX IF NOT EXISTS uq_lyric_entries_seq
			ON lyric_entries (chain_id, sequence_num)
			WHERE deleted_at IS NULL`,

		// ---- soft-deletable join テーブルの部分 UNIQUE インデックス ----
		// gorm の uniqueIndex タグは通常の UNIQUE INDEX を生成するため、soft delete 後の
		// 再挿入が UNIQUE 違反になる。WHERE deleted_at IS NULL の部分インデックスで定義する。

		`CREATE UNIQUE INDEX IF NOT EXISTS uq_lyric_entries_user
			ON lyric_entries (chain_id, user_id)
			WHERE deleted_at IS NULL`,

		`CREATE UNIQUE INDEX IF NOT EXISTS uq_blocks
			ON blocks (blocker_user_id, blocked_user_id)
			WHERE deleted_at IS NULL`,

		`CREATE UNIQUE INDEX IF NOT EXISTS uq_mutes
			ON mutes (user_id, target_user_id)
			WHERE deleted_at IS NULL`,

		`CREATE UNIQUE INDEX IF NOT EXISTS uq_user_tracks
			ON user_tracks (user_id, track_id)
			WHERE deleted_at IS NULL`,

		`CREATE UNIQUE INDEX IF NOT EXISTS uq_playlist_tracks
			ON playlist_tracks (playlist_id, track_id)
			WHERE deleted_at IS NULL`,

		`CREATE UNIQUE INDEX IF NOT EXISTS uq_track_favorites
			ON track_favorites (user_id, track_id)
			WHERE deleted_at IS NULL`,

		`CREATE UNIQUE INDEX IF NOT EXISTS uq_playlist_favorites
			ON playlist_favorites (user_id, playlist_id)
			WHERE deleted_at IS NULL`,

		`CREATE UNIQUE INDEX IF NOT EXISTS uq_song_likes
			ON song_likes (song_id, user_id)
			WHERE deleted_at IS NULL`,
	}

	for _, stmt := range statements {
		if err := db.Exec(stmt).Error; err != nil {
			return fmt.Errorf("applyManualConstraints exec: %w\nstmt: %s", err, stmt)
		}
	}
	return nil
}
