package handler

import (
	"context"
	"log"
	"os"
	"testing"
	"time"

	"gorm.io/driver/postgres"
	"gorm.io/gorm"

	"hackathon/internal/infra/rdb"
)

// sharedTestDB はパッケージ内の全テストが共有する DB 接続。
// TestMain でマイグレーション済みの状態になる。PostgreSQL が利用不可の場合は nil。
var sharedTestDB *gorm.DB

// TestMain はパッケージ全体で一度だけ DB 接続とマイグレーションを実行する。
// テスト関数ごとに rdb.Migrate を呼ぶ代わりにここで 1 回だけ実行することで
// スキーマ照会のオーバーヘッドを削減する。
func TestMain(m *testing.M) {
	dsn := os.Getenv("PG_TEST_DATABASE_URL")
	if dsn == "" {
		dsn = "postgres://postgres:postgres@127.0.0.1:5432/hackathon?sslmode=disable"
	}

	db, err := gorm.Open(postgres.Open(dsn), &gorm.Config{})
	if err != nil {
		log.Printf("postgres not reachable, skipping DB-backed tests: %v", err)
		os.Exit(m.Run())
	}

	sqlDB, err := db.DB()
	if err != nil {
		log.Fatalf("get sql.DB: %v", err)
	}

	ctx, cancel := context.WithTimeout(context.Background(), 2*time.Second)
	defer cancel()
	if err := sqlDB.PingContext(ctx); err != nil {
		log.Printf("postgres ping failed, skipping DB-backed tests: %v", err)
		os.Exit(m.Run())
	}

	if err := rdb.Migrate(db); err != nil {
		log.Fatalf("migrate: %v", err)
	}

	sharedTestDB = db
	os.Exit(m.Run())
}
